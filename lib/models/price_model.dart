class Price {
  final String productBarcode; // Doküman: productBarcode
  final String marketId; // Doküman: marketId
  final double price; // Doküman: price (Number)
  final String currency; // Doküman: currency

  // Arayüzde göstermek için sonradan dolduracağımız alanlar (Veritabanında yok)
  String? marketName;
  String? marketLogoUrl;

  Price({
    required this.productBarcode,
    required this.marketId,
    required this.price,
    required this.currency,
    this.marketName,
    this.marketLogoUrl,
  });

  factory Price.fromMap(Map<String, dynamic> data) {
    return Price(
      productBarcode: data['productBarcode'] ?? '',
      marketId: data['marketId'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'TRY',
    );
  }
}
