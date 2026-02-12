import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('K학원 지출 관리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
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
                eventLoader: (day) {
                  return expenseProvider.getExpensesForDate(day);
                },
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
                            // Show first 2 instructors
                            ...instructors.take(2).map((instructor) {
                              return Text(
                                instructor,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                            // Show "+N개" if more than 2
                            if (instructors.length > 2)
                              Text(
                                '+${instructors.length - 2}개',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
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
              Expanded(
                child: _buildExpenseList(expenseProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseInputDialog(context),
        tooltip: '지출 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseList(ExpenseProvider expenseProvider) {
    if (_selectedDay == null) {
      return const Center(
        child: Text('날짜를 선택해주세요'),
      );
    }

    final expenses = expenseProvider.getExpensesForDate(_selectedDay!);

    if (expenses.isEmpty) {
      return const Center(
        child: Text('이 날짜에 지출 내역이 없습니다'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            trailing: Text(
              expense.classType,
              style: TextStyle(
                color: expense.classType == '현강' ? Colors.green : Colors.purple,
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

  void _showExpenseInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExpenseInputDialog(
        selectedDate: _selectedDay ?? DateTime.now(),
      ),
    );
  }
}
