import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/widgets/custom_dropdown_field.dart';
import 'package:k_academy__app/widgets/amount_input_field.dart';
import 'package:k_academy__app/utils/constants.dart';
import 'package:k_academy__app/utils/formatters.dart';
import 'package:k_academy__app/utils/date_utils.dart' as app_date_utils;

class ExpenseInputDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Expense? existingExpense;

  const ExpenseInputDialog({
    super.key,
    required this.selectedDate,
    this.existingExpense,
  });

  @override
  State<ExpenseInputDialog> createState() => _ExpenseInputDialogState();
}

class _ExpenseInputDialogState extends State<ExpenseInputDialog> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  // Controllers
  final _amountController = TextEditingController();
  final _cancellationAmountController = TextEditingController();
  final _memoController = TextEditingController();

  // Form values
  String? _childName;
  DateTime? _paymentDate;
  String? _businessName;
  String? _subject;
  String? _instructor;
  String? _detail;
  String _classType = classTypes[0]; // Default: 현강
  String _paymentMethod = paymentMethods[0]; // Default: 카드
  String? _cardName;
  bool _isRefunded = false;
  List<String> _calendarLabels = ['강사'];

  @override
  void initState() {
    super.initState();

    if (widget.existingExpense != null) {
      // Edit mode: pre-fill with existing data
      final expense = widget.existingExpense!;
      _childName = expense.childName;
      _paymentDate = expense.paymentDate;
      _businessName = expense.businessName;
      _subject = expense.subject;
      _instructor = expense.instructor;
      _detail = expense.detail;
      _classType = expense.classType;
      _paymentMethod = expense.paymentMethod;
      _cardName = expense.cardName;
      _amountController.text = _formatNumber(expense.amount);
      _cancellationAmountController.text = _formatNumber(expense.cancellationAmount);
      _isRefunded = expense.isRefunded;
      _memoController.text = expense.memo ?? '';
      _calendarLabels = List<String>.from(expense.calendarLabels);
    } else {
      // Add mode: use selected date
      _paymentDate = widget.selectedDate;
    }
  }

  String _formatNumber(int number) {
    if (number == 0) return '';
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cancellationAmountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropdownProvider = Provider.of<DropdownProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
              child: Row(
                children: [
                  Text(
                    widget.existingExpense != null ? '지출 수정' : '지출 입력',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 폼
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                // 1. 자녀
                CustomDropdownField(
                  label: '자녀',
                  value: _childName,
                  options: dropdownProvider.childNames,
                  onChanged: (value) {
                    setState(() {
                      _childName = value;
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addChildName(value);
                    setState(() {
                      _childName = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removeChildName(value);
                    if (_childName == value) {
                      setState(() => _childName = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. 결제일
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '결제일 *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _paymentDate != null
                          ? app_date_utils.formatDateKorean(_paymentDate!)
                          : '날짜를 선택하세요',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 상호
                CustomDropdownField(
                  label: '학원',
                  value: _businessName,
                  options: dropdownProvider.businessNames,
                  onChanged: (value) {
                    setState(() {
                      _businessName = value;
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addBusinessName(value);
                    setState(() {
                      _businessName = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removeBusinessName(value);
                    if (_businessName == value) {
                      setState(() => _businessName = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 4. 과목
                CustomDropdownField(
                  label: '과목',
                  value: _subject,
                  options: dropdownProvider.allSubjects,
                  onChanged: (value) {
                    setState(() {
                      _subject = value;
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addCustomSubject(value);
                    setState(() {
                      _subject = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removeSubject(value);
                    if (_subject == value) {
                      setState(() => _subject = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 5. 강사
                CustomDropdownField(
                  label: '강사',
                  value: _instructor,
                  options: dropdownProvider.instructorNames,
                  onChanged: (value) {
                    setState(() {
                      _instructor = value;
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addInstructorName(value);
                    setState(() {
                      _instructor = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removeInstructorName(value);
                    if (_instructor == value) {
                      setState(() => _instructor = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 6. 세부내역
                CustomDropdownField(
                  label: '세부내역',
                  value: _detail,
                  options: dropdownProvider.allDetails,
                  onChanged: (value) {
                    setState(() {
                      _detail = value;
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addCustomDetail(value);
                    setState(() {
                      _detail = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removeDetail(value);
                    if (_detail == value) {
                      setState(() => _detail = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 7. 현강/라이브
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '수업 형태 *',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: classTypes.map((type) {
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _classType = type;
                              });
                            },
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: type,
                                  groupValue: _classType,
                                  onChanged: (value) {
                                    setState(() {
                                      _classType = value!;
                                    });
                                  },
                                ),
                                Text(type),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 8. 결제방법
                CustomDropdownField(
                  label: '결제방법',
                  value: _paymentMethod,
                  options: dropdownProvider.allPaymentMethods,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                      if (_paymentMethod != '카드') {
                        _cardName = null;
                      }
                    });
                  },
                  onValueAdded: (value) {
                    dropdownProvider.addCustomPaymentMethod(value);
                    setState(() {
                      _paymentMethod = value;
                    });
                  },
                  onItemDeleted: (value) {
                    dropdownProvider.removePaymentMethod(value);
                    if (_paymentMethod == value) {
                      setState(() => _paymentMethod = paymentMethods[0]);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 8-1. 카드명 (조건부)
                if (_paymentMethod == '카드') ...[
                  CustomDropdownField(
                    label: '카드명',
                    value: _cardName,
                    options: dropdownProvider.cardNames,
                    required: true,
                    onChanged: (value) {
                      setState(() {
                        _cardName = value;
                      });
                    },
                    onValueAdded: (value) {
                      dropdownProvider.addCardName(value);
                      setState(() {
                        _cardName = value;
                      });
                    },
                    onItemDeleted: (value) {
                      dropdownProvider.removeCardName(value);
                      if (_cardName == value) {
                        setState(() => _cardName = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // 9. 금액
                AmountInputField(
                  controller: _amountController,
                  label: '금액',
                  required: true,
                ),
                const SizedBox(height: 16),

                // 10. 취소금액
                AmountInputField(
                  controller: _cancellationAmountController,
                  label: '취소금액',
                  required: false,
                ),
                const SizedBox(height: 16),

                // 11. 환불 여부
                InkWell(
                  onTap: () {
                    setState(() {
                      _isRefunded = !_isRefunded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isRefunded,
                          onChanged: (value) {
                            setState(() {
                              _isRefunded = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('환불 여부 확인 완료'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 12. 메모
                TextFormField(
                  controller: _memoController,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    border: OutlineInputBorder(),
                    hintText: '자유롭게 메모를 작성하세요',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // 13. 캘린더 표시 항목
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '캘린더에 표시할 항목',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: ['학원', '과목', '강사'].map((label) {
                        final isSelected = _calendarLabels.contains(label);
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _calendarLabels.remove(label);
                                } else {
                                  _calendarLabels.add(label);
                                }
                              });
                            },
                            child: Row(
                              children: [
                                IgnorePointer(
                                  child: Radio<bool>(
                                    value: true,
                                    groupValue: isSelected,
                                    onChanged: (_) {},
                                  ),
                                ),
                                Text(label),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 삭제 버튼 (수정 모드에서만)
                  if (widget.existingExpense != null)
                    TextButton(
                      onPressed: _deleteExpense,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('삭제'),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.existingExpense != null ? '수정' : '저장'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제일을 선택해주세요')),
      );
      return;
    }

    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final dropdownProvider =
        Provider.of<DropdownProvider>(context, listen: false);

    // Save dropdown history
    if (_childName != null) {
      await dropdownProvider.addChildName(_childName!);
    }
    if (_businessName != null) {
      await dropdownProvider.addBusinessName(_businessName!);
    }
    if (_instructor != null) {
      await dropdownProvider.addInstructorName(_instructor!);
    }
    if (_cardName != null && _cardName!.isNotEmpty) {
      await dropdownProvider.addCardName(_cardName!);
    }

    // Create or update expense
    final expense = Expense(
      id: widget.existingExpense?.id ?? _uuid.v4(),
      childName: _childName!,
      paymentDate: _paymentDate!,
      businessName: _businessName!,
      subject: _subject!,
      instructor: _instructor!,
      detail: _detail!,
      classType: _classType,
      paymentMethod: _paymentMethod,
      cardName: _paymentMethod == '카드' ? _cardName : null,
      amount: parseFormattedNumber(_amountController.text),
      cancellationAmount: parseFormattedNumber(_cancellationAmountController.text),
      isRefunded: _isRefunded,
      memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      calendarLabels: _calendarLabels,
    );

    if (widget.existingExpense != null) {
      // Update existing expense
      await expenseProvider.updateExpense(expense);
    } else {
      // Add new expense
      await expenseProvider.addExpense(expense);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingExpense != null ? '지출이 수정되었습니다' : '지출이 저장되었습니다'),
        ),
      );
    }
  }

  Future<void> _deleteExpense() async {
    if (widget.existingExpense == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 지출 내역을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      // Delete the expense
      await expenseProvider.deleteExpense(widget.existingExpense!.id);

      // Force reload to update the calendar
      await expenseProvider.loadExpenses();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출이 삭제되었습니다')),
        );
      }
    }
  }
}
