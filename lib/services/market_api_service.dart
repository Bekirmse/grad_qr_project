import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  static const Map<String, String> _cityMapping = {
    'Nicosia': 'Nicosia',
    'Kyrenia': 'Kyrenia',
    'Famagusta': 'Famagusta',
  };

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
    debugPrint('===== MarketApiService.searchProductInCity =====');
    debugPrint('Barcode: $barcode, City: $city');

    if (city == 'All') {
      debugPrint('City is All, querying all cities: $_allCities');
      final futures = _allCities.map((c) => _fetchCity(barcode, c));
      final results = await Future.wait(futures);
      debugPrint('Results from each city: ${results.map((r) => r.length).toList()}');
      final combined = results.expand((r) => r).toList();
      debugPrint('Combined results: ${combined.length}');
      combined.sort((a, b) => a.price.compareTo(b.price));
      return combined;
    }

    final results = await _fetchCity(barcode, city);
    debugPrint('Results for $city: ${results.length}');
    results.sort((a, b) => a.price.compareTo(b.price));
    return results;
  }

  static Future<List<MarketSearchResult>> _fetchCity(
      String barcode, String city) async {
    final baseUrl = await getBaseUrl();
    debugPrint('_fetchCity: barcode=$barcode, city=$city, baseUrl=$baseUrl');

    if (baseUrl == null || baseUrl.isEmpty) {
      debugPrint('ERROR: baseUrl is null or empty!');
      return [];
    }

    final cleanUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final apiCity = _cityMapping[city] ?? city;
    debugPrint('City mapping: $city → $apiCity');

    final uri = Uri.parse(
        '$cleanUrl/api/products/search?barcode=${Uri.encodeComponent(barcode)}&city=${Uri.encodeComponent(apiCity)}');
    debugPrint('Full API URI: $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('API Response status: ${response.statusCode}');
      debugPrint('API Response body length: ${response.body.length}');
      debugPrint('API Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        debugPrint('Parsed JSON count: ${body.length}');
        final results = body.map((item) => MarketSearchResult.fromJson(item)).toList();
        return results;
      }
      debugPrint('ERROR: Status code ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('EXCEPTION in _fetchCity: $e');
      return [];
    }
  }
}
