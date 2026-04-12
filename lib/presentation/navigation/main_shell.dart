import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import 'app_router.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartItemCountProvider);
    final location = GoRouterState.of(context).uri.toString();

    int currentIndex = 0;
    if (location.startsWith(AppRoutes.products)) currentIndex = 1;
    if (location.startsWith(AppRoutes.cart)) currentIndex = 2;
    if (location.startsWith(AppRoutes.orders)) currentIndex = 3;
    if (location.startsWith(AppRoutes.profile)) currentIndex = 4;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          context.go(AppRoutes.home);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => context.go(AppRoutes.home),
                )),
                Expanded(child: _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Products',
                  isSelected: currentIndex == 1,
                  onTap: () => context.go(AppRoutes.products),
                )),
                Expanded(child: _NavItemCart(
                  isSelected: currentIndex == 2,
                  cartCount: cartCount,
                  onTap: () => context.go(AppRoutes.cart),
                )),
                Expanded(child: _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  isSelected: currentIndex == 3,
                  onTap: () => context.go(AppRoutes.orders),
                )),
                Expanded(child: _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                  onTap: () => context.go(AppRoutes.profile),
                )),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFFF5E6CC),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? AppColors.primaryBrown : AppColors.textHint,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.labelS.copyWith(
                    color: isSelected ? AppColors.primaryBrown : AppColors.textHint,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemCart extends StatelessWidget {
  const _NavItemCart({
    required this.isSelected,
    required this.cartCount,
    required this.onTap,
  });

  final bool isSelected;
  final int cartCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFF5E6CC),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text(
                cartCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: AppColors.comboPrimary,
                padding: EdgeInsets.all(4),
              ),
              child: Icon(
                Icons.shopping_cart_rounded,
                size: 22,
                color: isSelected ? AppColors.primaryBrown : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cart',
              style: AppTextStyles.labelS.copyWith(
                color: isSelected ? AppColors.primaryBrown : AppColors.textHint,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
