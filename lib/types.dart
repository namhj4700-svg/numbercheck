import 'dart:convert';

enum Screen {
  lock,
  list,
  input,
  settings,
  detail,
  trash,
}

class Personnel {
  final String id;
  final String name;
  final int age;
  final String affiliation;
  final String? details;
  final int year;
  final int month;
  final String createdAt;
  final String? deletedAt;

  Personnel({
    required this.id,
    required this.name,
    required this.age,
    required this.affiliation,
    this.details,
    required this.year,
    required this.month,
    required this.createdAt,
    this.deletedAt,
  });

  Personnel copyWith({
    String? id,
    String? name,
    int? age,
    String? affiliation,
    String? details,
    int? year,
    int? month,
    String? createdAt,
    String? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Personnel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      affiliation: affiliation ?? this.affiliation,
      details: details ?? this.details,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'affiliation': affiliation,
      if (details != null) 'details': details,
      'year': year,
      'month': month,
      'createdAt': createdAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
    };
  }

  factory Personnel.fromMap(Map<String, dynamic> map) {
    return Personnel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      affiliation: map['affiliation'] ?? '',
      details: map['details'],
      year: map['year']?.toInt() ?? DateTime.now().year,
      month: map['month']?.toInt() ?? DateTime.now().month,
      createdAt: map['createdAt'] ?? '',
      deletedAt: map['deletedAt'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Personnel.fromJson(String source) =>
      Personnel.fromMap(json.decode(source));
}
