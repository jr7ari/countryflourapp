import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/blog_model.dart';
import '../models/testimonial_model.dart';

class ContentRepository {
  static const _base = 'https://www.countryflour.in/api/mobileapi';

  Future<List<BlogPost>> getBlogs({String? type}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$_base/blogs')
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load blogs (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final list = data is List ? data : (data['blogs'] ?? data['data'] ?? []);
    return (list as List)
        .map((e) => BlogPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single blog post with full body content.
  Future<BlogPost> getBlogBySlug(String slug) async {
    // Try dedicated single-post endpoint first
    final singleUri = Uri.parse('$_base/blogs/$slug');
    final singleResp = await http.get(singleUri);
    if (singleResp.statusCode == 200) {
      final data = jsonDecode(singleResp.body);
      // Response may be the object directly or wrapped
      final obj = data is Map<String, dynamic>
          ? (data['blog'] ?? data['data'] ?? data)
          : null;
      if (obj is Map<String, dynamic>) {
        final post = BlogPost.fromJson(obj);
        if (post.body.isNotEmpty) return post;
      }
    }

    // Fallback: query by slug param
    final uri = Uri.parse('$_base/blogs').replace(
      queryParameters: {'slug': slug},
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load blog (${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    // Could be a list or a single object
    if (data is List && data.isNotEmpty) {
      return BlogPost.fromJson(data.first as Map<String, dynamic>);
    }
    if (data is Map<String, dynamic>) {
      final obj = data['blog'] ?? data['data'] ?? data;
      if (obj is List && obj.isNotEmpty) {
        return BlogPost.fromJson(obj.first as Map<String, dynamic>);
      }
      if (obj is Map<String, dynamic>) {
        return BlogPost.fromJson(obj);
      }
    }
    throw Exception('Blog not found: $slug');
  }

  Future<List<Testimonial>> getTestimonials() async {
    final response = await http.get(Uri.parse('$_base/testimonials'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load testimonials (${response.statusCode})');
    }

    final data = jsonDecode(response.body);
    final list = data is List
        ? data
        : (data['testimonials'] ?? data['data'] ?? []);
    return (list as List)
        .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
