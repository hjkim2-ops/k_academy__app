import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/widgets/expense_input_dialog.dart';
import 'package:k_academy__app/services/export_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 관리'),
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
            )
          // 로그인 모드: 사용자 이메일 + 클라우드 아이콘
          else if (auth.user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_done, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    auth.user!.email?.split('@').first ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
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
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: (day) =>
                        expenseProvider.getExpensesForDate(day),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return null;
                        final expenses = events.cast<Expense>();
                        final instructors = expenses
                            .map((e) => e.instructor)
                            .where((name) => name.isNotEmpty)
                            .toSet()
                            .toList();
                        if (instructors.isEmpty) return null;
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...instructors.take(2).map((name) => Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                                if (instructors.length > 2)
                                  Text(
                                    '+${instructors.length - 2}개',
                                    style: const TextStyle(
                                        fontSize: 8, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
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
                  Expanded(child: _buildExpenseList(expenseProvider)),
                ],
              ),
              // Excel 내보내기 버튼
              Positioned(
                left: 16,
                bottom: 16,
                child: ElevatedButton(
                  onPressed: () {
                    final expenses = expenseProvider.getAllExpenses();
                    ExportService.exportToExcel(expenses);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Excel',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  borderRadius: BorderRadius.circular(8)),
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

  Widget _buildExpenseList(ExpenseProvider expenseProvider) {
    if (_selectedDay == null) {
      return const Center(child: Text('날짜를 선택해주세요'));
    }

    final expenses = expenseProvider.getExpensesForDate(_selectedDay!);

    if (expenses.isEmpty) {
      return const Center(child: Text('이 날짜에 지출 내역이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => _showExpenseOptionsDialog(context, expense),
            title: Text(
              '${expense.childName} - ${expense.subject}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('강사: ${expense.instructor}'),
                Text('상호: ${expense.businessName}'),
                Text('세부내역: ${expense.detail}'),
                Text(
                  '금액: ${_formatNumber(expense.amount)}원',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (expense.cancellationAmount > 0)
                  Text(
                    '취소금액: ${_formatNumber(expense.cancellationAmount)}원',
                    style: const TextStyle(color: Colors.red),
                  ),
                if (expense.isRefunded)
                  const Text(
                    '환불됨',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            trailing: Text(
              expense.classType,
              style: TextStyle(
                color:
                    expense.classType == '현강' ? Colors.green : Colors.purple,
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) _showEditExpenseDialog(context, expense);
            },
            child: const Text('수정'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (context.mounted) await _deleteExpense(context, expense);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
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
