import 'package:flutter/material.dart';
import 'package:k_academy__app/utils/constants.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String>? onValueAdded;
  final ValueChanged<String>? onItemDeleted;
  final bool required;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.onValueAdded,
    this.onItemDeleted,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: value,
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) {
                return '$label을 선택해주세요';
              }
              return null;
            }
          : null,
      builder: (field) {
        return InkWell(
          onTap: () => _showSelectionDialog(context, field),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              border: const OutlineInputBorder(),
              errorText: field.errorText,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              value ?? '',
              style: value == null
                  ? TextStyle(color: Colors.grey[600])
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _showSelectionDialog(BuildContext context, FormFieldState<String> field) {
    final uniqueOptions = options.toSet().toList();
    // Ensure current value is in the options (but not 기타/새로추가 - they're shown separately)
    if (value != null &&
        value!.isNotEmpty &&
        value != etcOption &&
        value != addNewOption &&
        !uniqueOptions.contains(value)) {
      uniqueOptions.insert(0, value!);
    }

    showDialog(
      context: context,
      builder: (ctx) => _SelectionDialog(
        label: label,
        options: uniqueOptions,
        currentValue: value,
        onSelected: (selected) {
          onChanged(selected);
          field.didChange(selected);
        },
        onDeleted: onItemDeleted,
        onAddNew: onValueAdded != null
            ? () {
                Navigator.of(ctx).pop();
                _showAddNewDialog(context, field);
              }
            : null,
      ),
    );
  }

  void _showAddNewDialog(BuildContext context, FormFieldState<String> field) {
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
              field.didChange(value.trim());
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
                field.didChange(newValue);
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

class _SelectionDialog extends StatefulWidget {
  final String label;
  final List<String> options;
  final String? currentValue;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onDeleted;
  final VoidCallback? onAddNew;

  const _SelectionDialog({
    required this.label,
    required this.options,
    required this.currentValue,
    required this.onSelected,
    this.onDeleted,
    this.onAddNew,
  });

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  late List<String> _currentOptions;

  @override
  void initState() {
    super.initState();
    _currentOptions = List.from(widget.options);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 12, 8, 0),
      title: Row(
        children: [
          Expanded(
            child: Text('${widget.label} 선택', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, weight: 700),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, color: Colors.grey[300]),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _currentOptions.length,
                itemBuilder: (context, index) {
                  final option = _currentOptions[index];
                  final isSelected = option == widget.currentValue;
                  return InkWell(
                    onTap: () {
                      widget.onSelected(option);
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          if (isSelected)
                            const Icon(Icons.check,
                                size: 16, color: Colors.blue)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (widget.onDeleted != null)
                            GestureDetector(
                              onTap: () {
                                widget.onDeleted!(option);
                                setState(() {
                                  _currentOptions.remove(option);
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.close,
                                    size: 18, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 기타
            InkWell(
              onTap: () {
                widget.onSelected(etcOption);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    if (widget.currentValue == etcOption)
                      const Icon(Icons.check, size: 16, color: Colors.blue)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 10),
                    Text(
                      etcOption,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: widget.currentValue == etcOption
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: widget.currentValue == etcOption
                            ? Colors.blue
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // + 새로 추가
            if (widget.onAddNew != null)
              InkWell(
                onTap: widget.onAddNew,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      SizedBox(width: 10),
                      Text(
                        addNewOption,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
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
