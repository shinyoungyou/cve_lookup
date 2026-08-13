import 'package:flutter/material.dart';
import '../models/cve_model.dart';
import '../screens/cve_detail_screen.dart';

class CveCard extends StatelessWidget {
  final CveModel cve;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const CveCard({
    super.key,
    required this.cve,
    required this.isSaved,
    required this.onSaveToggle,
  });

  Color _severityColor(String? severity) {
    switch (severity?.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CveDetailScreen(cve: cve),
            ),
          );
        },
        child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cve.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue.shade900,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.blue.shade700 : Colors.grey,
                  ),
                  onPressed: onSaveToggle,
                ),
              ],
            ),
            if (cve.severity != null)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _severityColor(cve.severity),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cve.severity!.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (cve.cvssScore != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'CVSS: ${cve.cvssScore!.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 8),
            Text(
              cve.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 6),
            if (cve.publishedDate != null)
              Text(
                'Published: ${cve.publishedDate}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    ));
  }
}