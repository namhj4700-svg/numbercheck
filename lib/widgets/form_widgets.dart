import 'package:flutter/material.dart';

/// 입력 폼 필드 위의 회색 레이블 텍스트.
///
/// 성함, 나이, 소속 등 입력 항목 이름을 표시할 때 사용한다.
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
      ),
    );
  }
}

/// 앱 전체에서 공통으로 사용하는 밑줄 스타일 텍스트 입력 필드.
///
/// 비밀번호 입력에는 [obscureText]를,
/// 숫자 전용 입력에는 [keyboardType]을 지정한다.
/// [initialValue]는 수정 화면처럼 기존 값을 미리 채울 때 사용한다.
class FormTextField extends StatelessWidget {
  final Function(String) onChanged;
  final String? hintText;
  final String? initialValue;
  final bool obscureText;
  final TextInputType? keyboardType;

  const FormTextField({
    super.key,
    required this.onChanged,
    this.hintText,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade100, width: 2)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade100, width: 2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigo, width: 2)),
      ),
    );
  }
}
