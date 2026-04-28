import 'package:flutter/material.dart';

/// 뒤로가기 버튼과 제목을 포함하는 공통 상단 바.
///
/// [trailing]에 위젯을 전달하면 오른쪽 끝에 표시된다.
/// input, detail, settings, trash 화면에서 공통으로 사용한다.
class AppBarWidget extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  /// 오른쪽에 표시할 추가 위젯 (삭제 버튼, 비우기 버튼 등).
  final Widget? trailing;

  const AppBarWidget({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24).copyWith(bottom: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            child: Container(padding: const EdgeInsets.all(8), child: const Icon(Icons.arrow_back)),
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
