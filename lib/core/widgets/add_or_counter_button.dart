import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../presentation/providers/cart_provider.dart';

/// Unified Add → −/qty/+ counter button used across all product & combo cards.
///
/// When the item is not in cart  →  shows "Add [label]" button.
/// When the item is in cart      →  shows  −  qty  +  stepper.
/// When [disabled] is true       →  shows greyed-out "Out of Stock" (products only).
///
/// [cartId]   — the unique cart key (e.g. 'product_p1_v1' or 'combo_c1').
/// [onAdd]    — called both on initial add AND on the + tap; must handle
///              cart mutation + snackbar internally (weight-check aware).
class AddOrCounterButton extends ConsumerWidget {
  const AddOrCounterButton({
    super.key,
    required this.cartId,
    required this.onAdd,
    this.label = 'Add',
    this.addIcon = Icons.add_shopping_cart_rounded,
    this.height = 34.0,
    this.activeColor = AppColors.primaryBrown,
    this.backgroundColor = const Color(0xFFF5E6CC),
    this.disabled = false,
  });

  final String cartId;
  final VoidCallback onAdd;
  final String label;
  final IconData addIcon;
  final double height;

  /// Foreground colour — icon + text (and counter digits).
  final Color activeColor;

  /// Background colour of the button / counter container.
  final Color backgroundColor;

  /// When true the button is shown in a "Out of Stock" state and is not tappable.
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild when this item's quantity changes — fine-grained reactivity.
    final qty = ref.watch(
      cartProvider.select((c) => c.quantityOf(cartId)),
    );

    // ── Out of Stock ──────────────────────────────────────────────────────────
    if (disabled) {
      return _shell(
        color: AppColors.border,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_rounded,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              'Out of Stock',
              style: AppTextStyles.labelL.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // ── Counter ───────────────────────────────────────────────────────────────
    if (qty > 0) {
      return _shell(
        color: backgroundColor,
        child: Row(
          children: [
            // — button
            _CounterTap(
              onTap: () => ref
                  .read(cartProvider.notifier)
                  .updateQuantity(cartId, qty - 1),
              size: height,
              isLeft: true,
              child: Icon(Icons.remove_rounded, size: 15, color: activeColor),
            ),

            // qty label
            Expanded(
              child: Center(
                child: Text(
                  '$qty',
                  style: AppTextStyles.labelL.copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // + button
            _CounterTap(
              onTap: onAdd,
              size: height,
              isLeft: false,
              child: Icon(Icons.add_rounded, size: 15, color: activeColor),
            ),
          ],
        ),
      );
    }

    // ── Add button ────────────────────────────────────────────────────────────
    return GestureDetector(
      onTap: onAdd,
      child: _shell(
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(addIcon, size: 14, color: activeColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelL.copyWith(
                color: activeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shell({required Color color, required Widget child}) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      );
}

/// Tap target for the − / + sides of the counter.
class _CounterTap extends StatelessWidget {
  const _CounterTap({
    required this.onTap,
    required this.size,
    required this.isLeft,
    required this.child,
  });

  final VoidCallback onTap;
  final double size;
  final bool isLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(8) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(8),
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
