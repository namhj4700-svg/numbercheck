import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';

import 'types.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personnel Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          surface: Colors.grey.shade50,
          background: Colors.grey.shade50,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
      ),
      home: const AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  Screen _screen = Screen.lock;
  String _currentPassword = '1234';
  
  List<Personnel> _personnelList = [];
  
  // State for forms & UI
  String _searchQuery = '';
  Personnel? _selectedPerson;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  final ScrollController _monthScrollController = ScrollController();

  // Input Form
  String _formName = '';
  String _formAge = '';
  String _formAffiliation = '';
  int _formYear = DateTime.now().year;
  int _formMonth = DateTime.now().month;

  // Password Form
  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentPassword = prefs.getString('personnel_password') ?? '1234';
    
    final savedListStr = prefs.getString('personnel_list');
    if (savedListStr != null) {
      try {
        final List<dynamic> parsed = json.decode(savedListStr);
        setState(() {
          _personnelList = parsed.map((e) => Personnel.fromMap(e)).toList();
        });
      } catch (e) {
        debugPrint('Failed to parse saved personnel list: $e');
      }
    } else {
      // Default initial data
      setState(() {
        _personnelList = [
          Personnel(id: '1', name: '김철수', age: 28, affiliation: '개발팀', year: 2024, month: 3, createdAt: '2024-03-20 14:30'),
          Personnel(id: '2', name: '이영희', age: 24, affiliation: '디자인팀', year: 2024, month: 3, createdAt: '2024-03-21 09:15'),
          Personnel(id: '3', name: '박지민', age: 31, affiliation: '마케팅팀', year: 2024, month: 4, createdAt: '2024-04-02 11:00'),
          Personnel(id: '4', name: '최다은', age: 27, affiliation: '인사팀', year: 2024, month: 4, createdAt: '2024-04-05 16:45'),
        ];
      });
      _saveListData();
    }
  }

  Future<void> _saveListData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_personnelList.map((e) => e.toMap()).toList());
    await prefs.setString('personnel_list', jsonStr);
  }

  Future<void> _savePassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personnel_password', newPassword);
    setState(() {
      _currentPassword = newPassword;
    });
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  void _showConfirm(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _setScreen(Screen newScreen) {
    setState(() {
      _screen = newScreen;
    });
  }

  void _saveNewPersonnel() {
    if (_formName.isEmpty || _formAge.isEmpty || _formAffiliation.isEmpty) {
      _showAlert('입력 오류', '모든 필수 항목을 입력해주세요.');
      return;
    }

    final createdAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final newPerson = Personnel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _formName,
      age: int.tryParse(_formAge) ?? 0,
      affiliation: _formAffiliation,
      year: _formYear,
      month: _formMonth,
      createdAt: createdAt,
    );

    setState(() {
      _personnelList.add(newPerson);
      _formName = '';
      _formAge = '';
      _formAffiliation = '';
      _formYear = DateTime.now().year;
      _formMonth = DateTime.now().month;
      _selectedYear = newPerson.year;
      _selectedMonth = newPerson.month;
      _screen = Screen.list;
    });
    _saveListData();
  }

  List<Personnel> get _filteredAndSortedList {
    return _personnelList.where((p) {
      if (p.deletedAt != null) return false;

      final matchesSearch = p.name.contains(_searchQuery) || p.affiliation.contains(_searchQuery);
      
      if (_searchQuery.trim().isNotEmpty) {
        return matchesSearch;
      }
      
      return p.year == _selectedYear && p.month == _selectedMonth;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Personnel> get _trashList {
    return _personnelList.where((p) => p.deletedAt != null).toList()
      ..sort((a, b) => (b.deletedAt ?? '').compareTo(a.deletedAt ?? ''));
  }

  Future<void> _exportCSV() async {
    try {
      final headers = ['년도', '이름', '나이', '소속', '보관월', '등록일시', '상세내용'];
      final rows = _personnelList.map((p) => [
        '${p.year}년',
        p.name,
        p.age.toString(),
        p.affiliation,
        '${p.month}월',
        p.createdAt,
        (p.details ?? '').replaceAll('\n', ' ')
      ]).toList();

      String csvContent = headers.join(',') + '\n';
      csvContent += rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');

      final bom = '\uFEFF';
      final bytes = Uint8List.fromList(utf8.encode(bom + csvContent));
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FileSaver.instance.saveFile(
        name: '인원명단_$dateStr',
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
    } catch (e) {
      _showAlert('오류', '파일 저장 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _importJSON() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        final content = utf8.decode(result.files.first.bytes!);
        final jsonList = json.decode(content);
        if (jsonList is List) {
          _showConfirm('불러오기 확인', '기존 명단이 삭제되고 불러온 명단으로 대체됩니다. 계속하시겠습니까?', () {
            setState(() {
              _personnelList = jsonList.map((e) => Personnel.fromMap(e)).toList();
            });
            _saveListData();
            _showAlert('성공', '명단을 성공적으로 불러왔습니다.');
          });
        }
      }
    } catch (e) {
      _showAlert('오류', '올바른 명단 파일 형식이 아니거나 오류가 발생했습니다.');
    }
  }

  Widget _buildLockScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
          ],
          border: Border.all(color: Colors.grey.shade100)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, size: 48, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            const Text('보안 확인', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('앱 진입을 위해 비밀번호를 입력하세요', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '패스워드 입력',
                hintStyle: const TextStyle(fontSize: 16, letterSpacing: 0),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onSubmitted: (value) {
                if (value == _currentPassword) {
                  _setScreen(Screen.list);
                } else {
                  _showAlert('로그인 실패', '비밀번호가 틀렸습니다.');
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Actually need a controller to get text if not relying on onSubmitted,
                  // For simplicity we will handle via onSubmitted or state. 
                  // Wait, I didn't attach a controller. Let's fix this in a moment or use local state.
                }, 
                child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // To properly handle Lock screen text input, we need an internal state or controller 
  // Let's create a custom LockWidget to encapsulate it.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
              child: child,
            ));
          },
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_screen) {
      case Screen.lock: return LockScreen(
        correctPassword: _currentPassword, 
        onSuccess: () => _setScreen(Screen.list),
        onFail: () => _showAlert('로그인 실패', '비밀번호가 틀렸습니다.')
      );
      case Screen.list: return _buildListScreen();
      case Screen.input: return _buildInputScreen();
      case Screen.settings: return _buildSettingsScreen();
      case Screen.detail: return _buildDetailScreen();
      case Screen.trash: return _buildTrashScreen();
    }
  }

  Widget _buildListScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100))
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.indigo,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.users, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('인원 명단', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      InkWell(onTap: () => setState(() => _selectedYear--), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_left, size: 16))),
                                      Text('$_selectedYear년', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                                      InkWell(onTap: () => setState(() => _selectedYear++), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right, size: 16))),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              _buildIconButton(
                                icon: LucideIcons.trash2, 
                                onTap: () => _setScreen(Screen.trash),
                                badgeCount: _trashList.length,
                              ),
                              const SizedBox(width: 8),
                              _buildIconButton(
                                icon: LucideIcons.settings, 
                                onTap: () => _setScreen(Screen.settings)
                              ),
                              const SizedBox(width: 8),
                              _buildIconButton(
                                icon: LucideIcons.logOut, 
                                onTap: () => _setScreen(Screen.lock)
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: '검색어 입력 (이름, 소속)',
                          prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0)
                        ),
                      ),
                      const SizedBox(height: 16),
                      Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            final offset = pointerSignal.scrollDelta.dy;
                            _monthScrollController.jumpTo(
                              (_monthScrollController.offset + offset).clamp(
                                0.0,
                                _monthScrollController.position.maxScrollExtent,
                              ),
                            );
                          }
                        },
                        child: SingleChildScrollView(
                          controller: _monthScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: List.generate(12, (index) {
                              final m = index + 1;
                              final isSelected = _selectedMonth == m;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMonth = m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                                  ),
                                  child: Text('${m}월', style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.indigo : Colors.grey.shade500
                                  )),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _filteredAndSortedList.isEmpty 
                  ? Center(child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.user, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ))
                  : ListView.builder(
                      itemCount: _filteredAndSortedList.length,
                      itemBuilder: (context, index) {
                        final person = _filteredAndSortedList[index];
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedPerson = person);
                            _setScreen(Screen.detail);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade50))
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF9333EA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text(person.createdAt, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${person.year}년 | ${person.age}세 | ${person.affiliation}', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.grey.shade300),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ),
              ],
            ),
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
                onPressed: () => _setScreen(Screen.input),
                backgroundColor: Colors.indigo,
                shape: const CircleBorder(),
                elevation: 10,
                child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, int badgeCount = 0}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 24),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4, right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
      ],
    );
  }

  Widget _buildInputScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            _buildAppbar('정보 등록', onBack: () => _setScreen(Screen.list)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('성함'),
                    _buildTextField(onChanged: (v) => _formName = v, hintText: '이름을 입력하세요'),
                    const SizedBox(height: 24),
                    _buildLabel('나이'),
                    _buildTextField(onChanged: (v) => _formAge = v, hintText: '나이를 입력하세요', keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    _buildLabel('소속'),
                    _buildTextField(onChanged: (v) => _formAffiliation = v, hintText: '소속 부서 또는 단체'),
                    const SizedBox(height: 24),
                    _buildLabel('저장할 년도'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2))),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _formYear--)),
                          Expanded(child: Text('$_formYear년', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _formYear++)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('저장할 월 선택'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final m = index + 1;
                        final isSelected = _formMonth == m;
                        return InkWell(
                          onTap: () => setState(() => _formMonth = m),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade200, width: 2)
                            ),
                            child: Text('${m}월', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade400)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.save, color: Colors.white),
                        label: const Text('정보 저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _saveNewPersonnel,
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailScreen() {
    if (_selectedPerson == null) return const SizedBox();
    final p = _selectedPerson!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _setScreen(Screen.list),
                    child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.arrow_back)),
                  ),
                  const SizedBox(width: 8),
                  const Text('정보 수정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () {
                      _showConfirm('삭제 확인', '${p.name}님의 정보를 휴지통으로 보내시겠습니까?', () {
                        setState(() {
                          final idx = _personnelList.indexWhere((element) => element.id == p.id);
                          if (idx >= 0) {
                            _personnelList[idx] = p.copyWith(deletedAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
                          }
                          _selectedPerson = null;
                          _screen = Screen.list;
                        });
                        _saveListData();
                      });
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 96, height: 96,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF9333EA)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))]
                        ),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.user, size: 48, color: Colors.white),
                      ),
                    ),
                    _buildLabel('성함'),
                    _buildTextField(onChanged: (v) => p.copyWith(name: v), initialValue: p.name),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('나이'),
                          _buildTextField(onChanged: (v) => _selectedPerson = p.copyWith(age: int.tryParse(v) ?? p.age), initialValue: p.age.toString(), keyboardType: TextInputType.number),
                        ])),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _buildLabel('소속'),
                          _buildTextField(onChanged: (v) => _selectedPerson = p.copyWith(affiliation: v), initialValue: p.affiliation),
                        ])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('상세 내용'),
                    TextFormField(
                      initialValue: p.details,
                      onChanged: (v) => _selectedPerson = p.copyWith(details: v),
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                     _buildLabel('보관 년도 변경'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2))),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selectedPerson = p.copyWith(year: p.year - 1))),
                          Expanded(child: Text('${p.year}년', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selectedPerson = p.copyWith(year: p.year + 1))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildLabel('보관 월 변경'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final m = index + 1;
                        final isSelected = p.month == m;
                        return InkWell(
                          onTap: () => setState(() => _selectedPerson = p.copyWith(month: m)),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade200, width: 2)
                            ),
                            child: Text('${m}월', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade400)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text('최초 등록 일시: ${p.createdAt}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.save, color: Colors.white),
                        label: const Text('수정 내용 저장', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          setState(() {
                            final idx = _personnelList.indexWhere((element) => element.id == p.id);
                            if (idx >= 0) _personnelList[idx] = p;
                            _selectedPerson = null;
                            _screen = Screen.list;
                          });
                          _saveListData();
                        },
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            _buildAppbar('비밀번호 변경', onBack: () => _setScreen(Screen.list)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.keyRound, size: 48, color: Colors.indigo),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('현재 비밀번호'),
                        _buildTextField(onChanged: (v) => _oldPassword = v, hintText: '현재 비밀번호 입력', obscureText: true),
                        const SizedBox(height: 24),
                        _buildLabel('새 비밀번호'),
                        _buildTextField(onChanged: (v) => _newPassword = v, hintText: '새 비밀번호 입력', obscureText: true),
                        const SizedBox(height: 24),
                        _buildLabel('새 비밀번호 확인'),
                        _buildTextField(onChanged: (v) => _confirmPassword = v, hintText: '새 비밀번호 다시 입력', obscureText: true),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton.icon(
                            icon: const Icon(LucideIcons.checkCircle2, color: Colors.white),
                            label: const Text('비밀번호 변경 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () {
                              if (_oldPassword != _currentPassword) {
                                _showAlert('오류', '현재 비밀번호가 일치하지 않습니다.');
                                return;
                              }
                              if (_newPassword != _confirmPassword) {
                                _showAlert('오류', '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.');
                                return;
                              }
                              if (_newPassword.length < 4) {
                                _showAlert('오류', '비밀번호는 최소 4자리 이상이어야 합니다.');
                                return;
                              }
                              _savePassword(_newPassword);
                              _showAlert('성공', '비밀번호가 성공적으로 변경되었습니다.');
                              setState(() {
                                _oldPassword = ''; _newPassword = ''; _confirmPassword = '';
                                _screen = Screen.list;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    const Align(alignment: Alignment.centerLeft, child: Text('데이터 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _exportCSV,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.transparent, width: 2)
                              ),
                              child: const Column(
                                children: [
                                  Icon(LucideIcons.save, size: 32, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('한글/엑셀 파일', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _importJSON,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.transparent, width: 2)
                              ),
                              child: const Column(
                                children: [
                                  Icon(LucideIcons.plus, size: 32, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('불러오기', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('데이터는 브라우저(기기)에 자동으로 저장됩니다.\n\'한글/엑셀 파일\' 버튼으로 명단을 문서로 저장할 수 있습니다.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTrashScreen() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24).copyWith(bottom: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => _setScreen(Screen.list),
                    child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.arrow_back)),
                  ),
                  const SizedBox(width: 8),
                  const Text('휴지통', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_trashList.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _showConfirm('휴지통 비우기', '휴지통을 모두 비우시겠습니까? 모든 데이터가 영구 삭제됩니다.', () {
                          setState(() {
                            _personnelList.removeWhere((p) => p.deletedAt != null);
                          });
                          _saveListData();
                        });
                      },
                      child: const Text('비우기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
            Expanded(
              child: _trashList.isEmpty 
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.trash2, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('휴지통이 비어 있습니다.', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashList.length,
                  itemBuilder: (context, index) {
                    final p = _trashList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('삭제일: ${p.deletedAt}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${p.year}년 ${p.month}월 | ${p.age}세 | ${p.affiliation}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      final idx = _personnelList.indexWhere((element) => element.id == p.id);
                                      if (idx >= 0) _personnelList[idx] = p.copyWith(clearDeletedAt: true);
                                    });
                                    _saveListData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: const Text('복구', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    _showConfirm('영구 삭제', '이 정보를 영구적으로 삭제하시겠습니까? 복구할 수 없습니다.', () {
                                      setState(() {
                                        _personnelList.removeWhere((element) => element.id == p.id);
                                      });
                                      _saveListData();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: const Text('영구 삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppbar(String title, {required VoidCallback onBack}) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.arrow_back)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
    );
  }

  Widget _buildTextField({required Function(String) onChanged, String? hintText, String? initialValue, bool obscureText = false, TextInputType? keyboardType}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade100, width: 2)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade100, width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigo, width: 2)),
      ),
    );
  }
}

class LockScreen extends StatefulWidget {
  final String correctPassword;
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const LockScreen({super.key, required this.correctPassword, required this.onSuccess, required this.onFail});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    if (_controller.text == widget.correctPassword) {
      widget.onSuccess();
    } else {
      widget.onFail();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
          ],
          border: Border.all(color: Colors.grey.shade100)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shieldCheck, size: 48, color: Colors.indigo),
            ),
            const SizedBox(height: 24),
            const Text('보안 확인', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('앱 진입을 위해 비밀번호를 입력하세요', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '패스워드 입력',
                hintStyle: const TextStyle(fontSize: 16, letterSpacing: 0),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit, 
                child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
