import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/firebase_options.dart';
import 'package:k_academy__app/services/storage_service.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase 초기화 실패 (맛보기 모드로 실행): $e');
  }

  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider()..loadExpenses(),
          update: (_, auth, expense) {
            expense!.onAuthChanged(auth.isTrialMode, auth.user?.uid);
            return expense;
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ScheduleProvider>(
          create: (_) => ScheduleProvider()..loadSchedules(),
          update: (_, auth, schedule) {
            schedule!.onAuthChanged(auth.isTrialMode, auth.user?.uid);
            return schedule;
          },
        ),

        ChangeNotifierProvider(
          create: (_) => DropdownProvider()..loadAllDropdownData(),
        ),
      ],
      child: MaterialApp(
        title: 'K-학원',
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
