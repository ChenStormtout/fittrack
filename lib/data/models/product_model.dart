class ProductModel {
  final int id;
  final String name;
  final String description;
  final double priceIdr;
  final String imageUrl;
  final double rating;
  final int stock;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.priceIdr,
    required this.imageUrl,
    required this.rating,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price_idr': priceIdr,
      'image_url': imageUrl,
      'rating': rating,
      'stock': stock,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      priceIdr: (map['price_idr'] as num).toDouble(),
      imageUrl: map['image_url'] as String,
      rating: (map['rating'] as num).toDouble(),
      stock: map['stock'] as int,
    );
  }
}