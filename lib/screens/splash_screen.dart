import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k_academy__app/providers/auth_provider.dart';
import 'package:k_academy__app/screens/home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _startTrial(BuildContext context) {
    context.read<AuthProvider>().startTrialMode();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _startWithGoogle(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();
    if (success && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // 앱 로고
                      Text(
                        'K-학원',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '학원 지출 & 시간표 관리',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          letterSpacing: 0.5,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // 맛보기 버튼
                      _OptionCard(
                        icon: Icons.preview_outlined,
                        title: '둘러보기',
                        subtitle: '데이터 10개까지 무료 체험',
                        color: const Color(0xFFE8B87D),
                        onTap: auth.isLoading ? null : () => _startTrial(context),
                      ),

                      const SizedBox(height: 16),

                      // Google 로그인 버튼
                      _OptionCard(
                        icon: Icons.login_rounded,
                        title: '정식 서비스 이용하기',
                        subtitle: 'Google 로그인 · 클라우드 저장',
                        color: const Color(0xFF7BA4D4),
                        isLoading: auth.isLoading,
                        onTap: auth.isLoading
                            ? null
                            : () => _startWithGoogle(context),
                      ),

                      // 오류 메시지
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      // 하단 안내
                      Text(
                        '둘러보기는 기기에 저장됩니다.\n정식 서비스는 Google 계정에 연동됩니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 아이콘 컨테이너
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: onTap == null
                      ? Colors.grey
                      : color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),

              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: onTap == null ? Colors.grey : color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: onTap == null ? Colors.grey[300] : color,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
