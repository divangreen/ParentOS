class Feeding {
  Feeding({
    required this.id,
    required this.type,
    this.side,
    this.durationMinutes,
    this.volumeMl,
    this.milkType,
    required this.loggedAt,
    required this.createdAt,
  });

  final String id;
  final String type; // 'breast' | 'bottle'
  final String? side;
  final int? durationMinutes;
  final int? volumeMl;
  final String? milkType;
  final DateTime loggedAt;
  final DateTime createdAt;

  factory Feeding.fromJson(Map<String, dynamic> json) => Feeding(
        id: json['id'] as String,
        type: json['type'] as String,
        side: json['side'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
        volumeMl: json['volume_ml'] as int?,
        milkType: json['milk_type'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
