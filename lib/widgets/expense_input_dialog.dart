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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.existingExpense != null ? '지출 수정' : '지출 입력'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
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
                  label: '상호',
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
                ),
                const SizedBox(height: 16),

                // 4. 과목
                DropdownButtonFormField<String>(
                  initialValue: _subject,
                  decoration: const InputDecoration(
                    labelText: '과목 *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...dropdownProvider.allSubjects.map((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: addNewOption,
                      child: Text(
                        addNewOption,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == addNewOption) {
                      _showAddCustomSubjectDialog(context, dropdownProvider);
                    } else {
                      setState(() {
                        _subject = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || value == addNewOption) {
                      return '과목을 선택해주세요';
                    }
                    return null;
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
                ),
                const SizedBox(height: 16),

                // 6. 세부내역
                DropdownButtonFormField<String>(
                  initialValue: _detail,
                  decoration: const InputDecoration(
                    labelText: '세부내역 *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...dropdownProvider.allDetails.map((detail) {
                      return DropdownMenuItem<String>(
                        value: detail,
                        child: Text(detail),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: addNewOption,
                      child: Text(
                        addNewOption,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == addNewOption) {
                      _showAddCustomDetailDialog(context, dropdownProvider);
                    } else {
                      setState(() {
                        _detail = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || value == addNewOption) {
                      return '세부내역을 선택해주세요';
                    }
                    return null;
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
                        color: Colors.black54,
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
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: '결제방법 *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...dropdownProvider.allPaymentMethods.map((method) {
                      return DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: addNewOption,
                      child: Text(
                        addNewOption,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == addNewOption) {
                      _showAddCustomPaymentMethodDialog(context, dropdownProvider);
                    } else {
                      setState(() {
                        _paymentMethod = value!;
                        if (_paymentMethod != '카드') {
                          _cardName = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 8-1. 카드명 (조건부)
                if (_paymentMethod == '카드') ...[
                  DropdownButtonFormField<String>(
                    value: _cardName,
                    decoration: const InputDecoration(
                      labelText: '카드명',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...dropdownProvider.cardNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: addNewOption,
                        child: Text(
                          addNewOption,
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == addNewOption) {
                        _showAddCardNameDialog(context, dropdownProvider);
                      } else {
                        setState(() {
                          _cardName = value;
                        });
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
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Delete button (only in edit mode)
                    if (widget.existingExpense != null)
                      TextButton(
                        onPressed: _deleteExpense,
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('삭제'),
                      )
                    else
                      const SizedBox.shrink(),
                    // Right side buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveExpense,
                          child: const Text('저장'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    );

    if (picked != null) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  void _showAddCustomSubjectDialog(
    BuildContext context,
    DropdownProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 과목 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '과목',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addCustomSubject(value.trim());
              setState(() {
                _subject = value.trim();
              });
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
              if (newValue.isNotEmpty) {
                provider.addCustomSubject(newValue);
                setState(() {
                  _subject = newValue;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomDetailDialog(
    BuildContext context,
    DropdownProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 세부내역 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '세부내역',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addCustomDetail(value.trim());
              setState(() {
                _detail = value.trim();
              });
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
              if (newValue.isNotEmpty) {
                provider.addCustomDetail(newValue);
                setState(() {
                  _detail = newValue;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomPaymentMethodDialog(
    BuildContext context,
    DropdownProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 결제방법 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '결제방법',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addCustomPaymentMethod(value.trim());
              setState(() {
                _paymentMethod = value.trim();
              });
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
              if (newValue.isNotEmpty) {
                provider.addCustomPaymentMethod(newValue);
                setState(() {
                  _paymentMethod = newValue;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddCardNameDialog(
    BuildContext context,
    DropdownProvider provider,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 카드명 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '카드명',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.addCardName(value.trim());
              setState(() {
                _cardName = value.trim();
              });
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
              if (newValue.isNotEmpty) {
                provider.addCardName(newValue);
                setState(() {
                  _cardName = newValue;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      await expenseProvider.deleteExpense(widget.existingExpense!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출이 삭제되었습니다')),
        );
      }
    }
  }
}
