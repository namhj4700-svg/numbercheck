import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/personnel.dart';
import '../providers/personnel_provider.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../utils/dialogs.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/form_widgets.dart';

/// 설정 화면 — 비밀번호 변경과 데이터 관리(CSV 내보내기, JSON 가져오기).
///
/// 비밀번호 폼 값은 이 화면 로컬 상태로만 관리하고
/// 변경 완료 시 [PersonnelProvider.changePassword]를 호출한다.
///
/// CSV 내보내기와 JSON 가져오기는 각각 [ExportService], [ImportService]에 위임한다.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _oldPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  final _exportService = ExportService();
  final _importService = ImportService();

  /// 비밀번호 변경 유효성 검사 후 저장한다.
  /// 현재 비밀번호 불일치, 새 비밀번호 확인 불일치, 4자리 미만 시 오류를 표시한다.
  void _changePassword() {
    final provider = context.read<PersonnelProvider>();

    if (_oldPassword != provider.currentPassword) {
      showAlertDialog(context, '오류', '현재 비밀번호가 일치하지 않습니다.');
      return;
    }
    if (_newPassword != _confirmPassword) {
      showAlertDialog(context, '오류', '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.');
      return;
    }
    if (_newPassword.length < 4) {
      showAlertDialog(context, '오류', '비밀번호는 최소 4자리 이상이어야 합니다.');
      return;
    }

    provider.changePassword(_newPassword);
    showAlertDialog(context, '성공', '비밀번호가 성공적으로 변경되었습니다.');
    setState(() {
      _oldPassword = '';
      _newPassword = '';
      _confirmPassword = '';
    });
    provider.setScreen(Screen.list);
  }

  Future<void> _exportCSV() async {
    try {
      final list = context.read<PersonnelProvider>().personnelList;
      await _exportService.exportCSV(list);
    } catch (e) {
      if (mounted) showAlertDialog(context, '오류', '파일 저장 중 오류가 발생했습니다: $e');
    }
  }

  /// JSON 파일을 선택해 파싱한 뒤, 교체 여부를 확인하고 기존 목록을 대체한다.
  /// [ImportService.importJSON]이 null 을 반환하면 아무 동작도 하지 않는다.
  Future<void> _importJSON() async {
    try {
      final imported = await _importService.importJSON();
      if (imported == null || !mounted) return;

      showConfirmDialog(
        context,
        '불러오기 확인',
        '기존 명단이 삭제되고 불러온 명단으로 대체됩니다. 계속하시겠습니까?',
        () async {
          await context.read<PersonnelProvider>().replacePersonnelList(imported);
          if (mounted) showAlertDialog(context, '성공', '명단을 성공적으로 불러왔습니다.');
        },
      );
    } catch (_) {
      if (mounted) showAlertDialog(context, '오류', '올바른 명단 파일 형식이 아니거나 오류가 발생했습니다.');
    }
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
            AppBarWidget(title: '비밀번호 변경', onBack: () => provider.setScreen(Screen.list)),
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
                        const FormLabel('현재 비밀번호'),
                        FormTextField(onChanged: (v) => _oldPassword = v, hintText: '현재 비밀번호 입력', obscureText: true),
                        const SizedBox(height: 24),
                        const FormLabel('새 비밀번호'),
                        FormTextField(onChanged: (v) => _newPassword = v, hintText: '새 비밀번호 입력', obscureText: true),
                        const SizedBox(height: 24),
                        const FormLabel('새 비밀번호 확인'),
                        FormTextField(onChanged: (v) => _confirmPassword = v, hintText: '새 비밀번호 다시 입력', obscureText: true),
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
                            onPressed: _changePassword,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('데이터 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _dataButton(icon: LucideIcons.save, label: '한글/엑셀 파일', onTap: _exportCSV)),
                        const SizedBox(width: 16),
                        Expanded(child: _dataButton(icon: LucideIcons.plus, label: '불러오기', onTap: _importJSON)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '데이터는 브라우저(기기)에 자동으로 저장됩니다.\n\'한글/엑셀 파일\' 버튼으로 명단을 문서로 저장할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
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

  /// 데이터 관리 영역의 카드형 버튼.
  Widget _dataButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
