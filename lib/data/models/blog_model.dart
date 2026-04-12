class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String body;
  final String? image;
  final String type; // 'recipe' | 'health'
  final DateTime createdAt;

  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.body,
    this.image,
    required this.type,
    required this.createdAt,
  });

  String get excerpt {
    final plain = body.replaceAll(RegExp(r'\n+'), ' ').trim();
    return plain.length > 120 ? '${plain.substring(0, 120)}…' : plain;
  }

  String get readTime {
    final words = body.split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  factory BlogPost.fromJson(Map<String, dynamic> json) => BlogPost(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        image: json['image']?.toString(),
        type: json['type']?.toString() ?? 'health',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
}
