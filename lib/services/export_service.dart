import 'dart:convert';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../models/personnel.dart';

/// 인원 목록을 CSV 파일로 내보내는 서비스.
class ExportService {
  /// 전체 인원 목록(휴지통 포함)을 CSV 로 저장한다.
  ///
  /// 한글/Excel 호환을 위해 UTF-8 BOM(﻿)을 파일 앞에 추가한다.
  /// 셀 값은 모두 큰따옴표로 감싸 쉼표 포함 데이터를 안전하게 처리한다.
  /// 파일명 형식: 인원명단_yyyy-MM-dd.csv
  Future<void> exportCSV(List<Personnel> list) async {
    const headers = ['년도', '이름', '나이', '소속', '보관월', '등록일시', '상세내용'];
    final rows = list
        .map((p) => [
              '${p.year}년',
              p.name,
              p.age.toString(),
              p.affiliation,
              '${p.month}월',
              p.createdAt,
              // 다중 줄 내용은 공백으로 치환해 CSV 행 깨짐을 방지
              (p.details ?? '').replaceAll('\n', ' '),
            ])
        .toList();

    String csvContent = '${headers.join(',')}\n';
    csvContent += rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');

    final bytes = Uint8List.fromList(utf8.encode('﻿$csvContent'));
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await FileSaver.instance.saveFile(
      name: '인원명단_$dateStr',
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }
}
