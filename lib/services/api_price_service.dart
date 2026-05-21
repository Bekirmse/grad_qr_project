import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiPriceService {
  static const String _baseUrl = 'https://scanwiser-price-api.onrender.com';

  static Future<Map<String, dynamic>?> getProductWithPrices(
    String barcode,
  ) async {
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
      if (category != null && category != 'All') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '$_baseUrl/api/products',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));

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
