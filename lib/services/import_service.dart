import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/personnel.dart';

/// JSON 파일에서 인원 목록을 가져오는 서비스.
class ImportService {
  /// 파일 탐색기를 열어 .json 파일을 선택하고 [Personnel] 목록으로 파싱한다.
  ///
  /// 파일을 선택하지 않거나 최상위가 List 가 아닌 경우 null 을 반환한다.
  /// 호출 측에서 null 체크 후 기존 목록 교체 여부를 결정해야 한다.
  Future<List<Personnel>?> importJSON() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.first.bytes == null) return null;

    final content = utf8.decode(result.files.first.bytes!);
    final jsonList = json.decode(content);
    if (jsonList is! List) return null;

    return jsonList.map((e) => Personnel.fromMap(e as Map<String, dynamic>)).toList();
  }
}
