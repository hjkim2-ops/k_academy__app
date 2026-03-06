import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/firebase_options.dart';
import 'package:k_academy__app/services/storage_service.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/providers/child_filter_provider.dart';
import 'package:k_academy__app/providers/expense_provider.dart';
import 'package:k_academy__app/providers/schedule_provider.dart';
import 'package:k_academy__app/providers/dropdown_provider.dart';
import 'package:k_academy__app/providers/selected_date_provider.dart';
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

        ChangeNotifierProxyProvider<AuthProvider, DropdownProvider>(
          create: (_) => DropdownProvider()..loadAllDropdownData(),
          update: (_, auth, dropdown) {
            dropdown!.onAuthChanged(auth.isTrialMode, auth.user?.uid);
            return dropdown;
          },
        ),

        ChangeNotifierProvider(create: (_) => ChildFilterProvider()),
        ChangeNotifierProvider(create: (_) => SelectedDateProvider()),
      ],
      child: MaterialApp(
        title: 'K-학원',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7BA4D4),
            surface: const Color(0xFFF5F7FA),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          useMaterial3: true,
          textTheme: ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF4A4A4A),
            displayColor: const Color(0xFF4A4A4A),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.08),
          ),
          appBarTheme: const AppBarTheme(
            foregroundColor: Color(0xFF4A4A4A),
            shape: RoundedRectangleBorder(),
          ),
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          tooltipTheme: const TooltipThemeData(
            height: 0,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(color: Colors.transparent),
            textStyle: TextStyle(fontSize: 0, color: Colors.transparent),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
        ],
        locale: const Locale('ko'),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
