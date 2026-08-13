import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cve_model.dart';

class ApiService {
  static const String _baseUrl =
      'https://services.nvd.nist.gov/rest/json/cves/2.0';

  Future<List<CveModel>> searchCves(
      String keyword, {
        required String pubStart,
        required String pubEnd,
      }) async {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final uri = Uri.parse(
      '$_baseUrl?keywordSearch=$encodedKeyword',
    );

    print('Requesting: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vulnerabilities = data['vulnerabilities'] as List? ?? [];

        final allCves = vulnerabilities
            .map((item) => CveModel.fromJson(item['cve']))
            .toList();

        // Parse selected date range
        final start = DateTime.parse(pubStart.substring(0, 10));
        final end = DateTime.parse(pubEnd.substring(0, 10));

        // Filter locally by selected period
        final filtered = allCves.where((cve) {
          if (cve.publishedDate == null) return false;
          final date = DateTime.tryParse(cve.publishedDate!);
          if (date == null) return false;
          return date.isAfter(
            start.subtract(const Duration(days: 1)),
          ) &&
              date.isBefore(
                end.add(const Duration(days: 1)),
              );
        }).toList();

        // Sort newest first
        filtered.sort((a, b) {
          if (a.publishedDate == null || b.publishedDate == null) return 0;
          return b.publishedDate!.compareTo(a.publishedDate!);
        });

        return filtered;
      } else {
        throw Exception('Failed to fetch CVEs: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception caught: $e');
      rethrow;
    }
  }
}