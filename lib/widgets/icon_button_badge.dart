import 'package:flutter/material.dart';

/// 빨간 숫자 뱃지를 선택적으로 표시하는 원형 아이콘 버튼.
///
/// [badgeCount]가 0 이면 뱃지가 숨겨진다.
/// 목록 화면 헤더의 휴지통 버튼에서 삭제된 인원 수를 표시할 때 사용한다.
class IconButtonBadge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// 0 이상일 때 오른쪽 상단에 빨간 뱃지로 표시된다.
  final int badgeCount;

  const IconButtonBadge({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.grey.shade600, size: 24),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Text(
                badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
