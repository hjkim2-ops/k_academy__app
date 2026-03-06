import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/selected_date_provider.dart';
import 'package:k_academy__app/widgets/child_filter_dropdown.dart';
import 'package:k_academy__app/screens/home_screen.dart';
import 'package:k_academy__app/widgets/expense_input_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final selectedChild = context.watch<ChildFilterProvider>().selectedChild;

    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 관리'),
        centerTitle: false,
        flexibleSpace: const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: kToolbarHeight,
            child: Center(child: ChildFilterDropdown()),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 맛보기 모드: 체험 카운트 배지
          if (auth.isTrialMode)
            Consumer<ExpenseProvider>(
              builder: (context, expense, _) {
                final count = expense.totalExpenseCount;
                final isFull = count >= ExpenseProvider.trialLimit;
                return Padding(
                  padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                  child: Chip(
                    label: Text(
                      '체험 $count/${ExpenseProvider.trialLimit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFull ? Colors.white : Colors.orange[800],
                      ),
                    ),
                    backgroundColor: isFull
                        ? Colors.red
                        : Colors.orange.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
          // 로그인 모드: 점 세개 메뉴
          if (!auth.isTrialMode)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'logout') signOutAndRestart(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
              ],
            ),
        ],
      ),
      body: Consumer2<ExpenseProvider, DropdownProvider>(
        builder: (context, expenseProvider, dropdownProv, child) {
          final childOrder = dropdownProv.childNames;
          return Stack(
            children: [
              Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      context
                          .read<SelectedDateProvider>()
                          .selectDate(selectedDay);
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _selectedDay = null;
                      });
                    },
                    eventLoader: (day) {
                      final all = expenseProvider.getExpensesForDate(day);
                      if (selectedChild == null) return all;
                      return all
                          .where((e) => e.childName == selectedChild)
                          .toList();
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        final expenses = events.cast<Expense>();
                        final labels = <String>{};
                        for (final expense in expenses) {
                          for (final label in expense.calendarLabels) {
                            String? value;
                            if (label == '학원') value = expense.businessName;
                            if (label == '과목') value = expense.subject;
                            if (label == '강사') value = expense.instructor;
                            if (value != null && value.isNotEmpty) {
                              labels.add(value);
                            }
                          }
                        }
                        if (labels.isEmpty) return null;
                        final labelList = labels.toList();
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...labelList.take(2).map((name) => Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                if (labelList.length > 2)
                                  Text(
                                    '+${labelList.length - 2}개',
                                    style: const TextStyle(
                                        fontSize: 8, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    onHeaderTapped: (_) {
                      setState(() {
                        _selectedDay = null;
                      });
                    },
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextFormatter: (date, locale) =>
                          '${date.year}년 ${date.month}월',
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      todayDecoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildExpenseList(expenseProvider, selectedChild, childOrder)),
                ],
              ),


            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () => _onAddPressed(context),
        tooltip: '지출 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// + 버튼 클릭: 맛보기 한도 초과 시 업그레이드 안내
  void _onAddPressed(BuildContext context) {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    if (!expenseProvider.canAddMore) {
      _showUpgradeDialog(context);
      return;
    }

    _showExpenseInputDialog(context);
  }

  /// 맛보기 한도 초과 안내 다이얼로그
  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('체험 한도 도달'),
          ],
        ),
        content: const Text(
          '맛보기 모드에서는 최대 10개까지 입력 가능합니다.\n\n'
          'Google 로그인으로 전환하면 무제한으로 입력하고 클라우드에 안전하게 저장할 수 있습니다.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('닫기'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Google 로그인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (!context.mounted) return;
              final auth =
                  Provider.of<AuthProvider>(context, listen: false);
              await auth.signInWithGoogle();
              // 로그인 성공 시 ProxyProvider가 자동으로 모드 전환
            },
          ),
        ],
      ),
    );
  }

  void _showExpenseInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ExpenseInputDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
      ),
    );
  }

  Widget _buildExpenseList(ExpenseProvider expenseProvider, String? selectedChild, List<String> childOrder) {
    List<Expense> expenses;
    String emptyMessage;

    if (_selectedDay != null) {
      // 특정 날짜 선택 시: 해당 날짜의 지출만 표시
      expenses = expenseProvider.getExpensesForDate(_selectedDay!);
      emptyMessage = '이 날짜에 지출 내역이 없습니다';
    } else {
      // 월 변경 시 (날짜 미선택): 해당 월 전체 지출 표시
      expenses = expenseProvider.getAllExpenses().where((e) =>
          e.paymentDate.year == _focusedDay.year &&
          e.paymentDate.month == _focusedDay.month).toList();
      expenses.sort((a, b) => a.paymentDate.compareTo(b.paymentDate));
      emptyMessage = '이 달에 지출 내역이 없습니다';
    }

    if (selectedChild != null) {
      expenses = expenses.where((e) => e.childName == selectedChild).toList();
    }

    // 자녀 드롭다운 순서로 정렬 (같은 날짜 내에서)
    if (selectedChild == null && childOrder.isNotEmpty) {
      expenses.sort((a, b) {
        final dateCmp = a.paymentDate.compareTo(b.paymentDate);
        if (dateCmp != 0) return dateCmp;
        final ia = childOrder.indexOf(a.childName);
        final ib = childOrder.indexOf(b.childName);
        return (ia == -1 ? 999 : ia).compareTo(ib == -1 ? 999 : ib);
      });
    }

    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 13, color: Colors.black),
            ),
            if (_selectedDay != null) ...[
              const SizedBox(height: 8),
              const Text(
                '이달의 지출 내역을 보려면 캘린더의 월을 클릭하세요',
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
            ],
          ],
        ),
      );
    }

    final itemCount = expenses.length + (_selectedDay != null ? 1 : 0);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == expenses.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              '이달의 지출 내역을 보려면 캘린더의 월을 클릭하세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black),
            ),
          );
        }
        final expense = expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => _showExpenseOptionsDialog(context, expense),
            title: Text(
              '${expense.childName} - ${expense.subject}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 월 전체 보기일 때 날짜 표시
                if (_selectedDay == null)
                  Text(
                    '${expense.paymentDate.month}/${expense.paymentDate.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                Text('강사: ${expense.instructor}'),
                Text('상호: ${expense.businessName}'),
                Text('세부내역: ${expense.detail}'),
                Text(
                  '금액: ${_formatNumber(expense.amount)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7BA4D4),
                  ),
                ),
                if (expense.cancellationAmount > 0)
                  Text(
                    '취소금액: ${_formatNumber(expense.cancellationAmount)}원',
                    style: const TextStyle(color: Color(0xFFD48A8A)),
                  ),
                if (expense.isRefunded)
                  const Text(
                    '환불됨',
                    style: TextStyle(
                        color: Color(0xFFD4922A), fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            trailing: Text(
              expense.classType,
              style: TextStyle(
                color:
                    expense.classType == '현강' ? const Color(0xFF8DC6A0) : const Color(0xFFB49ACC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  void _showExpenseOptionsDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('지출 내역 관리'),
        content: const Text('작업을 선택하세요'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) await _deleteExpense(context, expense);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  if (context.mounted) _showEditExpenseDialog(context, expense);
                },
                child: const Text('수정'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (_) => ExpenseInputDialog(
        selectedDate: expense.paymentDate,
        existingExpense: expense,
      ),
    );
  }

  Future<void> _deleteExpense(BuildContext context, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 지출 내역을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      await expenseProvider.deleteExpense(expense.id);
      await expenseProvider.loadExpenses();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지출 내역이 삭제되었습니다')),
        );
      }
    }
  }
}
