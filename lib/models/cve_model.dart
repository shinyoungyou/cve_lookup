class CveModel {
  final String id;
  final String description;
  final double? cvssScore;
  final String? severity;
  final String? publishedDate;

  CveModel({
    required this.id,
    required this.description,
    this.cvssScore,
    this.severity,
    this.publishedDate,
  });

  // Convert NVD API JSON to CveModel
  factory CveModel.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] ?? {};
    final cvssData = metrics['cvssMetricV31'] ??
        metrics['cvssMetricV30'] ??
        metrics['cvssMetricV2'] ??
        [];

    double? score;
    String? severity;

    if (cvssData is List && cvssData.isNotEmpty) {
      final cvss = cvssData[0]['cvssData'];
      score = (cvss['baseScore'] as num?)?.toDouble();
      severity = cvssData[0]['baseSeverity'] ??
          cvss['baseSeverity'];
    }

    final descriptions = json['descriptions'] as List? ?? [];
    final englishDesc = descriptions.firstWhere(
          (d) => d['lang'] == 'en',
      orElse: () => {'value': 'No description available'},
    );

    return CveModel(
      id: json['id'] ?? 'Unknown',
      description: englishDesc['value'] ?? 'No description available',
      cvssScore: score,
      severity: severity,
      publishedDate: json['published']?.toString().substring(0, 10),
    );
  }

  // Convert to map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'cvssScore': cvssScore,
      'severity': severity,
      'publishedDate': publishedDate,
    };
  }

  // Convert from SQLite map
  factory CveModel.fromMap(Map<String, dynamic> map) {
    return CveModel(
      id: map['id'],
      description: map['description'],
      cvssScore: map['cvssScore'],
      severity: map['severity'],
      publishedDate: map['publishedDate'],
    );
  }
}
