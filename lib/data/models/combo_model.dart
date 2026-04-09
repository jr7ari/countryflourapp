/// Strict mapping to GET /api/combos response
class ComboProductItem {
  final String productId;
  final String productName;
  final String weight;
  final int quantity;
  final double baseMRP;

  const ComboProductItem({
    required this.productId,
    required this.productName,
    required this.weight,
    required this.quantity,
    required this.baseMRP,
  });

  factory ComboProductItem.fromJson(Map<String, dynamic> json) => ComboProductItem(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        weight: json['weight']?.toString() ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        baseMRP: (json['baseMRP'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'weight': weight,
        'quantity': quantity,
        'baseMRP': baseMRP,
      };

  double get totalMRP => baseMRP * quantity;
}

class Combo {
  final String id;
  final String name;
  final String description;
  final List<ComboProductItem> products;
  final double mrp;
  final double offerPrice;
  final String img;
  /// Raw weight string from API (e.g. "2kg", "2000g"). Used as fallback when
  /// individual product weights are missing or unparseable.
  final String weight;

  const Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.products,
    required this.mrp,
    required this.offerPrice,
    required this.img,
    this.weight = '',
  });

  factory Combo.fromJson(Map<String, dynamic> json) => Combo(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        products: (json['products'] as List<dynamic>?)
                ?.map((e) => ComboProductItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        mrp: (json['mrp'] as num?)?.toDouble() ?? 0.0,
        offerPrice: (json['offerPrice'] as num?)?.toDouble() ?? 0.0,
        img: json['img']?.toString() ?? json['image']?.toString() ?? '',
        // Try several field names the API might use for total weight
        weight: json['weight']?.toString() ??
            json['totalWeight']?.toString() ??
            json['totalWeightKg']?.toString() ??
            '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'products': products.map((p) => p.toJson()).toList(),
        'mrp': mrp,
        'offerPrice': offerPrice,
        'img': img,
        'weight': weight,
      };

  /// Computed: discount percentage
  double get discountPercent {
    if (mrp <= 0) return 0;
    return ((mrp - offerPrice) / mrp) * 100;
  }

  /// Computed: total savings
  double get savings => mrp - offerPrice;

  /// Computed: total items count
  int get totalItems =>
      products.fold(0, (sum, p) => sum + p.quantity);

  /// Computed: total weight summary
  String get weightSummary {
    if (products.isEmpty) return '';
    return products.map((p) => '${p.quantity}×${p.weight}').join(' + ');
  }
}
