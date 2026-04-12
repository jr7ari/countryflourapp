import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../data/models/blog_model.dart';
import '../../../presentation/providers/content_provider.dart';
import '../../../presentation/navigation/app_router.dart';

// Colour palette per blog type
List<Color> _gradientFor(String type) {
  switch (type.toLowerCase()) {
    case 'recipe':
      return [const Color(0xFFE85D26), const Color(0xFFFF9A3C)];
    case 'health':
      return [const Color(0xFF4A7C3F), const Color(0xFF76B041)];
    default:
      return [const Color(0xFF6B4226), const Color(0xFFC8860A)];
  }
}

IconData _iconFor(String type) {
  switch (type.toLowerCase()) {
    case 'recipe':
      return Icons.restaurant_rounded;
    case 'health':
      return Icons.favorite_rounded;
    default:
      return Icons.article_rounded;
  }
}

// ─── Blogs Section ────────────────────────────────────────────────────────────

class BlogsSection extends ConsumerWidget {
  const BlogsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(blogsProvider);

    return blogsAsync.when(
      loading: () => const _BlogsShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (blogs) {
        if (blogs.isEmpty) return const SizedBox.shrink();
        return _BlogsContent(blogs: blogs);
      },
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _BlogsContent extends StatelessWidget {
  const _BlogsContent({required this.blogs});
  final List<BlogPost> blogs;

  @override
  Widget build(BuildContext context) {
    final featured = blogs.first;
    final rest = blogs.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From Our Kitchen', style: AppTextStyles.headingXL),
              Text(
                'Tips, nutrition & recipes',
                style: AppTextStyles.bodyS
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        // Featured card
        _FeaturedCard(post: featured)
            .animate()
            .fadeIn(delay: 150.ms, duration: 400.ms)
            .slideY(begin: 0.06, end: 0),

        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 168,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rest.length,
              itemBuilder: (_, i) =>
                  _CompactCard(post: rest[i], index: i),
            ),
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Featured Card ────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(post.type);
    final icon = _iconFor(post.type);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.blogDetail(post.slug)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image or gradient background
              if (post.image != null)
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: post.image!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                ),

              // Dark gradient overlay (bottom-to-top)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(30),
                        Colors.black.withAlpha(180),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Large faded icon top-right
              if (post.image == null)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(icon, size: 140,
                      color: Colors.white.withAlpha(18)),
                ),

              // Content overlay
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeChip(type: post.type),
                        const Spacer(),
                        Icon(Icons.schedule_rounded,
                            size: 12, color: Colors.white.withAlpha(200)),
                        const SizedBox(width: 4),
                        Text(
                          post.readTime,
                          style: AppTextStyles.labelS
                              .copyWith(color: Colors.white.withAlpha(200)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: AppTextStyles.headingL.copyWith(
                        color: Colors.white,
                        height: 1.25,
                        shadows: [
                          Shadow(color: Colors.black.withAlpha(80),
                              blurRadius: 8),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Read article',
                          style: AppTextStyles.labelL.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact Card ─────────────────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.post, required this.index});
  final BlogPost post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(post.type);
    final icon = _iconFor(post.type);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.blogDetail(post.slug)),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or gradient top
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: post.image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: post.image!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: gradient,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  gradient.last.withAlpha(160)
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 8,
                            child: _TypeChip(type: post.type),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(icon, size: 70,
                                  color: Colors.white.withAlpha(20)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: _TypeChip(type: post.type),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.title,
                      style: AppTextStyles.headingS,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(post.readTime, style: AppTextStyles.labelS),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.primaryBrown),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (200 + index * 100).ms, duration: 350.ms)
          .slideX(begin: 0.08, end: 0),
    );
  }
}

// ─── Type chip ────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.labelS.copyWith(
          color: Colors.white,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _BlogsShimmer extends StatelessWidget {
  const _BlogsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 160, height: 22, borderRadius: 6),
          const SizedBox(height: 6),
          ShimmerBox(width: 200, height: 14, borderRadius: 4),
          const SizedBox(height: 16),
          ShimmerBox(
              width: double.infinity, height: 200, borderRadius: 20),
          const SizedBox(height: 12),
          Row(
            children: [
              ShimmerBox(width: 200, height: 168, borderRadius: 16),
              const SizedBox(width: 12),
              ShimmerBox(width: 200, height: 168, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}
