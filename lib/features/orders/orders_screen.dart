import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/analytics_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/order_model.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/navigation/app_router.dart';
import 'widgets/order_timeline.dart';

// ── Filter definition ─────────────────────────────────────────────────────────

class _FilterOption {
  final String? status; // null = All
  final String label;
  final IconData icon;
  final Color color;

  const _FilterOption({
    required this.status,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const _kFilters = [
  _FilterOption(status: null,               label: 'All',              icon: Icons.receipt_long_rounded,    color: AppColors.primaryBrown),
  _FilterOption(status: 'pending',          label: 'Order Placed',     icon: Icons.radio_button_checked,    color: AppColors.primaryGold),
  _FilterOption(status: 'confirmed',        label: 'Confirmed',        icon: Icons.verified_rounded,         color: AppColors.primaryGold),
  _FilterOption(status: 'processing',       label: 'Processing',       icon: Icons.autorenew_rounded,        color: AppColors.primaryGold),
  _FilterOption(status: 'shipped',          label: 'Shipped',          icon: Icons.local_shipping_rounded,   color: AppColors.info),
  _FilterOption(status: 'out_for_delivery', label: 'Out for Delivery', icon: Icons.delivery_dining_rounded,  color: AppColors.info),
  _FilterOption(status: 'delivered',        label: 'Delivered',        icon: Icons.check_circle_rounded,     color: AppColors.accentGreen),
  _FilterOption(status: 'cancelled',        label: 'Cancelled',        icon: Icons.cancel_rounded,           color: AppColors.error),
];

// ── Orders Screen ─────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedStatus; // null = show all

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(ordersProvider);

    // ── Login wall for guests ──────────────────────────────────────────────
    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
          title: Text('My Orders', style: AppTextStyles.headingXL),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5E6CC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      size: 44, color: AppColors.primaryBrown),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text('Login to view orders', style: AppTextStyles.headingL)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Sign in to see your order history\nand track deliveries.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 28),
                SizedBox(
                  width: 180,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBrown,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Login / Sign Up',
                        style: AppTextStyles.buttonM.copyWith(color: Colors.white)),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        title: Text('My Orders', style: AppTextStyles.headingXL),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(
            selected: _selectedStatus,
            onSelected: (status) => setState(() => _selectedStatus = status),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryBrown,
        onRefresh: () async {
          ref.invalidate(ordersProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ordersAsync.when(
          data: (orders) {
            if (orders.isEmpty) return const _EmptyOrders();

            final filtered = _selectedStatus == null
                ? orders
                : orders
                    .where((o) =>
                        o.orderStatus.toLowerCase() == _selectedStatus)
                    .toList();

            if (filtered.isEmpty) {
              return _EmptyFiltered(
                label: _kFilters
                    .firstWhere((f) => f.status == _selectedStatus)
                    .label,
                onClear: () => setState(() => _selectedStatus = null),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _OrderCard(order: filtered[i], index: i),
            );
          },
          loading: () => ListView.builder(
            itemCount: 3,
            itemBuilder: (_, __) => const ListTileShimmer(),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _kFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _kFilters[i];
          final isActive = f.status == selected;
          return GestureDetector(
            onTap: () => onSelected(f.status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? f.color : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? f.color : AppColors.border,
                  width: isActive ? 1.5 : 0.8,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: f.color.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: 14,
                    color: isActive ? Colors.white : f.color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f.label,
                    style: AppTextStyles.labelM.copyWith(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty filtered state ──────────────────────────────────────────────────────

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered({required this.label, required this.onClear});
  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF5E6CC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_list_off_rounded,
                  size: 42, color: AppColors.primaryBrown),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text('No "$label" orders',
                    style: AppTextStyles.headingL, textAlign: TextAlign.center)
                .animate()
                .fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any orders with\nthis status yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM
                  .copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Clear filter'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBrown),
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order, required this.index});
  final Order order;
  final int index;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isCancelling = false;

  Order get order => widget.order;
  int get index => widget.index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: _statusBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 16, color: _statusColor),
                const SizedBox(width: 8),
                Text(
                  Formatters.orderStatus(order.orderStatus),
                  style: AppTextStyles.headingS.copyWith(color: _statusColor),
                ),
                const Spacer(),
                Text(
                  '#${order.orderId}',
                  style: AppTextStyles.labelM.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              children: [
                ...order.items.take(2).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (item.isCombo)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.comboGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('COMBO',
                                style: AppTextStyles.badge
                                    .copyWith(color: Colors.white, fontSize: 8)),
                          ),
                        Expanded(
                          child: Text(
                            item.productName,
                            style: AppTextStyles.bodyM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('×${item.quantity}', style: AppTextStyles.labelL),
                      ],
                    ),
                  ),
                ),
                if (order.items.length > 2)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+${order.items.length - 2} more items',
                      style: AppTextStyles.bodyS,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Divider(height: 1),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Formatters.currency(order.totalAmount), style: AppTextStyles.priceM),
                    Text(Formatters.date(order.createdAt), style: AppTextStyles.bodyS),
                  ],
                ),
                const Spacer(),

                // View detail button
                GestureDetector(
                  onTap: () => _showOrderDetail(context, order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6CC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Details',
                      style: AppTextStyles.labelL.copyWith(color: AppColors.primaryBrown),
                    ),
                  ),
                ),

                // Cancel button
                if (order.canCancel) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isCancelling
                        ? null
                        : () => _confirmCancel(context, order),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isCancelling
                              ? AppColors.border
                              : AppColors.error.withAlpha(80),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _isCancelling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : Text(
                              'Cancel',
                              style:
                                  AppTextStyles.labelL.copyWith(color: AppColors.error),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 80).ms)
        .slideY(begin: 0.1, end: 0);
  }

  Color get _statusColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return AppColors.accentGreen;
      case 'cancelled':
        return AppColors.error;
      case 'shipped':
      case 'out_for_delivery':
        return AppColors.info;
      default:
        return AppColors.primaryGold;
    }
  }

  Color get _statusBgColor {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return AppColors.accentGreenLight;
      case 'cancelled':
        return const Color(0xFFFFEDED);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFFFF8ED);
    }
  }

  IconData get _statusIcon {
    switch (order.orderStatus.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'shipped':
      case 'out_for_delivery':
        return Icons.local_shipping_rounded;
      case 'confirmed':
        return Icons.verified_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Future<void> _showOrderDetail(BuildContext context, Order order) async {
    final didCancel = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(order: order),
    );
    if (didCancel == true && mounted) {
      ref.invalidate(ordersProvider);
    }
  }

  void _confirmCancel(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order #${order.orderId}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _isCancelling = true);
              final success =
                  await ref.read(cancelOrderProvider.notifier).cancel(order.orderId);
              if (!mounted) return;
              setState(() => _isCancelling = false);
              if (success) {
                ref.invalidate(ordersProvider);
                AnalyticsService.logCancelOrder(order.orderId);
              }
              messenger.showSnackBar(SnackBar(
                content: Text(success
                    ? 'Order #${order.orderId} cancelled'
                    : 'Failed to cancel. Please try again.'),
                backgroundColor: success ? AppColors.accentGreen : AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSheet extends ConsumerStatefulWidget {
  const _OrderDetailSheet({required this.order});
  final Order order;

  @override
  ConsumerState<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends ConsumerState<_OrderDetailSheet> {
  bool _isCancelling = false;

  Order get order => widget.order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Order #${order.orderId}', style: AppTextStyles.headingL),
          Text(Formatters.dateTime(order.createdAt), style: AppTextStyles.bodyS),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderTimeline(currentStep: order.statusStep, isCancelled: order.isCancelled),
                  const SizedBox(height: 20),

                  if (order.shippingAddress != null) ...[
                    Text('Delivery Address', style: AppTextStyles.headingM),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primaryGold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.shippingAddress!.fullAddress,
                              style: AppTextStyles.bodyS,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Text('Items', style: AppTextStyles.headingM),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          if (item.isCombo)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                gradient: AppColors.comboGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('COMBO',
                                  style: AppTextStyles.badge
                                      .copyWith(color: Colors.white, fontSize: 8)),
                            ),
                          Expanded(child: Text(item.productName, style: AppTextStyles.bodyM)),
                          Text('×${item.quantity}', style: AppTextStyles.labelL),
                          const SizedBox(width: 8),
                          Text(Formatters.currency(item.price * item.quantity),
                              style: AppTextStyles.priceS),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _PriceRow('Subtotal', Formatters.currency(order.subtotal)),
                        _PriceRow('Delivery', Formatters.currency(order.shippingCharges)),
                        const Divider(height: 16),
                        _PriceRow('Total', Formatters.currency(order.totalAmount), bold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Cancel button — pinned at bottom, only when cancellable
          if (order.canCancel)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isCancelling ? null : _confirmCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isCancelling
                            ? AppColors.border
                            : AppColors.error.withAlpha(160),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.error),
                          )
                        : const Icon(Icons.cancel_outlined,
                            color: AppColors.error, size: 18),
                    label: Text(
                      _isCancelling ? 'Cancelling…' : 'Cancel Order',
                      style: AppTextStyles.buttonM.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order?'),
        content: Text(
          'Are you sure you want to cancel order #${order.orderId}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _isCancelling = true);
              final success = await ref
                  .read(cancelOrderProvider.notifier)
                  .cancel(order.orderId);
              if (!mounted) return;
              if (success) {
                AnalyticsService.logCancelOrder(order.orderId);
                // Pop sheet with true — parent will refresh the orders list
                Navigator.of(context).pop(true);
                return;
              }
              setState(() => _isCancelling = false);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Failed to cancel. Please try again.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppTextStyles.headingM : AppTextStyles.bodyM;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFF5E6CC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.primaryBrown),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          Text('No orders yet', style: AppTextStyles.headingL).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
