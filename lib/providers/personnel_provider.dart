import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/personnel.dart';
import '../services/storage_service.dart';

/// 앱 전체 상태를 관리하는 Provider.
///
/// - 화면 전환 ([screen])
/// - 인원 목록 CRUD
/// - 검색 / 년도·월 필터
/// - 비밀번호
///
/// 각 변경 메서드는 [notifyListeners] → UI 리빌드 → [StorageService] 저장 순으로 동작한다.
class PersonnelProvider extends ChangeNotifier {
  final _storage = StorageService();

  // ── 상태 필드 ──────────────────────────────────────────
  Screen _screen = Screen.lock;
  String _currentPassword = '1234';
  List<Personnel> _personnelList = [];
  String _searchQuery = '';
  Personnel? _selectedPerson;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // ── Getter ─────────────────────────────────────────────
  Screen get screen => _screen;
  String get currentPassword => _currentPassword;
  List<Personnel> get personnelList => _personnelList;
  String get searchQuery => _searchQuery;

  /// 상세/수정 화면에서 편집 대상으로 사용하는 인원.
  Personnel? get selectedPerson => _selectedPerson;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// 삭제되지 않은 인원을 검색어 또는 년도·월 기준으로 필터링하고 이름순 정렬한다.
  ///
  /// 검색어가 있으면 년도·월 필터를 무시하고 이름·소속 전체를 대상으로 검색한다.
  List<Personnel> get filteredAndSortedList {
    return _personnelList.where((p) {
      if (p.deletedAt != null) return false;
      if (_searchQuery.trim().isNotEmpty) {
        return p.name.contains(_searchQuery) || p.affiliation.contains(_searchQuery);
      }
      return p.year == _selectedYear && p.month == _selectedMonth;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// 소프트 삭제된 인원 목록. 삭제 일시 내림차순 정렬.
  List<Personnel> get trashList {
    return _personnelList.where((p) => p.deletedAt != null).toList()
      ..sort((a, b) => (b.deletedAt ?? '').compareTo(a.deletedAt ?? ''));
  }

  // ── 초기화 ─────────────────────────────────────────────

  /// SharedPreferences 에서 인원 목록과 비밀번호를 불러온다.
  /// 저장된 데이터가 없으면 [StorageService._defaultList]로 초기화한다.
  Future<void> loadData() async {
    final (list, password) = await _storage.loadData();
    _personnelList = list;
    _currentPassword = password;
    notifyListeners();
  }

  // ── 화면 전환 ──────────────────────────────────────────

  void setScreen(Screen screen) {
    _screen = screen;
    notifyListeners();
  }

  // ── 필터 ───────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  /// 상세 화면으로 이동하기 직전에 편집 대상 인원을 지정한다.
  void selectPerson(Personnel person) {
    _selectedPerson = person;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────

  /// 신규 인원을 추가하고 목록 화면으로 전환한다.
  /// 추가된 인원의 년도·월로 필터를 자동 이동한다.
  Future<void> addPersonnel(Personnel person) async {
    _personnelList.add(person);
    _selectedYear = person.year;
    _selectedMonth = person.month;
    _screen = Screen.list;
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  /// 기존 인원 정보를 수정하고 목록 화면으로 전환한다.
  Future<void> updatePersonnel(Personnel person) async {
    final idx = _personnelList.indexWhere((e) => e.id == person.id);
    if (idx >= 0) _personnelList[idx] = person;
    _selectedPerson = null;
    _screen = Screen.list;
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  /// 인원을 즉시 삭제하지 않고 [deletedAt]을 기록해 휴지통으로 이동한다.
  Future<void> softDeletePersonnel(String id) async {
    final idx = _personnelList.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _personnelList[idx] = _personnelList[idx].copyWith(
        deletedAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );
    }
    _selectedPerson = null;
    _screen = Screen.list;
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  /// 휴지통에 있는 인원의 [deletedAt]을 null 로 되돌려 활성 상태로 복구한다.
  Future<void> restorePersonnel(String id) async {
    final idx = _personnelList.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      _personnelList[idx] = _personnelList[idx].copyWith(clearDeletedAt: true);
    }
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  /// 인원을 목록에서 완전히 제거한다. 복구 불가.
  Future<void> permanentDeletePersonnel(String id) async {
    _personnelList.removeWhere((e) => e.id == id);
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  /// 휴지통에 있는 모든 인원을 영구 삭제한다.
  Future<void> emptyTrash() async {
    _personnelList.removeWhere((p) => p.deletedAt != null);
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }

  // ── 설정 ───────────────────────────────────────────────

  Future<void> changePassword(String newPassword) async {
    _currentPassword = newPassword;
    notifyListeners();
    await _storage.savePassword(newPassword);
  }

  /// JSON 가져오기 시 기존 목록 전체를 교체한다.
  Future<void> replacePersonnelList(List<Personnel> list) async {
    _personnelList = list;
    notifyListeners();
    await _storage.savePersonnelList(_personnelList);
  }
}
