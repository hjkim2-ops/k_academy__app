import 'package:flutter/foundation.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  // Map of date -> list of expenses
  Map<DateTime, List<Expense>> _expensesByDate = {};

  Map<DateTime, List<Expense>> get expensesByDate => _expensesByDate;

  // Load all expenses from storage
  Future<void> loadExpenses() async {
    final expenses = _expenseService.getAllExpenses();
    _expensesByDate = {};

    for (var expense in expenses) {
      final dateKey = expense.dateKey;
      if (_expensesByDate.containsKey(dateKey)) {
        _expensesByDate[dateKey]!.add(expense);
      } else {
        _expensesByDate[dateKey] = [expense];
      }
    }

    notifyListeners();
  }

  // Get expenses for a specific date
  List<Expense> getExpensesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _expensesByDate[normalizedDate] ?? [];
  }

  // Get all expenses
  List<Expense> getAllExpenses() {
    return _expenseService.getAllExpenses();
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    await _expenseService.addExpense(expense);

    final dateKey = expense.dateKey;
    if (_expensesByDate.containsKey(dateKey)) {
      _expensesByDate[dateKey]!.add(expense);
    } else {
      _expensesByDate[dateKey] = [expense];
    }

    notifyListeners();
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    await _expenseService.updateExpense(expense);
    await loadExpenses(); // Reload to ensure consistency
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    await _expenseService.deleteExpense(id);
    await loadExpenses(); // Reload to ensure consistency
  }
}
