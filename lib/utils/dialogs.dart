import 'package:flutter/material.dart';

/// 확인 버튼 하나짜리 알림 다이얼로그를 표시한다.
///
/// 유효성 검사 실패, 오류 메시지 등 단순 안내에 사용한다.
void showAlertDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
      ],
    ),
  );
}

/// 취소/확인 버튼이 있는 확인 요청 다이얼로그를 표시한다.
///
/// 사용자가 '확인'을 누를 때만 [onConfirm]이 호출된다.
/// 삭제, 가져오기 등 되돌리기 어려운 작업 전에 사용한다.
void showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
      ],
    ),
  );
}
