import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_widget.dart';

/// 소프트 삭제된 인원을 관리하는 휴지통 화면.
///
/// 각 항목에서 복구(활성 상태로 되돌리기) 또는 영구 삭제를 선택할 수 있다.
/// 헤더의 '비우기' 버튼으로 전체를 한 번에 영구 삭제한다.
/// 목록이 비어 있으면 '비우기' 버튼이 숨겨진다.
class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonnelProvider>();
    final trashList = provider.trashList;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            AppBarWidget(
              title: '휴지통',
              onBack: () => provider.setScreen(Screen.list),
              trailing: trashList.isNotEmpty
                  ? TextButton(
                      onPressed: () => showConfirmDialog(
                        context,
                        '휴지통 비우기',
                        '휴지통을 모두 비우시겠습니까? 모든 데이터가 영구 삭제됩니다.',
                        provider.emptyTrash,
                      ),
                      child: const Text('비우기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    )
                  : null,
            ),
            Expanded(
              child: trashList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.trash2, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('휴지통이 비어 있습니다.', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: trashList.length,
                      itemBuilder: (context, index) => _buildTrashItem(context, provider, trashList[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 휴지통 항목 카드. 복구와 영구 삭제 버튼을 포함한다.
  Widget _buildTrashItem(BuildContext context, PersonnelProvider provider, Personnel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                  onTap: () => provider.restorePersonnel(p.id),
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
                  onTap: () => showConfirmDialog(
                    context,
                    '영구 삭제',
                    '이 정보를 영구적으로 삭제하시겠습니까? 복구할 수 없습니다.',
                    () => provider.permanentDeletePersonnel(p.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Text('영구 삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
