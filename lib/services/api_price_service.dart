import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiPriceService {
  static const String _baseUrl = 'https://marketapi-production-d263.up.railway.app';

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
      final uri = Uri.parse('$_baseUrl/api/products/all');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final all = List<Map<String, dynamic>>.from(data['products']);
          // barcode bazlı tekilleştir
          final seen = <String>{};
          final unique = <Map<String, dynamic>>[];
          for (final p in all) {
            final barcode = p['barcode']?.toString() ?? '';
            if (barcode.isEmpty || seen.contains(barcode)) continue;
            seen.add(barcode);
            unique.add(p);
          }
          // Firestore'dan gerçek resim ve kategori al
          var enriched = await _enrichFromFirestore(unique, search: search);
          // client-side kategori filtresi
          if (category != null && category != 'All') {
            enriched = enriched.where((p) =>
              (p['category']?.toString() ?? '') == category).toList();
          }
          return enriched;
        }
      }
    } catch (_) {}
    return _getAllProductsFromFirestore(category: category, search: search);
  }

  static Future<List<Map<String, dynamic>>> _enrichFromFirestore(
    List<Map<String, dynamic>> products, {String? search}) async {
    try {
      final barcodes = products.map((p) => p['barcode']?.toString() ?? '').where((b) => b.isNotEmpty).toList();
      if (barcodes.isEmpty) return products;

      final snap = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', whereIn: barcodes.take(10).toList())
          .get();

      final firestoreMap = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        final b = d['barcode']?.toString() ?? '';
        if (b.isNotEmpty) firestoreMap[b] = d;
      }

      var result = products.map((p) {
        final barcode = p['barcode']?.toString() ?? '';
        final fs = firestoreMap[barcode];
        final imageUrl = (p['imageUrl']?.toString() ?? '').contains('placeholder')
            ? (fs?['imageUrl'] ?? fs?['photoUrl'] ?? '')
            : p['imageUrl'];
        final category = (p['category']?.toString() ?? '').isEmpty
            ? (fs?['category'] ?? fs?['CategoryName'] ?? '')
            : p['category'];
        return {...p, 'imageUrl': imageUrl, 'category': category};
      }).toList();

      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        result = result.where((p) =>
          (p['productName'] ?? '').toString().toLowerCase().contains(q)).toList();
      }
      return result;
    } catch (_) {
      return products;
    }
  }

  static Future<List<Map<String, dynamic>>> _getAllProductsFromFirestore({
    String? category,
    String? search,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          FirebaseFirestore.instance.collection('products');
      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }
      final snap = await query.get();
      var docs = snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
      if (search != null && search.isNotEmpty) {
        final lower = search.toLowerCase();
        docs = docs.where((p) {
          final name = (p['productName'] ?? '').toString().toLowerCase();
          final brand = (p['brand'] ?? '').toString().toLowerCase();
          return name.contains(lower) || brand.contains(lower);
        }).toList();
      }
      return docs;
    } catch (_) {
      return [];
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('products').get();
      final cats = snap.docs
          .map((d) => d.data()['category']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      return cats;
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
