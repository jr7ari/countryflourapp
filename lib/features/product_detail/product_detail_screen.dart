import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/badge_widget.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/add_or_counter_button.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/services/analytics_service.dart';
import '../../data/models/product_model.dart';
import '../../presentation/providers/products_provider.dart';
import '../../presentation/providers/cart_provider.dart';
import '../../presentation/navigation/app_router.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _selectedVariantIndex = 0;
  int _currentImageIndex = 0;
  int _quantity = 1;
  late final TabController _tabController;
  final _pageController = PageController();
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productBySlugProvider(widget.slug));

    if (!_viewTracked) {
      productAsync.whenData((product) {
        _viewTracked = true;
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => AnalyticsService.logViewProduct(product));
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: productAsync.when(
        data: (product) => _ProductDetailBody(
          product: product,
          selectedVariantIndex: _selectedVariantIndex,
          currentImageIndex: _currentImageIndex,
          quantity: _quantity,
          tabController: _tabController,
          pageController: _pageController,
          onVariantChanged: (i) => setState(() => _selectedVariantIndex = i),
          onImageChanged: (i) => setState(() => _currentImageIndex = i),
          onQuantityChanged: (q) => setState(() => _quantity = q),
        ),
        loading: () => const _ProductDetailShimmer(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProductDetailBody extends ConsumerWidget {
  const _ProductDetailBody({
    required this.product,
    required this.selectedVariantIndex,
    required this.currentImageIndex,
    required this.quantity,
    required this.tabController,
    required this.pageController,
    required this.onVariantChanged,
    required this.onImageChanged,
    required this.onQuantityChanged,
  });

  final Product product;
  final int selectedVariantIndex;
  final int currentImageIndex;
  final int quantity;
  final TabController tabController;
  final PageController pageController;
  final ValueChanged<int> onVariantChanged;
  final ValueChanged<int> onImageChanged;
  final ValueChanged<int> onQuantityChanged;

  ProductVariant? get selectedVariant =>
      product.variants.isEmpty ? null : product.variants[selectedVariantIndex];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final inCart = selectedVariant != null &&
        cart.containsProduct(product.id, selectedVariant!.id);

    return CustomScrollView(
      slivers: [
        // Image + App bar
        SliverAppBar(
          backgroundColor: const Color(0xFFFFF8ED),
          expandedHeight: 300,
          pinned: true,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            ),
          ),
          actions: [
            _ShareButton(product: product),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _ImageGallery(
              images: product.allImages,
              currentIndex: currentImageIndex,
              pageController: pageController,
              productId: product.id,
              onPageChanged: onImageChanged,
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.backgroundCream,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Wrap(
                        spacing: 8,
                        children: [
                          if (product.bestseller)
                            const AppBadge(type: BadgeType.bestseller),
                          if (product.featured && !product.bestseller)
                            const AppBadge(type: BadgeType.featured),
                          if (!product.inStock)
                            const AppBadge(type: BadgeType.outOfStock),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Text(product.name, style: AppTextStyles.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: AppTextStyles.labelL.copyWith(color: AppColors.primaryGold),
                      ),
                      const SizedBox(height: 8),

                      // Rating
                      if (product.reviewCount > 0)
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                                  i < product.rating.floor()
                                      ? Icons.star_rounded
                                      : i < product.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded,
                                  size: 16,
                                  color: AppColors.primaryGold,
                                )),
                            const SizedBox(width: 6),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: AppTextStyles.headingS,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount} reviews)',
                              style: AppTextStyles.bodyS,
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Price display
                      if (selectedVariant != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Formatters.currency(selectedVariant!.price),
                              style: AppTextStyles.priceL,
                            ),
                            if (selectedVariant!.hasDiscount) ...[
                              const SizedBox(width: 8),
                              Text(
                                Formatters.currency(selectedVariant!.comparePrice),
                                style: AppTextStyles.priceStrike.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              DiscountBadge(percent: selectedVariant!.discountPercent),
                            ],
                          ],
                        ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // Variant selector
                if (product.variants.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _VariantSelector(
                      variants: product.variants,
                      selectedIndex: selectedVariantIndex,
                      onChanged: onVariantChanged,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 20),

                // Quantity + Add to Cart
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: inCart && selectedVariant != null
                      // ── Already in cart: live counter synced with cartProvider ──
                      ? Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: AddOrCounterButton(
                                cartId: 'product_${product.id}_${selectedVariant!.id}',
                                height: 48,
                                onAdd: () {
                                  final result = ref
                                      .read(cartProvider.notifier)
                                      .addProduct(product, selectedVariant!);
                                  if (result == CartAddResult.weightExceeded) {
                                    showWeightExceededToast(context, ref);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Go to Cart',
                                icon: Icons.shopping_cart_rounded,
                                onPressed: () => context.go(AppRoutes.cart),
                                height: 48,
                              ),
                            ),
                          ],
                        )
                      // ── Not in cart: quantity picker + Add to Cart ──
                      : Row(
                          children: [
                            QuantitySelector(
                              quantity: quantity,
                              onIncrement: () {
                                if (quantity < 10) onQuantityChanged(quantity + 1);
                              },
                              onDecrement: () {
                                if (quantity > 1) onQuantityChanged(quantity - 1);
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Add to Cart',
                                icon: Icons.add_shopping_cart_rounded,
                                onPressed: product.inStock && selectedVariant != null
                                    ? () {
                                        final result = ref
                                            .read(cartProvider.notifier)
                                            .addProduct(
                                              product,
                                              selectedVariant!,
                                              quantity: quantity,
                                            );
                                        if (result == CartAddResult.weightExceeded) {
                                          showWeightExceededToast(context, ref);
                                        }
                                      }
                                    : null,
                                height: 48,
                              ),
                            ),
                          ],
                        ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                // Bulk pricing combos
                if (product.combos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: _BulkPricingTile(combos: product.combos),
                  ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 16),

                // Info tabs
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _ProductInfoTabs(
                    product: product,
                    tabController: tabController,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 32),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({
    required this.images,
    required this.currentIndex,
    required this.pageController,
    required this.productId,
    required this.onPageChanged,
  });

  final List<String> images;
  final int currentIndex;
  final PageController pageController;
  final String productId;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFFFFF8ED)),
        PageView.builder(
          controller: pageController,
          itemCount: images.isEmpty ? 1 : images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) {
            final url = images.isEmpty ? '' : images[i];
            return Hero(
              tag: 'product_${productId}_img_$i',
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.grain_rounded, size: 80, color: AppColors.primaryGold),
                ),
              ),
            );
          },
        ),

        // Dots indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: currentIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentIndex == i
                        ? AppColors.primaryBrown
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ProductVariant> variants;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Weight', style: AppTextStyles.headingS.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(variants.length, (i) {
            final variant = variants[i];
            final isSelected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBrown : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBrown : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      variant.weight,
                      style: AppTextStyles.headingS.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${variant.price.toInt()}',
                      style: AppTextStyles.labelM.copyWith(
                        color: isSelected ? Colors.white.withAlpha(200) : AppColors.primaryGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!variant.inStock)
                      Text(
                        'Out of stock',
                        style: AppTextStyles.labelS.copyWith(color: AppColors.error),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BulkPricingTile extends StatelessWidget {
  const _BulkPricingTile({required this.combos});
  final List<ProductBulkCombo> combos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_rounded, size: 16, color: AppColors.primaryGold),
              const SizedBox(width: 6),
              Text('Bulk Pricing', style: AppTextStyles.headingS.copyWith(color: AppColors.primaryGold)),
            ],
          ),
          const SizedBox(height: 8),
          ...combos.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // "Buy 2+" label
                  Text(
                    'Buy ${c.qty}+',
                    style: AppTextStyles.bodyS,
                  ),
                  // MRP struck through + offer price
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${c.mrp.toInt()}',
                        style: AppTextStyles.priceStrike,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${c.offerPrice.toInt()}',
                        style: AppTextStyles.labelL.copyWith(
                          color: AppColors.primaryBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${c.discountPercent.toStringAsFixed(0)}% off)',
                        style: AppTextStyles.labelS.copyWith(color: AppColors.accentGreen),
                      ),
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

class _ProductInfoTabs extends StatefulWidget {
  const _ProductInfoTabs({required this.product, required this.tabController});
  final Product product;
  final TabController tabController;

  @override
  State<_ProductInfoTabs> createState() => _ProductInfoTabsState();
}

class _ProductInfoTabsState extends State<_ProductInfoTabs> {
  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!widget.tabController.indexIsChanging) setState(() {});
  }

  static String _stripHtml(String html) =>
      html.replaceAll(RegExp(r'<[^>]*>'), '').trim();

  @override
  Widget build(BuildContext context) {
    final contents = [
      _stripHtml(widget.product.description),
      widget.product.ingredients ?? 'Ingredients information not available.',
      _stripHtml(
          widget.product.nutritionalInfo ?? 'Nutritional information not available.'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            controller: widget.tabController,
            labelStyle: AppTextStyles.labelL.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTextStyles.labelL,
            labelColor: AppColors.primaryBrown,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryBrown,
            indicatorWeight: 2,
            dividerColor: AppColors.border,
            tabs: const [
              Tab(text: 'Description'),
              Tab(text: 'Ingredients'),
              Tab(text: 'Nutrition'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              contents[widget.tabController.index],
              style: AppTextStyles.bodyM.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}


class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentGreenLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.accentGreen),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.labelS.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─── Share Button ─────────────────────────────────────────────────────────────

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.product});
  final Product product;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final product = widget.product;
    final deepLink =
        'https://www.countryflour.in/products/';

    // Build share text
    final price = product.variants.isNotEmpty
        ? '₹${product.variants.first.price.toInt()}'
        : '';
    final text = '🌾 *${product.name}*\n'
        '${price.isNotEmpty ? '$price onwards | ' : ''}'
        '${product.category}\n\n'
        'Order fresh 👇\n$deepLink';

    try {
      if (product.allImages.isNotEmpty) {
        // Download image and share with it
        final response =
            await http.get(Uri.parse(product.allImages.first));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final file = File(
              '${dir.path}/cf_${product.slug.replaceAll('/', '_')}.jpg');
          await file.writeAsBytes(response.bodyBytes);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'image/jpeg')],
            text: text,
            subject: product.name,
          );
          return;
        }
      }
      // Fallback: text + link only
      await Share.share(text, subject: product.name);
    } catch (_) {
      // Silently fall back to text-only if anything fails
      try {
        await Share.share(text, subject: product.name);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
        ],
      ),
      child: IconButton(
        icon: _sharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryBrown),
              )
            : const Icon(Icons.share_rounded,
                color: AppColors.textPrimary, size: 20),
        onPressed: _sharing ? null : _share,
      ),
    );
  }
}

// ─── Product Detail Shimmer ───────────────────────────────────────────────────

class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          backgroundColor: AppColors.shimmerBase,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: AppColors.shimmerBase),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 200, height: 28, borderRadius: 8),
                const SizedBox(height: 12),
                ShimmerBox(width: 100, height: 16, borderRadius: 6),
                const SizedBox(height: 16),
                ShimmerBox(width: 120, height: 32, borderRadius: 8),
                const SizedBox(height: 24),
                ShimmerBox(width: double.infinity, height: 48, borderRadius: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
