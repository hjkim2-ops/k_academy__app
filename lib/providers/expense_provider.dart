import 'package:flutter/foundation.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/services/expense_service.dart';
import 'package:k_academy__app/services/firestore_expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _hiveService = ExpenseService();
  FirestoreExpenseService? _firestoreService;

  Map<DateTime, List<Expense>> _expensesByDate = {};
  bool _isTrialMode = true;
  String? _userId;

  static const int trialLimit = 10;

  bool get isTrialMode => _isTrialMode;
  Map<DateTime, List<Expense>> get expensesByDate => _expensesByDate;

  /// 전체 저장된 지출 개수
  int get totalExpenseCount =>
      _expensesByDate.values.fold(0, (sum, list) => sum + list.length);

  /// 추가 입력 가능 여부 (맛보기: 10개 미만일 때만 true)
  bool get canAddMore => !_isTrialMode || totalExpenseCount < trialLimit;

  /// 인증 모드 변경 시 호출됨 (main.dart ProxyProvider에서 자동 호출)
  void onAuthChanged(bool isTrialMode, String? userId) {
    final modeChanged = _isTrialMode != isTrialMode || _userId != userId;
    if (!modeChanged) return;

    _isTrialMode = isTrialMode;
    _userId = userId;
    _firestoreService = (!isTrialMode && userId != null)
        ? FirestoreExpenseService(userId: userId)
        : null;

    Future.microtask(() => loadExpenses());
  }

  /// 저장소에서 전체 지출 로드
  Future<void> loadExpenses() async {
    List<Expense> expenses;
    if (_firestoreService != null) {
      expenses = await _firestoreService!.getAllExpenses();
    } else {
      expenses = _hiveService.getAllExpenses();
    }

    _expensesByDate = {};
    for (final expense in expenses) {
      _expensesByDate.putIfAbsent(expense.dateKey, () => []).add(expense);
    }
    notifyListeners();
  }

  /// 특정 날짜의 지출 목록
  List<Expense> getExpensesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _expensesByDate[normalizedDate] ?? [];
  }

  /// 전체 지출 목록 (Excel 내보내기 등 동기 접근용)
  List<Expense> getAllExpenses() {
    return _expensesByDate.values.expand((e) => e).toList();
  }

  /// 지출 추가
  Future<void> addExpense(Expense expense) async {
    if (_firestoreService != null) {
      await _firestoreService!.addExpense(expense);
    } else {
      await _hiveService.addExpense(expense);
    }
    _expensesByDate.putIfAbsent(expense.dateKey, () => []).add(expense);
    notifyListeners();
  }

  /// 지출 수정
  Future<void> updateExpense(Expense expense) async {
    if (_firestoreService != null) {
      await _firestoreService!.updateExpense(expense);
    } else {
      await _hiveService.updateExpense(expense);
    }
    await loadExpenses();
  }

  /// 지출 삭제
  Future<void> deleteExpense(String id) async {
    if (_firestoreService != null) {
      await _firestoreService!.deleteExpense(id);
    } else {
      await _hiveService.deleteExpense(id);
    }
    await loadExpenses();
  }
}
