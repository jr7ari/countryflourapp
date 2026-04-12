import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/notification_model.dart';
import '../../presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications', style: AppTextStyles.headingXL),
            if (unread > 0)
              Text(
                '$unread unread',
                style: AppTextStyles.labelS.copyWith(
                  color: AppColors.primaryGold,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
        actions: [
          if (notifications.isNotEmpty) ...[
            if (unread > 0)
              TextButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).markAllRead(),
                child: Text(
                  'Mark all read',
                  style: AppTextStyles.labelM.copyWith(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'clear') {
                  _confirmClear(context, ref);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 10),
                      Text('Clear all',
                          style: AppTextStyles.bodyM
                              .copyWith(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: notifications.isEmpty
          ? const _EmptyState()
          : _NotificationList(notifications: notifications),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear all notifications?'),
        content: const Text('This will permanently remove all notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear all',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Grouped list ────────────────────────────────────────────────────────────

class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.notifications});
  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by date bucket: Today / Yesterday / Earlier
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final today = notifications
        .where((n) => n.receivedAt.isAfter(todayStart))
        .toList();
    final yesterday = notifications
        .where((n) =>
            n.receivedAt.isAfter(yesterdayStart) &&
            !n.receivedAt.isAfter(todayStart))
        .toList();
    final earlier = notifications
        .where((n) => !n.receivedAt.isAfter(yesterdayStart))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        if (today.isNotEmpty) ...[
          _GroupHeader(label: 'Today'),
          ...today.asMap().entries.map(
                (e) => _NotificationCard(
                    notification: e.value, index: e.key),
              ),
        ],
        if (yesterday.isNotEmpty) ...[
          _GroupHeader(label: 'Yesterday'),
          ...yesterday.asMap().entries.map(
                (e) => _NotificationCard(
                    notification: e.value, index: e.key),
              ),
        ],
        if (earlier.isNotEmpty) ...[
          _GroupHeader(label: 'Earlier'),
          ...earlier.asMap().entries.map(
                (e) => _NotificationCard(
                    notification: e.value, index: e.key),
              ),
        ],
      ],
    );
  }
}

// ─── Group header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelS.copyWith(
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotificationCard extends ConsumerStatefulWidget {
  const _NotificationCard(
      {required this.notification, required this.index});
  final AppNotification notification;
  final int index;

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _dismissed = false;

  AppNotification get n => widget.notification;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _dismissed = true);
        ref.read(notificationsProvider.notifier).delete(n.id);
      },
      background: _SwipeDeleteBackground(),
      child: GestureDetector(
        onTap: () {
          if (!n.isRead) {
            ref.read(notificationsProvider.notifier).markRead(n.id);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: n.isRead
                ? AppColors.surfaceWhite
                : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.isRead ? AppColors.border : _typeColor.withAlpha(60),
              width: n.isRead ? 0.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: n.isRead
                    ? Colors.black.withAlpha(4)
                    : _typeColor.withAlpha(18),
                blurRadius: n.isRead ? 6 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coloured left accent bar
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: n.isRead
                      ? AppColors.border
                      : _typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Icon badge
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _typeColor.withAlpha(n.isRead ? 20 : 30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _typeIcon,
                    size: 20,
                    color:
                        n.isRead ? _typeColor.withAlpha(140) : _typeColor,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: AppTextStyles.headingS.copyWith(
                                color: n.isRead
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontWeight: n.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Unread dot
                          if (!n.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: _typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: AppTextStyles.bodyS.copyWith(
                          color: n.isRead
                              ? AppColors.textHint
                              : AppColors.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Type chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _typeColor.withAlpha(18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _typeLabel,
                              style: AppTextStyles.labelS.copyWith(
                                color: _typeColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(n.receivedAt),
                            style: AppTextStyles.labelS.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (widget.index * 50).ms, duration: 300.ms)
          .slideX(begin: 0.04, end: 0, curve: Curves.easeOut),
    );
  }

  Color get _typeColor {
    switch (n.type) {
      case NotificationType.order:
        return AppColors.primaryBrown;
      case NotificationType.delivery:
        return AppColors.info;
      case NotificationType.promo:
        return AppColors.primaryGold;
      case NotificationType.general:
        return AppColors.accentGreen;
    }
  }

  IconData get _typeIcon {
    switch (n.type) {
      case NotificationType.order:
        return Icons.receipt_long_rounded;
      case NotificationType.delivery:
        return Icons.local_shipping_rounded;
      case NotificationType.promo:
        return Icons.local_offer_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  String get _typeLabel {
    switch (n.type) {
      case NotificationType.order:
        return 'ORDER';
      case NotificationType.delivery:
        return 'DELIVERY';
      case NotificationType.promo:
        return 'OFFER';
      case NotificationType.general:
        return 'INFO';
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(dt);
  }
}

// ─── Swipe-to-delete background ──────────────────────────────────────────────

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withAlpha(40)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(height: 2),
          Text(
            'Delete',
            style: AppTextStyles.labelS.copyWith(color: AppColors.error),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated bell illustration
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryGold.withAlpha(30),
                        AppColors.primaryGold.withAlpha(5),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 52,
                    color: AppColors.primaryGold.withAlpha(180),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.backgroundCream, width: 2),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 10, color: AppColors.textHint),
                  ),
                ),
              ],
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.05,
                    duration: 2000.ms,
                    curve: Curves.easeInOut),

            const SizedBox(height: 28),

            Text(
              'No notifications yet',
              style: AppTextStyles.headingL,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 10),

            Text(
              'We\'ll notify you about order\nupdates, offers, and more.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // Feature hints
            ...[
              (Icons.receipt_long_rounded, 'Order status updates', AppColors.primaryBrown),
              (Icons.local_shipping_rounded, 'Delivery tracking', AppColors.info),
              (Icons.local_offer_rounded, 'Exclusive offers & deals', AppColors.primaryGold),
            ].asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: e.value.$3.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(e.value.$1,
                              size: 16, color: e.value.$3),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.value.$2,
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: (400 + e.key * 80).ms).slideX(begin: 0.05, end: 0),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
