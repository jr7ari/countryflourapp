import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

enum BadgeType {
  bestseller,
  featured,
  combo,
  bestValue,
  newProduct,
  outOfStock,
  discount,
  organic,
}

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.type,
    this.label,
    this.small = false,
  });

  final BadgeType type;
  final String? label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig();
    final fontSize = small ? 9.0 : 10.0;
    final hPad = small ? 6.0 : 8.0;
    final vPad = small ? 3.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(100),
        gradient: config.gradient,
        boxShadow: [
          BoxShadow(
            color: config.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(config.icon, size: small ? 9 : 10, color: config.textColor),
            SizedBox(width: small ? 2 : 3),
          ],
          Text(
            label ?? config.label,
            style: AppTextStyles.badge.copyWith(
              color: config.textColor,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _badgeConfig() {
    switch (type) {
      case BadgeType.bestseller:
        return _BadgeConfig(
          backgroundColor: AppColors.primaryGold,
          textColor: Colors.white,
          label: 'BESTSELLER',
          icon: Icons.star_rounded,
          shadowColor: AppColors.primaryGold.withAlpha(80),
        );
      case BadgeType.featured:
        return _BadgeConfig(
          backgroundColor: AppColors.primaryBrown,
          textColor: Colors.white,
          label: 'FEATURED',
          icon: Icons.workspace_premium_rounded,
          shadowColor: AppColors.primaryBrown.withAlpha(80),
        );
      case BadgeType.combo:
        return _BadgeConfig(
          gradient: AppColors.comboGradient,
          textColor: Colors.white,
          label: 'COMBO',
          icon: Icons.inventory_2_rounded,
          shadowColor: AppColors.comboPrimary.withAlpha(80),
        );
      case BadgeType.bestValue:
        return _BadgeConfig(
          gradient: AppColors.comboGradient,
          textColor: Colors.white,
          label: 'BEST VALUE',
          icon: Icons.local_offer_rounded,
          shadowColor: AppColors.comboPrimary.withAlpha(80),
        );
      case BadgeType.newProduct:
        return _BadgeConfig(
          backgroundColor: AppColors.accentGreen,
          textColor: Colors.white,
          label: 'NEW',
          icon: Icons.new_releases_rounded,
          shadowColor: AppColors.accentGreen.withAlpha(80),
        );
      case BadgeType.outOfStock:
        return _BadgeConfig(
          backgroundColor: const Color(0xFFE0E0E0),
          textColor: const Color(0xFF757575),
          label: 'OUT OF STOCK',
          shadowColor: Colors.black.withAlpha(20),
        );
      case BadgeType.discount:
        return _BadgeConfig(
          backgroundColor: AppColors.error,
          textColor: Colors.white,
          label: label ?? 'SALE',
          icon: Icons.percent_rounded,
          shadowColor: AppColors.error.withAlpha(80),
        );
      case BadgeType.organic:
        return _BadgeConfig(
          backgroundColor: AppColors.accentGreen,
          textColor: Colors.white,
          label: 'ORGANIC',
          icon: Icons.eco_rounded,
          shadowColor: AppColors.accentGreen.withAlpha(80),
        );
    }
  }
}

class _BadgeConfig {
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final Color textColor;
  final String label;
  final IconData? icon;
  final Color shadowColor;

  _BadgeConfig({
    this.backgroundColor,
    this.gradient,
    required this.textColor,
    required this.label,
    this.icon,
    required this.shadowColor,
  });
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.small = false});
  final double percent;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      type: BadgeType.discount,
      label: '${percent.toStringAsFixed(0)}% OFF',
      small: small,
    );
  }
}
