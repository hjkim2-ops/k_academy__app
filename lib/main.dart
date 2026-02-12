import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/services/storage_service.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await StorageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ExpenseProvider()..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => DropdownProvider()..loadAllDropdownData(),
        ),
      ],
      child: MaterialApp(
        title: 'K학원 지출 관리',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
