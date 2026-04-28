import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/form_widgets.dart';
import '../widgets/month_grid.dart';
import '../widgets/year_selector.dart';

/// 인원 정보 수정 화면.
///
/// [initState]에서 Provider의 [selectedPerson]을 로컬 [_edited]에 복사해
/// 편집 도중 목록에 즉시 반영되지 않도록 한다.
/// '수정 내용 저장' 버튼을 눌러야 [PersonnelProvider.updatePersonnel]이 호출된다.
///
/// (기존 코드의 버그 수정: 원래는 이름/소속 변경이 setState 없이 _selectedPerson에
/// 할당되어 저장 시 반영되지 않는 문제가 있었다. 로컬 복사 패턴으로 수정.)
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// 편집 중인 인원 데이터. Provider의 selectedPerson 을 initState 에서 복사한다.
  late Personnel _edited;

  @override
  void initState() {
    super.initState();
    _edited = context.read<PersonnelProvider>().selectedPerson!;
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
            AppBarWidget(
              title: '정보 수정',
              onBack: () => provider.setScreen(Screen.list),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
                onPressed: () => showConfirmDialog(
                  context,
                  '삭제 확인',
                  '${_edited.name}님의 정보를 휴지통으로 보내시겠습니까?',
                  () => provider.softDeletePersonnel(_edited.id),
                ),
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
                        width: 96,
                        height: 96,
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF9333EA)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.user, size: 48, color: Colors.white),
                      ),
                    ),
                    const FormLabel('성함'),
                    FormTextField(
                      initialValue: _edited.name,
                      onChanged: (v) => setState(() => _edited = _edited.copyWith(name: v)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormLabel('나이'),
                              FormTextField(
                                initialValue: _edited.age.toString(),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => setState(() => _edited = _edited.copyWith(age: int.tryParse(v) ?? _edited.age)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormLabel('소속'),
                              FormTextField(
                                initialValue: _edited.affiliation,
                                onChanged: (v) => setState(() => _edited = _edited.copyWith(affiliation: v)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const FormLabel('상세 내용'),
                    TextFormField(
                      initialValue: _edited.details,
                      onChanged: (v) => setState(() => _edited = _edited.copyWith(details: v)),
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
                    const FormLabel('보관 년도 변경'),
                    YearSelector(
                      year: _edited.year,
                      onDecrement: () => setState(() => _edited = _edited.copyWith(year: _edited.year - 1)),
                      onIncrement: () => setState(() => _edited = _edited.copyWith(year: _edited.year + 1)),
                    ),
                    const SizedBox(height: 24),
                    const FormLabel('보관 월 변경'),
                    MonthGrid(
                      selectedMonth: _edited.month,
                      onMonthSelected: (m) => setState(() => _edited = _edited.copyWith(month: m)),
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text('최초 등록 일시: ${_edited.createdAt}', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
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
                        onPressed: () => provider.updatePersonnel(_edited),
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
