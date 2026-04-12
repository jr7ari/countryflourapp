import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/testimonial_model.dart';
import '../../../presentation/providers/content_provider.dart';

// ─── Avatar colour palette (cycles based on index) ───────────────────────────
const _avatarColors = [
  Color(0xFF6B4226),
  Color(0xFF4A7C3F),
  Color(0xFF1565C0),
  Color(0xFFC8860A),
  Color(0xFF7B1FA2),
  Color(0xFFD84315),
  Color(0xFF00695C),
];

// ─── Testimonials Section ─────────────────────────────────────────────────────

class TestimonialsSection extends ConsumerStatefulWidget {
  const TestimonialsSection({super.key});

  @override
  ConsumerState<TestimonialsSection> createState() =>
      _TestimonialsSectionState();
}

class _TestimonialsSectionState extends ConsumerState<TestimonialsSection> {
  final _pageController = PageController(viewportFraction: 0.88);
  int _current = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testimonialsAsync = ref.watch(testimonialsProvider);

    return testimonialsAsync.when(
      loading: () => const _TestimonialsShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (testimonials) {
        if (testimonials.isEmpty) return const SizedBox.shrink();

        // Compute overall rating
        final avgRating = testimonials.fold<double>(
              0,
              (sum, t) => sum + t.rating,
            ) /
            testimonials.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What Our Customers Say',
                            style: AppTextStyles.headingXL),
                        Text(
                          'Real reviews from real kitchens',
                          style: AppTextStyles.bodyS
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.primaryGold),
                          const SizedBox(width: 3),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: AppTextStyles.headingM
                                .copyWith(color: AppColors.primaryBrown),
                          ),
                        ],
                      ),
                      Text(
                        '${testimonials.length} reviews',
                        style: AppTextStyles.labelS
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Cards pager
            SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _pageController,
                itemCount: testimonials.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _TestimonialCard(
                  testimonial: testimonials[i],
                  isActive: i == _current,
                  index: i,
                  avatarColor:
                      _avatarColors[i % _avatarColors.length],
                ),
              ),
            ),

            // Page indicator
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  testimonials.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current
                          ? AppColors.primaryBrown
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Trust stats row
            _TrustRow(total: testimonials.length, rating: avgRating)
                .animate()
                .fadeIn(delay: 400.ms),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ─── Testimonial Card ─────────────────────────────────────────────────────────

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.testimonial,
    required this.isActive,
    required this.index,
    required this.avatarColor,
  });
  final Testimonial testimonial;
  final bool isActive;
  final int index;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        top: isActive ? 0 : 14,
        bottom: isActive ? 0 : 14,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.primaryGold.withAlpha(80)
              : AppColors.border,
          width: isActive ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primaryGold.withAlpha(25)
                : Colors.black.withAlpha(5),
            blurRadius: isActive ? 20 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: avatar + name + stars
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    testimonial.initials,
                    style: AppTextStyles.headingS
                        .copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(testimonial.name,
                        style: AppTextStyles.headingS),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Text(testimonial.location,
                            style: AppTextStyles.labelS),
                        if (testimonial.when.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('· ${testimonial.when}',
                              style: AppTextStyles.labelS),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Stars
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < testimonial.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 14,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Opening quote
          Text(
            '\u201C',
            style: TextStyle(
              fontSize: 38,
              height: 0.4,
              color: AppColors.primaryGold.withAlpha(80),
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          // Review text
          Expanded(
            child: Text(
              testimonial.text,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms);
  }
}

// ─── Trust Stats Row ──────────────────────────────────────────────────────────

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.total, required this.rating});
  final int total;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.verified_rounded, '${total * 3}+\nOrders', AppColors.accentGreen),
      (Icons.star_rounded, '${rating.toStringAsFixed(1)}\nRating', AppColors.primaryGold),
      (Icons.people_rounded, '$total+\nReviews', AppColors.info),
      (Icons.repeat_rounded, '80%\nRepeat', AppColors.primaryBrown),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: isLast
                      ? BorderSide.none
                      : const BorderSide(
                          color: AppColors.border, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Icon(item.$1, size: 20, color: item.$3),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    style: AppTextStyles.headingS
                        .copyWith(fontSize: 13, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _TestimonialsShimmer extends StatelessWidget {
  const _TestimonialsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 220, height: 22, borderRadius: 6),
          const SizedBox(height: 6),
          ShimmerBox(width: 180, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 220, borderRadius: 20),
        ],
      ),
    );
  }
}
