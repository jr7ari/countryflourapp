import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class _BannerData {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
  });
}

final _banners = [
  _BannerData(
    title: 'Freshly Milled\nGoodness',
    subtitle: 'Traditional chakki atta for the softest rotis',
    gradientColors: [const Color(0xFF6B4226), const Color(0xFFC8860A)],
    icon: Icons.grain_rounded,
  ),
  _BannerData(
    title: 'Combo\nDeals',
    subtitle: 'Save up to 25% with our family packs',
    gradientColors: [const Color(0xFFE85D26), const Color(0xFFFF9A3C)],
    icon: Icons.inventory_2_rounded,
  ),
  _BannerData(
    title: 'Health\nFirst',
    subtitle: 'Multigrain & millet flours for wellness',
    gradientColors: [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
    icon: Icons.eco_rounded,
  ),
];

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_controller.hasClients
            ? (_controller.page?.round() ?? 0)
            : 0) +
        1;
    _controller.animateToPage(
      next % _banners.length,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            itemBuilder: (context, i) => _BannerCard(banner: _banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _controller,
          count: _banners.length,
          effect: ExpandingDotsEffect(
            dotHeight: 5,
            dotWidth: 5,
            expansionFactor: 4,
            activeDotColor: AppColors.primaryBrown,
            dotColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});
  final _BannerData banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shape
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        banner.subtitle,
                        style: AppTextStyles.bodyS.copyWith(
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  banner.icon,
                  size: 80,
                  color: Colors.white.withAlpha(60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
