import 'package:flutter/material.dart';

/// 1~12월을 4열 그리드로 표시하는 월 선택 위젯.
///
/// 선택된 월은 인디고 배경으로 강조된다.
/// input, detail 화면에서 공통으로 사용한다.
class MonthGrid extends StatelessWidget {
  /// 현재 선택된 월 (1~12).
  final int selectedMonth;

  /// 월 탭 시 호출되는 콜백. 선택된 월 번호를 전달한다.
  final ValueChanged<int> onMonthSelected;

  const MonthGrid({
    super.key,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      // 상위 ScrollView 와 충돌하지 않도록 자체 스크롤 비활성화
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final m = index + 1;
        final isSelected = selectedMonth == m;
        return InkWell(
          onTap: () => onMonthSelected(m),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.grey.shade200,
                width: 2,
              ),
            ),
            child: Text(
              '$m월',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ),
        );
      },
    );
  }
}
