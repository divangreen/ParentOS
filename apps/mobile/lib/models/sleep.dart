class Sleep {
  Sleep({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.createdAt,
  });

  final String id;
  final String type; // 'nap' | 'night'
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final DateTime createdAt;

  factory Sleep.fromJson(Map<String, dynamic> json) => Sleep(
        id: json['id'] as String,
        type: json['type'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: DateTime.parse(json['ended_at'] as String),
        durationMinutes: json['duration_minutes'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
