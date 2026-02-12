import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_academy__app/utils/formatters.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.label,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
        suffixText: '원',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        ThousandsSeparatorInputFormatter(),
      ],
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return '$label을 입력해주세요';
              }
              return null;
            }
          : null,
    );
  }
}
