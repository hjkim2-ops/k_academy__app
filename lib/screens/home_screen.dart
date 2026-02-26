import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/screens/calendar_screen.dart';
import 'package:k_academy__app/screens/expense_stats_screen.dart';
import 'package:k_academy__app/screens/schedule_screen.dart';
import 'package:k_academy__app/screens/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = [
    CalendarScreen(),
    ExpenseStatsScreen(),
    ScheduleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '지출관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '지출통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: '시간표',
          ),
        ],
      ),
    );
  }
}

/// 로그아웃 후 시작 화면으로 이동하는 헬퍼
Future<void> signOutAndRestart(BuildContext context) async {
  await context.read<AuthProvider>().signOut();
  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (_) => false,
    );
  }
}
