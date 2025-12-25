class Supermarket {
  final String marketId; // Doküman: marketId
  final String name; // Doküman: name
  final String city; // Doküman: city
  final String logoUrl; // Doküman: logoUrl

  Supermarket({
    required this.marketId,
    required this.name,
    required this.city,
    required this.logoUrl,
  });

  factory Supermarket.fromMap(Map<String, dynamic> data) {
    return Supermarket(
      marketId: data['marketId'] ?? '',
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
    );
  }
}
