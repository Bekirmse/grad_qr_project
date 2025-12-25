class Product {
  final String barcode; // Doküman: barcode (Primary Key)
  final String productName; // Doküman: productName
  final String category; // Doküman: category
  final String brand; // Doküman: brand
  final String imageUrl; // Doküman: imageUrl
  final String description; // Doküman: description

  Product({
    required this.barcode,
    required this.productName,
    required this.category,
    required this.brand,
    required this.imageUrl,
    required this.description,
  });

  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      barcode: data['barcode'] ?? '',
      productName: data['productName'] ?? '',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
    );
  }
}
