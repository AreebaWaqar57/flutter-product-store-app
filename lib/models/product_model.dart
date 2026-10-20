class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String thumbnail;
  final String? brand;
  final double? rating;
  final int? stock;

  final bool isLocal;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.thumbnail,
    this.brand,
    this.rating,
    this.stock,
    this.isLocal = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: json['category']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString() ?? '',
      brand: json['brand']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt(),
    );
  }
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'thumbnail': thumbnail,
  };

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? thumbnail,
    bool? isLocal,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      thumbnail: thumbnail ?? this.thumbnail,
      brand: brand,
      rating: rating,
      stock: stock,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
