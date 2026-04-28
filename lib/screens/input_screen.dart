import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/form_widgets.dart';
import '../widgets/month_grid.dart';
import '../widgets/year_selector.dart';

/// 신규 인원 등록 화면.
///
/// 폼 값(_name, _age, _affiliation, _year, _month)은 이 화면 로컬 상태로만 관리한다.
/// 저장 버튼을 누르면 [PersonnelProvider.addPersonnel]을 호출하고
/// 자동으로 목록 화면으로 전환된다.
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  String _name = '';
  String _age = '';
  String _affiliation = '';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  /// 입력값을 검증하고 신규 인원을 저장한다.
  /// 필수 항목(이름, 나이, 소속)이 비어 있으면 알림을 표시한다.
  void _save() {
    if (_name.isEmpty || _age.isEmpty || _affiliation.isEmpty) {
      showAlertDialog(context, '입력 오류', '모든 필수 항목을 입력해주세요.');
      return;
    }

    final newPerson = Personnel(
      // 밀리초 타임스탬프를 ID 로 사용해 중복을 방지한다
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name,
      age: int.tryParse(_age) ?? 0,
      affiliation: _affiliation,
      year: _year,
      month: _month,
      createdAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );

    context.read<PersonnelProvider>().addPersonnel(newPerson);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PersonnelProvider>();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 672),
        color: Colors.white,
        child: Column(
          children: [
            AppBarWidget(title: '정보 등록', onBack: () => provider.setScreen(Screen.list)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FormLabel('성함'),
                    FormTextField(onChanged: (v) => _name = v, hintText: '이름을 입력하세요'),
                    const SizedBox(height: 24),
                    const FormLabel('나이'),
                    FormTextField(onChanged: (v) => _age = v, hintText: '나이를 입력하세요', keyboardType: TextInputType.number),
                    const SizedBox(height: 24),
                    const FormLabel('소속'),
                    FormTextField(onChanged: (v) => _affiliation = v, hintText: '소속 부서 또는 단체'),
                    const SizedBox(height: 24),
                    const FormLabel('저장할 년도'),
                    YearSelector(
                      year: _year,
                      onDecrement: () => setState(() => _year--),
                      onIncrement: () => setState(() => _year++),
                    ),
                    const SizedBox(height: 24),
                    const FormLabel('저장할 월 선택'),
                    MonthGrid(
                      selectedMonth: _month,
                      onMonthSelected: (m) => setState(() => _month = m),
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
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
