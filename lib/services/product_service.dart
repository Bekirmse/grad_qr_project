import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../models/supermarket_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Product?> getProduct(String barcode) async {
    try {
      var snapshot =
          await _firestore
              .collection('products')
              .where('barcode', isEqualTo: barcode)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return Product.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Ürün çekme hatası: $e");
      }
      return null;
    }
  }

  Future<List<Price>> getPricesForProduct(String barcode) async {
    try {
      List<Price> pricesList = [];

      var priceSnapshot =
          await _firestore
              .collection('prices')
              .where('productBarcode', isEqualTo: barcode)
              .get();

      for (var doc in priceSnapshot.docs) {
        Price priceObj = Price.fromMap(doc.data());

        var marketSnapshot =
            await _firestore
                .collection('supermarkets')
                .where('marketId', isEqualTo: priceObj.marketId)
                .limit(1)
                .get();

        if (marketSnapshot.docs.isNotEmpty) {
          Supermarket market = Supermarket.fromMap(
            marketSnapshot.docs.first.data(),
          );
          priceObj.marketName = market.name;
          priceObj.marketLogoUrl = market.logoUrl;
        } else {
          priceObj.marketName = "Bilinmeyen Market";
        }

        pricesList.add(priceObj);
      }

      pricesList.sort((a, b) => a.price.compareTo(b.price));

      return pricesList;
    } catch (e) {
      if (kDebugMode) {
        print("Fiyat listesi hatası: $e");
      }
      return [];
    }
  }
}
