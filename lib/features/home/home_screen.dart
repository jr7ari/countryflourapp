import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../presentation/providers/products_provider.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../presentation/providers/location_provider.dart';
import '../../presentation/providers/content_provider.dart';
import '../../presentation/navigation/app_router.dart';
import 'widgets/banner_slider.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/combo_highlights_section.dart';
import 'widgets/blogs_section.dart';
import 'widgets/testimonials_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteConfig = ref.watch(siteConfigProvider);
    final auth = ref.watch(authProvider);
    final location = ref.watch(userLocationProvider);

    final isJamshedpur = location.city.toLowerCase().contains('jamshedpur');

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: RefreshIndicator(
        color: AppColors.primaryBrown,
        backgroundColor: AppColors.surfaceWhite,
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(combosProvider);
          ref.invalidate(siteConfigProvider);
          ref.invalidate(blogsProvider);
          ref.invalidate(testimonialsProvider);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.backgroundCream,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 20,
              toolbarHeight: 70,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(userLocationProvider.notifier).refresh(),
                    child: Row(
                      children: [
                        if (location.status == LocationStatus.loading)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primaryGold,
                            ),
                          )
                        else
                          const Icon(Icons.location_on_rounded,
                              size: 14, color: AppColors.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          location.status == LocationStatus.loading
                              ? 'Detecting...'
                              : location.displayLocation,
                          style: AppTextStyles.labelM.copyWith(
                            color: AppColors.primaryGold,
                          ),
                        ),
                        if (location.status != LocationStatus.loading) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 14, color: AppColors.primaryGold),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    auth.isLoggedIn ? 'Hello, ${auth.name}! 👋' : 'Country Flour',
                    style: AppTextStyles.headingL,
                  ),
                ],
              ),
              actions: [
                // Avatar / guest icon — taps to profile
                GestureDetector(
                  onTap: () => context.go(AppRoutes.profile),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: auth.isLoggedIn
                            ? AppColors.primaryGold
                            : AppColors.border,
                        width: auth.isLoggedIn ? 2 : 1,
                      ),
                    ),
                    child: ClipOval(
                      child: auth.isLoggedIn && auth.photoUrl != null
                          ? Image.network(
                              auth.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _AvatarInitial(name: auth.name),
                            )
                          : auth.isLoggedIn
                              ? _AvatarInitial(name: auth.name)
                              : Container(
                                  color: AppColors.surfaceWhite,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 20,
                                    color: AppColors.textHint,
                                  ),
                                ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),

            // Announcement Banner
            siteConfig.when(
              data: (config) => config.bannerEnabled
                  ? SliverToBoxAdapter(
                      child: _AnnouncementBanner(
                        message: config.bannerMessage,
                        type: config.bannerType,
                      ).animate().slideY(begin: -0.5, end: 0, duration: 400.ms),
                    )
                  : const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Local Offer Banner (Jamshedpur only)
            siteConfig.when(
              data: (config) =>
                  config.showLocalOffer && isJamshedpur
                      ? SliverToBoxAdapter(
                          child: const _LocalOfferBanner()
                              .animate()
                              .slideY(begin: -0.3, end: 0, duration: 400.ms),
                        )
                      : const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Hero Banner Slider
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: const BannerSlider()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms),
              ),
            ),

            // Combo Highlights Section
            SliverToBoxAdapter(
              child: const ComboHighlightsSection()
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
            ),

            // Featured Products
            SliverToBoxAdapter(
              child: const FeaturedProductsSection()
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),
            ),

            // Bestsellers header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SectionHeader(
                  title: 'Bestsellers',
                  subtitle: 'Customer favourites',
                  onSeeAll: () => context.go(AppRoutes.products),
                ),
              ),
            ),

            // Bestseller products grid
            const _BestsellerGrid(),

            // Blogs Section
            SliverToBoxAdapter(
              child: const BlogsSection()
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms),
            ),

            // Testimonials Section
            SliverToBoxAdapter(
              child: const TestimonialsSection()
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms),
            ),

            // Why choose us
            SliverToBoxAdapter(
              child: const _WhyChooseUs()
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner({required this.message, required this.type});
  final String message;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'success'
        ? AppColors.accentGreen
        : type == 'warning'
            ? AppColors.warning
            : AppColors.primaryGold;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTextStyles.labelL.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}

class _LocalOfferBanner extends StatelessWidget {
  const _LocalOfferBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '🎉 Special offer for Jamshedpur! Free delivery on all orders today.',
              style: AppTextStyles.labelL.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.onSeeAll,
  });
  final String title;
  final String subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headingXL),
              Text(subtitle,
                  style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See All', style: AppTextStyles.buttonM.copyWith(color: AppColors.primaryBrown)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primaryBrown),
              ],
            ),
          ),
      ],
    );
  }
}

class _BestsellerGrid extends ConsumerWidget {
  const _BestsellerGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestsellers = ref.watch(bestsellerProductsProvider);

    return bestsellers.when(
      data: (products) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _ProductMiniCard(product: products[i]),
            childCount: products.take(4).length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
        ),
      ),
      loading: () => SliverToBoxAdapter(child: ProductsGridShimmer(count: 4)),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _ProductMiniCard extends ConsumerWidget {
  const _ProductMiniCard({required this.product});
  final dynamic product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultVariant = product.defaultVariant;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.productDetailPath(product.slug)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF8ED), Color(0xFFFFF0D4)],
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.grain_rounded, size: 48, color: AppColors.primaryGold),
                        ),
                      ),
                    ),
                    if (product.bestseller)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 9, color: Colors.white),
                              const SizedBox(width: 2),
                              Text('BEST', style: AppTextStyles.badge.copyWith(color: Colors.white, fontSize: 8)),
                            ],
                          ),
                        ),
                      ),
                    // Out of Stock overlay
                    if (!product.inStock) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(50),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'OUT OF STOCK',
                              style: AppTextStyles.badge.copyWith(
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.headingS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (defaultVariant != null)
                      Row(
                        children: [
                          Text(
                            '₹${defaultVariant.price.toInt()}',
                            style: AppTextStyles.priceS,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '₹${defaultVariant.comparePrice.toInt()}',
                            style: AppTextStyles.priceStrike,
                          ),
                        ],
                      ),
                    Text(
                      defaultVariant?.weight ?? '',
                      style: AppTextStyles.labelM,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar initial fallback ──────────────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryBrown,
      child: Center(
        child: Text(
          name != null && name!.isNotEmpty ? name![0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WhyChooseUs extends StatelessWidget {
  const _WhyChooseUs();

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.grain_rounded, 'Freshly Milled', 'Milled when you order'),
      (Icons.eco_rounded, '100% Natural', 'No preservatives, no additives'),
      (Icons.local_shipping_rounded, 'Fresh Delivery', 'Mill-to-door freshness'),
      (Icons.verified_rounded, 'Quality Tested', 'Every packet quality checked'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF4A2818)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Country Flour?',
            style: AppTextStyles.headingXL.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'We bring the goodness of traditional milling',
            style: AppTextStyles.bodyS.copyWith(color: Colors.white.withAlpha(160)),
          ),
          const SizedBox(height: 20),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(f.$1, size: 18, color: AppColors.primaryGoldLight),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.$2, style: AppTextStyles.headingS.copyWith(color: Colors.white)),
                      Text(f.$3, style: AppTextStyles.labelM.copyWith(color: Colors.white.withAlpha(140))),
                    ],
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
