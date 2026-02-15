import 'package:hive_flutter/hive_flutter.dart';
import 'package:k_academy__app/models/expense.dart';
import 'package:k_academy__app/utils/constants.dart';

class StorageService {
  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExpenseAdapter());

    // Open boxes
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox<String>(childrenBoxName);
    await Hive.openBox<String>(businessNamesBoxName);
    await Hive.openBox<String>(instructorsBoxName);
    await Hive.openBox<String>(customSubjectsBoxName);
    await Hive.openBox<String>(customDetailsBoxName);
    await Hive.openBox<String>(cardNamesBoxName);
    await Hive.openBox<String>(customPaymentMethodsBoxName);
  }

  static Box<Expense> get expenseBox => Hive.box<Expense>(expenseBoxName);
  static Box<String> get childrenBox => Hive.box<String>(childrenBoxName);
  static Box<String> get businessNamesBox =>
      Hive.box<String>(businessNamesBoxName);
  static Box<String> get instructorsBox => Hive.box<String>(instructorsBoxName);
  static Box<String> get customSubjectsBox =>
      Hive.box<String>(customSubjectsBoxName);
  static Box<String> get customDetailsBox =>
      Hive.box<String>(customDetailsBoxName);
  static Box<String> get cardNamesBox => Hive.box<String>(cardNamesBoxName);
  static Box<String> get customPaymentMethodsBox =>
      Hive.box<String>(customPaymentMethodsBoxName);
}
