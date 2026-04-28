import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personnel.dart';

/// SharedPreferences 를 통한 로컬 데이터 영속성 처리.
///
/// 인원 목록과 비밀번호를 JSON 문자열로 저장하고 불러온다.
class StorageService {
  static const _listKey = 'personnel_list';
  static const _passwordKey = 'personnel_password';

  /// 저장된 인원 목록과 비밀번호를 함께 반환한다.
  ///
  /// 저장된 데이터가 없거나 파싱 실패 시 [_defaultList]로 초기화하고
  /// 즉시 저장한 뒤 반환한다 (다음 실행부터는 저장된 데이터를 읽음).
  Future<(List<Personnel>, String)> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString(_passwordKey) ?? '1234';
    final savedListStr = prefs.getString(_listKey);

    if (savedListStr != null) {
      try {
        final List<dynamic> parsed = json.decode(savedListStr);
        return (parsed.map((e) => Personnel.fromMap(e)).toList(), password);
      } catch (_) {}
    }

    // 최초 실행: 샘플 데이터를 저장하고 반환
    final defaults = _defaultList;
    await savePersonnelList(defaults);
    return (defaults, password);
  }

  /// 인원 목록 전체를 JSON 문자열로 직렬화해 저장한다.
  Future<void> savePersonnelList(List<Personnel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, json.encode(list.map((e) => e.toMap()).toList()));
  }

  /// 비밀번호를 저장한다.
  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
  }

  /// 최초 실행 시 표시할 샘플 인원 목록.
  static List<Personnel> get _defaultList => [
        Personnel(id: '1', name: '김철수', age: 28, affiliation: '개발팀', year: 2024, month: 3, createdAt: '2024-03-20 14:30'),
        Personnel(id: '2', name: '이영희', age: 24, affiliation: '디자인팀', year: 2024, month: 3, createdAt: '2024-03-21 09:15'),
        Personnel(id: '3', name: '박지민', age: 31, affiliation: '마케팅팀', year: 2024, month: 4, createdAt: '2024-04-02 11:00'),
        Personnel(id: '4', name: '최다은', age: 27, affiliation: '인사팀', year: 2024, month: 4, createdAt: '2024-04-05 16:45'),
      ];
}
