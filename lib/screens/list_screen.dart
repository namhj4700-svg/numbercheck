import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../widgets/icon_button_badge.dart';

/// 인원 목록 메인 화면.
///
/// 헤더에서 년도·월 필터와 이름/소속 검색을 제공한다.
/// 검색어가 있으면 년도·월 필터 대신 전체 명단에서 검색한다.
/// FAB(+)을 누르면 [InputScreen]으로 이동한다.
///
/// [StatefulWidget]인 이유: 월 탭 가로 스크롤에
/// [ScrollController](_monthScrollController)가 필요하기 때문이다.
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  /// 월 탭 바의 마우스 휠 스크롤을 처리하기 위한 컨트롤러.
  final _monthScrollController = ScrollController();

  @override
  void dispose() {
    _monthScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonnelProvider>();
    final list = provider.filteredAndSortedList;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, provider),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.user, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) => _buildListTile(context, provider, list, index),
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 32,
              right: 32,
              child: FloatingActionButton(
                onPressed: () => provider.setScreen(Screen.input),
                backgroundColor: Colors.indigo,
                shape: const CircleBorder(),
                elevation: 10,
                child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 제목, 년도 선택, 검색창, 월 탭 바를 포함하는 고정 헤더.
  Widget _buildHeader(BuildContext context, PersonnelProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                    decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(LucideIcons.users, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('인원 명단', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => provider.setSelectedYear(provider.selectedYear - 1),
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_left, size: 16)),
                          ),
                          Text('${provider.selectedYear}년', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          InkWell(
                            onTap: () => provider.setSelectedYear(provider.selectedYear + 1),
                            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right, size: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // 휴지통 아이콘에 삭제된 인원 수를 뱃지로 표시
                  IconButtonBadge(
                    icon: LucideIcons.trash2,
                    onTap: () => provider.setScreen(Screen.trash),
                    badgeCount: provider.trashList.length,
                  ),
                  const SizedBox(width: 8),
                  IconButtonBadge(icon: LucideIcons.settings, onTap: () => provider.setScreen(Screen.settings)),
                  const SizedBox(width: 8),
                  IconButtonBadge(icon: LucideIcons.logOut, onTap: () => provider.setScreen(Screen.lock)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: provider.setSearchQuery,
            decoration: InputDecoration(
              hintText: '검색어 입력 (이름, 소속)',
              prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          // Listener 로 마우스 휠 이벤트를 가로채 월 탭 바를 좌우 스크롤한다
          Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                _monthScrollController.jumpTo(
                  (_monthScrollController.offset + pointerSignal.scrollDelta.dy).clamp(
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
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: List.generate(12, (index) {
                    final m = index + 1;
                    final isSelected = provider.selectedMonth == m;
                    return GestureDetector(
                      onTap: () => provider.setSelectedMonth(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                        ),
                        child: Text(
                          '$m월',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.indigo : Colors.grey.shade500),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 인원 한 명을 표시하는 목록 행.
  /// 탭하면 해당 인원을 선택하고 [DetailScreen]으로 이동한다.
  Widget _buildListTile(BuildContext context, PersonnelProvider provider, List<Personnel> list, int index) {
    final person = list[index];
    return InkWell(
      onTap: () {
        provider.selectPerson(person);
        provider.setScreen(Screen.detail);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
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
  }
}
