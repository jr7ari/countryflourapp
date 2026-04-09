/// Strict mapping to GET /api/products response
class ProductVariant {
  final String id;
  final String weight;
  final double price;
  final double comparePrice;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.weight,
    required this.price,
    required this.comparePrice,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id']?.toString() ?? '',
        weight: json['weight']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        comparePrice: (json['comparePrice'] as num?)?.toDouble() ?? 0.0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight': weight,
        'price': price,
        'comparePrice': comparePrice,
        'stock': stock,
      };

  bool get inStock => stock > 0;
  bool get hasDiscount => comparePrice > price;
  double get discountPercent =>
      hasDiscount ? ((comparePrice - price) / comparePrice) * 100 : 0;
}

/// Bulk pricing tier embedded in a product — matches API shape exactly:
/// { "qty": 2, "mrp": 280, "offerPrice": 255 }
class ProductBulkCombo {
  final int qty;
  final double mrp;
  final double offerPrice;

  const ProductBulkCombo({
    required this.qty,
    required this.mrp,
    required this.offerPrice,
  });

  factory ProductBulkCombo.fromJson(Map<String, dynamic> json) => ProductBulkCombo(
        qty: (json['qty'] as num?)?.toInt() ?? 0,
        mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
        offerPrice: (json['offerPrice'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'qty': qty, 'mrp': mrp, 'offerPrice': offerPrice};

  double get savings => mrp - offerPrice;
  double get discountPercent => mrp > 0 ? (savings / mrp) * 100 : 0;
}

class Product {
  final String id;
  final String name;
  final double baseMRP;
  final String slug;
  final String description; // HTML content
  final String shortDescription;
  final String? ingredients;
  final String? nutritionalInfo; // HTML content
  final String category;
  final String image;
  final List<String> images;
  final List<ProductVariant> variants;
  final bool featured;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final bool bestseller;
  final List<ProductBulkCombo> combos; // bulk pricing tiers

  const Product({
    required this.id,
    required this.name,
    required this.baseMRP,
    required this.slug,
    required this.description,
    required this.shortDescription,
    this.ingredients,
    this.nutritionalInfo,
    required this.category,
    required this.image,
    required this.images,
    required this.variants,
    required this.featured,
    required this.rating,
    required this.reviewCount,
    required this.inStock,
    required this.bestseller,
    required this.combos,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        baseMRP: (json['baseMRP'] as num?)?.toDouble() ?? 0.0,
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        shortDescription: json['shortDescription']?.toString() ?? '',
        ingredients: json['ingredients']?.toString(),
        nutritionalInfo: json['nutritionalInfo']?.toString(),
        category: json['category']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        variants: (json['variants'] as List<dynamic>?)
                ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        featured: json['featured'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        inStock: json['inStock'] as bool? ?? true,
        bestseller: json['bestseller'] as bool? ?? false,
        combos: (json['combos'] as List<dynamic>?)
                ?.map((e) => ProductBulkCombo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseMRP': baseMRP,
        'slug': slug,
        'description': description,
        'shortDescription': shortDescription,
        'ingredients': ingredients,
        'nutritionalInfo': nutritionalInfo,
        'category': category,
        'image': image,
        'images': images,
        'variants': variants.map((v) => v.toJson()).toList(),
        'featured': featured,
        'rating': rating,
        'reviewCount': reviewCount,
        'inStock': inStock,
        'bestseller': bestseller,
        'combos': combos.map((c) => c.toJson()).toList(),
      };

  /// Returns the cheapest available variant price
  double get lowestPrice {
    if (variants.isEmpty) return baseMRP;
    return variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  /// Default variant (first in stock, or first)
  ProductVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere((v) => v.inStock, orElse: () => variants.first);
  }

  List<String> get allImages {
    final all = [image, ...images].where((i) => i.isNotEmpty).toList();
    return all.isEmpty ? [image] : all;
  }
}
