class Testimonial {
  final String id;
  final String name;
  final String location;
  final String text;
  final double rating;
  final String when;

  const Testimonial({
    required this.id,
    required this.name,
    required this.location,
    required this.text,
    required this.rating,
    required this.when,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory Testimonial.fromJson(Map<String, dynamic> json) => Testimonial(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        when: json['when']?.toString() ?? '',
      );
}
