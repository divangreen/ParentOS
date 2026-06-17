class Child {
  Child({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.birthWeightKg,
    required this.ageDays,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime dateOfBirth;
  final double? birthWeightKg;
  final int ageDays;
  final DateTime createdAt;

  factory Child.fromJson(Map<String, dynamic> json) => Child(
        id: json['id'] as String,
        name: json['name'] as String,
        dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
        birthWeightKg: (json['birth_weight_kg'] as num?)?.toDouble(),
        ageDays: json['age_days'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
