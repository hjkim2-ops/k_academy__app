import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:k_academy__app/models/expense.dart';

/// Firebase Firestore를 사용한 지출 데이터 CRUD 서비스
/// 데이터 경로: users/{userId}/expenses/{expenseId}
class FirestoreExpenseService {
  final String userId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreExpenseService({required this.userId});

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('users').doc(userId).collection('expenses');

  Future<List<Expense>> getAllExpenses() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _collection.doc(expense.id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _collection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }
}
