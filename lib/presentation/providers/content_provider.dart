import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/blog_model.dart';
import '../../data/models/testimonial_model.dart';
import '../../data/repositories/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (_) => ContentRepository(),
);

// All blogs
final blogsProvider = FutureProvider<List<BlogPost>>((ref) async {
  return ref.read(contentRepositoryProvider).getBlogs();
});

// Single blog by slug — always fetches full post (list endpoint truncates body)
final blogBySlugProvider =
    FutureProvider.family<BlogPost, String>((ref, slug) async {
  return ref.read(contentRepositoryProvider).getBlogBySlug(slug);
});

// Testimonials
final testimonialsProvider = FutureProvider<List<Testimonial>>((ref) async {
  return ref.read(contentRepositoryProvider).getTestimonials();
});
