import 'package:flutter/material.dart';
import 'package:k_academy__app/utils/constants.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String>? onValueAdded;
  final bool required;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onValueAdded,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    // Add "새로 추가" option to the list
    final allOptions = [...options, addNewOption];

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      items: allOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: option == addNewOption
                ? const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        if (newValue == addNewOption) {
          _showAddNewDialog(context);
        } else {
          onChanged(newValue);
        }
      },
      validator: required
          ? (value) {
              if (value == null || value.isEmpty || value == addNewOption) {
                return '$label을 선택해주세요';
              }
              return null;
            }
          : null,
    );
  }

  void _showAddNewDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('새 $label 추가'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && onValueAdded != null) {
              onValueAdded!(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && onValueAdded != null) {
                onValueAdded!(newValue);
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
