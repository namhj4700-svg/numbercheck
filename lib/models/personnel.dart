import 'dart:convert';

/// 앱 내 화면 이동을 나타내는 열거형.
/// [PersonnelProvider.setScreen]을 통해 전환된다.
enum Screen { lock, list, input, settings, detail, trash }

/// 인원 한 명의 데이터 모델.
///
/// 영구 삭제 없이 [deletedAt] 필드로 소프트 삭제를 구현한다.
/// [deletedAt]이 null 이면 활성 인원, 값이 있으면 휴지통 상태다.
class Personnel {
  final String id;
  final String name;
  final int age;
  final String affiliation;

  /// 상세 메모. 선택 입력이므로 null 가능.
  final String? details;

  /// 인원이 속한 년도 (명단 필터 기준).
  final int year;

  /// 인원이 속한 월 (명단 필터 기준).
  final int month;

  /// 최초 등록 일시 ('yyyy-MM-dd HH:mm' 형식 문자열).
  final String createdAt;

  /// 소프트 삭제 일시. null 이면 활성, 값이 있으면 휴지통.
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

  /// 일부 필드만 변경한 새 인스턴스를 반환한다.
  ///
  /// 휴지통에서 복구할 때는 [clearDeletedAt]을 true 로 넘겨
  /// [deletedAt]을 null 로 초기화한다.
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

  /// SharedPreferences 저장 및 JSON 내보내기용 Map 변환.
  /// null 필드(details, deletedAt)는 키 자체를 생략한다.
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

  /// JSON Map 으로부터 인스턴스를 생성한다.
  /// 누락된 필드는 기본값으로 대체하여 파싱 오류를 방지한다.
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
