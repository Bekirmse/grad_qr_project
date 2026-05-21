import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiPriceService {
  static const String _baseUrl = 'https://scanwiser-price-api.onrender.com';

  static Future<Map<String, dynamic>?> getProductWithPrices(String barcode) async {
    try {
      final markets = await _getMarketsWithApiUrls();
      if (markets.isEmpty) return await _fetchFromBaseApi(barcode);

      final futures = markets.map((m) => _fetchMarketPrice(m, barcode));
      final results = await Future.wait(futures);

      final validPrices = results.whereType<Map<String, dynamic>>().toList();
      if (validPrices.isEmpty) return await _fetchFromBaseApi(barcode);

      validPrices.sort((a, b) =>
          (double.tryParse(a['price'].toString()) ?? 0)
              .compareTo(double.tryParse(b['price'].toString()) ?? 0));

      final first = validPrices.first;
      return {
        'success': true,
        'barcode': barcode,
        'productName': first['productName'],
        'brand': first['brand'],
        'category': first['category'],
        'imageUrl': first['imageUrl'],
        'prices': validPrices.map((p) => {
          'marketId': p['marketId'],
          'marketName': p['marketName'],
          'marketLogoUrl': p['marketLogoUrl'],
          'price': p['price'],
          'currency': p['currency'],
        }).toList(),
      };
    } catch (_) {
      return await _fetchFromBaseApi(barcode);
    }
  }

  static Future<Map<String, dynamic>?> _fetchMarketPrice(
      Map<String, dynamic> market, String barcode) async {
    final apiUrl = market['apiUrl']?.toString() ?? '';
    if (apiUrl.isEmpty) return null;
    try {
      final uri = Uri.parse('$apiUrl/prices/$barcode');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _getMarketsWithApiUrls() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('supermarkets')
          .get();
      return snap.docs
          .map((d) => Map<String, dynamic>.from(d.data()))
          .where((m) => m['apiUrl'] != null && m['apiUrl'].toString().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> _fetchFromBaseApi(String barcode) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/prices/$barcode'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllProducts({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null && category != 'All') queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse('$_baseUrl/api/products')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['products']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/categories'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return List<String>.from(data['categories']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSupermarkets() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/supermarkets'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['supermarkets']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
