class Diaper {
  Diaper({
    required this.id,
    required this.type,
    required this.loggedAt,
    required this.createdAt,
  });

  final String id;
  final String type; // 'wet' | 'dirty' | 'both'
  final DateTime loggedAt;
  final DateTime createdAt;

  factory Diaper.fromJson(Map<String, dynamic> json) => Diaper(
        id: json['id'] as String,
        type: json['type'] as String,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
