class ProductItem {
  final String name;
  final double? price;
  final String store;
  final double? rating;
  final String image;
  final String url;
  final String reason;

  const ProductItem({
    required this.name,
    required this.price,
    required this.store,
    required this.rating,
    required this.image,
    required this.url,
    required this.reason,
  });

  factory ProductItem.fromMap(Map<String, dynamic> map) {
    return ProductItem(
      name: map['name']?.toString() ?? 'Unknown product',
      price: map['price'] is num ? (map['price'] as num).toDouble() : null,
      store: map['store']?.toString() ?? 'Unknown store',
      rating: map['rating'] is num ? (map['rating'] as num).toDouble() : null,
      image: map['image']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
    );
  }
}