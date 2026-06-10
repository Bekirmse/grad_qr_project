import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class MarketSearchResult {
  final String barcode;
  final String name;
  final String photoUrl;
  final double price;
  final String marketName;

  MarketSearchResult({
    required this.barcode,
    required this.name,
    required this.photoUrl,
    required this.price,
    required this.marketName,
  });

  factory MarketSearchResult.fromJson(Map<String, dynamic> json) {
    return MarketSearchResult(
      barcode: json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      price: (json['price'] as num).toDouble(),
      marketName: json['marketName']?.toString() ?? '',
    );
  }
}

class MarketApiService {
  static const List<String> cities = [
    'All',
    'Nicosia',
    'Kyrenia',
    'Famagusta',
  ];

  static const List<String> _allCities = ['Nicosia', 'Kyrenia', 'Famagusta'];

  static String? _cachedUrl = null;

  static Future<String?> getBaseUrl() async {
    if (_cachedUrl != null) return _cachedUrl;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('marketApi')
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final url = doc.data()?['baseUrl']?.toString() ?? '';
        _cachedUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
        return _cachedUrl;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static void clearCache() => _cachedUrl = null;

  static Future<List<MarketSearchResult>> searchProductInCity(
      String barcode, String city) async {
    if (city == 'All') {
      final futures = _allCities.map((c) => _fetchCity(barcode, c));
      final results = await Future.wait(futures);
      final combined = results.expand((r) => r).toList();
      combined.sort((a, b) => a.price.compareTo(b.price));
      return combined;
    }
    return _fetchCity(barcode, city);
  }

  static Future<List<MarketSearchResult>> _fetchCity(
      String barcode, String city) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null || baseUrl.isEmpty) return [];
    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse(
        '$cleanUrl/api/products/search?barcode=${Uri.encodeComponent(barcode)}&city=${Uri.encodeComponent(city)}');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => MarketSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
