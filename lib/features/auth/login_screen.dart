import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/analytics_service.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      AnalyticsService.logLogin();
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      final err = e.toString();
      final message = err.contains('cancelled')
          ? 'Sign-in cancelled.'
          : 'Sign-in failed: $err';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background decorative blobs ────────────────────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.75,
              height: size.width * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.25,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBrown.withAlpha(10),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.05),

                  // ── Logo ───────────────────────────────────────────────────
                  Image.asset(
                    'assets/images/cf.png',
                    width: size.width * 0.78,
                    height: size.width * 0.78,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        duration: 700.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  SizedBox(height: size.height * 0.04),

                  // ── Welcome card ───────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBrown.withAlpha(12),
                          blurRadius: 32,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Welcome',
                          style: AppTextStyles.displaySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to order fresh Freshly-Milled\nflours delivered to your door.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Google Sign-In Button ──────────────────────────
                        _GoogleSignInButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          isLoading: _isLoading,
                        ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                        const SizedBox(height: 20),

                        // ── Divider ────────────────────────────────────────
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: AppTextStyles.labelM,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Guest option ───────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.home),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continue as Guest',
                              style: AppTextStyles.buttonM.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.12, end: 0),

                  const SizedBox(height: 32),

                  // ── Trust badges ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(icon: Icons.lock_rounded, label: 'Secure'),
                      _Dot(),
                      _TrustBadge(icon: Icons.verified_rounded, label: 'Verified'),
                      _Dot(),
                      _TrustBadge(icon: Icons.eco_rounded, label: 'Natural'),
                    ],
                  ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  // ── Terms note ─────────────────────────────────────────────
                  Text(
                    'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelS.copyWith(
                      color: AppColors.textHint,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryBrown.withAlpha(200),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Google "G" logo drawn with text (no asset needed)
                        _GoogleGLogo(),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: AppTextStyles.buttonM.copyWith(
                            color: const Color(0xFF3C4043),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw coloured arcs to mimic Google's G
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.round;

    // Blue arc (top-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      -1.05, 1.7, false, paint,
    );

    // Red arc (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      -2.8, 1.75, false, paint,
    );

    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      2.09, 1.1, false, paint,
    );

    // Green arc (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      3.19, 0.7, false, paint,
    );

    // White horizontal bar (right-hand notch of the G)
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.78, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.accentGreen),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelS.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.textHint,
        ),
      ),
    );
  }
}
