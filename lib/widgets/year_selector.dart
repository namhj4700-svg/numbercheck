import 'package:flutter/material.dart';

/// 좌우 화살표 버튼으로 년도를 증감하는 선택 위젯.
///
/// input, detail 화면에서 공통으로 사용한다.
class YearSelector extends StatelessWidget {
  /// 현재 표시할 년도.
  final int year;

  /// 왼쪽 화살표(감소) 버튼 콜백.
  final VoidCallback onDecrement;

  /// 오른쪽 화살표(증가) 버튼 콜백.
  final VoidCallback onIncrement;

  const YearSelector({
    super.key,
    required this.year,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 2)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onDecrement),
          Expanded(
            child: Text(
              '$year년',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onIncrement),
        ],
      ),
    );
  }
}
