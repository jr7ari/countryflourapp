import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: CustomScrollView(
        slivers: [
          // 🔹 Profile Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      // ✅ Avatar — Google photo when logged in, CF logo for guest
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withAlpha(80),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: auth.isLoggedIn
                              ? (auth.photoUrl != null
                                  ? Image.network(
                                      auth.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _InitialAvatar(name: auth.name),
                                    )
                                  : _InitialAvatar(name: auth.name))
                              : Image.asset(
                                  'assets/images/cf.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _InitialAvatar(name: null),
                                ),
                        ),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 12),

                      Text(
                        auth.isLoggedIn ? (auth.name ?? 'User') : 'Guest User',
                        style: AppTextStyles.headingL.copyWith(color: Colors.white),
                      ).animate().fadeIn(delay: 200.ms),

                      if (auth.isLoggedIn && auth.phone != null)
                        Text(
                          '+91 ${auth.phone}',
                          style: AppTextStyles.bodyM.copyWith(
                            color: Colors.white.withAlpha(180),
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                      if (!auth.isLoggedIn) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.login),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text('Login / Sign Up'),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔹 Stats Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Orders',
                      value: ref.watch(ordersProvider).when(
                            data: (o) => '${o.length}',
                            loading: () => '—',
                            error: (_, __) => '—',
                          ),
                      icon: Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Addresses',
                      value: ref.watch(addressesProvider).when(
                            data: (a) => '${a.length}',
                            loading: () => '—',
                            error: (_, __) => '—',
                          ),
                      icon: Icons.location_on_rounded,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),

          // 🔹 Menu Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account
                  Text('Account',
                      style: AppTextStyles.headingM.copyWith(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),

                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.location_on_rounded,
                      label: 'My Addresses',
                      onTap: () => context.push(AppRoutes.addresses),
                    ),
                    _MenuItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Order History',
                      onTap: () => context.go(AppRoutes.orders),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Preferences (Language removed)
                  Text('Preferences',
                      style: AppTextStyles.headingM.copyWith(
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),

                  _MenuGroup(items: [
                    _MenuItem(
                      icon: Icons.notifications_rounded,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                  ]),

                  // Logout
                  if (auth.isLoggedIn) ...[
                    const SizedBox(height: 16),
                    _MenuGroup(items: [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        iconColor: AppColors.error,
                        labelColor: AppColors.error,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Logout?'),
                              content: const Text(
                                  'Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(authProvider.notifier).logout();
                                    Navigator.of(dialogCtx).pop();
                                    SchedulerBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (context.mounted) {
                                        context.go(AppRoutes.login);
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]),
                  ],

                  const SizedBox(height: 40),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 Stat Card
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryGold),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headingL),
          Text(label, style: AppTextStyles.labelM),
        ],
      ),
    );
  }
}

// 🔹 Menu Group
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon,
                          size: 20,
                          color:
                          item.iconColor ?? AppColors.textPrimary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: AppTextStyles.bodyM
                              .copyWith(color: item.labelColor),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// 🔹 Initial Avatar (fallback when no photo URL)
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBrown,
      child: Center(
        child: Text(
          name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?',
          style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// 🔹 Menu Item Model
class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });
}