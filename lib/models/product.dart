class Product {
  final int id;
  final String title;
  final String category;
  final double price;
  final String thumbnail;

  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.thumbnail,
  });

  // Map -> Product (creates a NEW object). Used for API data and saved data.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  // Product -> Map (describes an EXISTING object). Used to save favourites.
  // Keys must match the ones fromJson reads.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'price': price,
      'thumbnail': thumbnail,
    };
  }
}
