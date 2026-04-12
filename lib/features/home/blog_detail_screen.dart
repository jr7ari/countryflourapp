import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/blog_model.dart';
import '../../presentation/providers/content_provider.dart';
import '../../presentation/navigation/app_router.dart';

// ─── Shared blog helpers ──────────────────────────────────────────────────────

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

class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.blogSlug});
  final String blogSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(blogBySlugProvider(blogSlug));

    return postAsync.when(
      loading: () => const _BlogDetailShimmer(),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundCream,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text('Could not load article.',
              style: AppTextStyles.bodyM
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ),
      data: (post) => _BlogDetailContent(post: post),
    );
  }
}

// ─── Main content ─────────────────────────────────────────────────────────────

class _BlogDetailContent extends ConsumerWidget {
  const _BlogDetailContent({required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradient = _gradientFor(post.type);
    final icon = _iconFor(post.type);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: gradient.first,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withAlpha(30),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or gradient
                  if (post.image != null)
                    CachedNetworkImage(
                      imageUrl: post.image!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),

                  // Dark overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(20),
                          Colors.black.withAlpha(200),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),

                  // Faded icon
                  if (post.image == null)
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(icon, size: 200,
                          color: Colors.white.withAlpha(15)),
                    ),

                  // Metadata overlay at bottom
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            _TypeBadge(type: post.type),
                            const SizedBox(width: 10),
                            Icon(Icons.schedule_rounded,
                                size: 12,
                                color: Colors.white.withAlpha(200)),
                            const SizedBox(width: 4),
                            Text(
                              post.readTime,
                              style: AppTextStyles.labelS.copyWith(
                                  color: Colors.white.withAlpha(200)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          post.title,
                          style: AppTextStyles.headingXL.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withAlpha(100),
                                  blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMMM yyyy').format(post.createdAt),
                          style: AppTextStyles.labelM.copyWith(
                              color: Colors.white.withAlpha(160)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Article Body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: _ArticleBody(content: post.body),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ),

          // ── More Articles ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _MoreArticles(currentSlug: post.slug),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }
}

// ─── Article body renderer ────────────────────────────────────────────────────

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    // Normalise: handle both literal "\n" escape sequences and real newlines
    final text = content
        .replaceAll(r'\n', '\n')   // convert any literal \n strings → real newlines
        .replaceAll('\r\n', '\n')  // normalise Windows line endings
        .replaceAll('\r', '\n')
        .trim();

    // Split into paragraphs on blank lines
    final paragraphs = text
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.bodyL.copyWith(height: 1.8),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.asMap().entries.map((entry) {
        final isFirst = entry.key == 0;
        return Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 20),
          child: Text(
            entry.value,
            style: AppTextStyles.bodyL.copyWith(
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── More articles ────────────────────────────────────────────────────────────

class _MoreArticles extends ConsumerWidget {
  const _MoreArticles({required this.currentSlug});
  final String currentSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(blogsProvider);

    return blogsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (blogs) {
        final others =
            blogs.where((p) => p.slug != currentSlug).take(3).toList();
        if (others.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'More Articles',
                      style: AppTextStyles.labelM.copyWith(
                          color: AppColors.textHint, letterSpacing: 0.5),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            ...others.asMap().entries.map(
                  (e) => _MoreArticleRow(post: e.value, index: e.key),
                ),
          ],
        );
      },
    );
  }
}

class _MoreArticleRow extends StatelessWidget {
  const _MoreArticleRow({required this.post, required this.index});
  final BlogPost post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(post.type);
    final icon = _iconFor(post.type);

    return GestureDetector(
      onTap: () => context.pushReplacement(AppRoutes.blogDetail(post.slug)),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image or colour icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: post.image != null
                    ? CachedNetworkImage(
                        imageUrl: post.image!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _iconBox(
                            gradient, icon),
                      )
                    : _iconBox(gradient, icon),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: AppTextStyles.headingS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.type.toUpperCase(),
                          style: AppTextStyles.labelS.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(post.readTime, style: AppTextStyles.labelS),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHint),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (index * 80).ms, duration: 300.ms)
          .slideX(begin: 0.04, end: 0),
    );
  }

  Widget _iconBox(List<Color> gradient, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Center(
          child: Icon(icon, color: Colors.white, size: 24)),
    );
  }
}

// ─── Type badge ───────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Text(
        type.toUpperCase(),
        style: AppTextStyles.labelS.copyWith(
          color: Colors.white,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _BlogDetailShimmer extends StatelessWidget {
  const _BlogDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
              width: double.infinity,
              height: 260,
              borderRadius: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 200, height: 22, borderRadius: 6),
                  const SizedBox(height: 12),
                  ShimmerBox(
                      width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(
                      width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 260, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
