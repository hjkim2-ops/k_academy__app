import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/services/storage_service.dart';

class ExpenseService {
  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    final box = StorageService.expenseBox;
    await box.put(expense.id, expense);
  }

  // Update an existing expense
  Future<void> updateExpense(Expense expense) async {
    final box = StorageService.expenseBox;
    await box.put(expense.id, expense);
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    final box = StorageService.expenseBox;
    await box.delete(id);
  }

  // Get all expenses
  List<Expense> getAllExpenses() {
    final box = StorageService.expenseBox;
    return box.values.toList();
  }

  // Get expenses for a specific date
  List<Expense> getExpensesByDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final allExpenses = getAllExpenses();

    return allExpenses
        .where((expense) =>
            expense.dateKey.year == normalizedDate.year &&
            expense.dateKey.month == normalizedDate.month &&
            expense.dateKey.day == normalizedDate.day)
        .toList();
  }

  // Get expenses for a specific month
  List<Expense> getExpensesByMonth(DateTime month) {
    final allExpenses = getAllExpenses();

    return allExpenses
        .where((expense) =>
            expense.dateKey.year == month.year &&
            expense.dateKey.month == month.month)
        .toList();
  }
}
