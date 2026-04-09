import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({
    super.key,
    required this.currentStep,
    this.isCancelled = false,
  });

  final int currentStep;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStep(
        icon: Icons.receipt_rounded,
        label: 'Order Placed',
        subtitle: 'We\'ve received your order',
      ),
      _TimelineStep(
        icon: Icons.verified_rounded,
        label: 'Confirmed',
        subtitle: 'Order confirmed by team',
      ),
      _TimelineStep(
        icon: Icons.sync_rounded,
        label: 'Processing',
        subtitle: 'Being prepared for dispatch',
      ),
      _TimelineStep(
        icon: Icons.local_shipping_rounded,
        label: 'Shipped',
        subtitle: 'Out for delivery to you',
      ),
      _TimelineStep(
        icon: Icons.delivery_dining_rounded,
        label: 'Out for Delivery',
        subtitle: 'Almost there!',
      ),
      _TimelineStep(
        icon: Icons.check_circle_rounded,
        label: 'Delivered',
        subtitle: 'Enjoy your fresh flour!',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: AppTextStyles.headingM),
        const SizedBox(height: 12),
        if (isCancelled)
          _CancelledTimeline()
        else
          ...steps.asMap().entries.map(
                (entry) => _TimelineTile(
                  step: entry.value,
                  stepIndex: entry.key,
                  currentStep: currentStep,
                  isLast: entry.key == steps.length - 1,
                ),
              ),
      ],
    );
  }
}

class _TimelineStep {
  final IconData icon;
  final String label;
  final String subtitle;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.subtitle,
  });
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.stepIndex,
    required this.currentStep,
    required this.isLast,
  });

  final _TimelineStep step;
  final int stepIndex;
  final int currentStep;
  final bool isLast;

  bool get isDone => stepIndex <= currentStep;
  bool get isActive => stepIndex == currentStep;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: icon + line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? isActive
                            ? AppColors.primaryBrown
                            : AppColors.accentGreen
                        : AppColors.border,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primaryBrown.withAlpha(60),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isDone && !isActive ? Icons.check_rounded : step.icon,
                    size: 18,
                    color: isDone ? Colors.white : AppColors.textHint,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: stepIndex < currentStep
                          ? AppColors.accentGreen
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: AppTextStyles.headingS.copyWith(
                      color: isDone ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.bodyS.copyWith(
                      color: isDone ? AppColors.textSecondary : AppColors.textHint,
                    ),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBrown.withAlpha(15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.primaryBrown.withAlpha(60)),
                      ),
                      child: Text(
                        'Current Status',
                        style: AppTextStyles.badge.copyWith(color: AppColors.primaryBrown),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Cancelled', style: AppTextStyles.headingS.copyWith(color: AppColors.error)),
              Text('Your order has been cancelled.',
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.error.withAlpha(180))),
            ],
          ),
        ],
      ),
    );
  }
}
