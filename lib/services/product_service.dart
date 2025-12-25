import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../models/supermarket_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Ürün Detayını Getir
  Future<Product?> getProduct(String barcode) async {
    try {
      // 'products' koleksiyonunda barcode alanı eşleşen dokümanı bul
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
      print("Ürün çekme hatası: $e");
      return null;
    }
  }

  // 2. Fiyatları ve Market Bilgilerini Getir (JOIN İşlemi)
  Future<List<Price>> getPricesForProduct(String barcode) async {
    try {
      List<Price> pricesList = [];

      // A. 'prices' tablosundan bu barkoda ait fiyatları çek
      var priceSnapshot =
          await _firestore
              .collection('prices')
              .where('productBarcode', isEqualTo: barcode)
              .get();

      // B. Her bir fiyat için market ismini bulmamız lazım
      for (var doc in priceSnapshot.docs) {
        Price priceObj = Price.fromMap(doc.data());

        // C. 'supermarkets' tablosuna git ve marketId ile market adını bul
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
          // Fiyat objesine market ismini ve logosunu ekle
          priceObj.marketName = market.name;
          priceObj.marketLogoUrl = market.logoUrl;
        } else {
          priceObj.marketName = "Bilinmeyen Market";
        }

        pricesList.add(priceObj);
      }

      // D. Fiyatları ucuzdan pahalıya sırala (Sort)
      pricesList.sort((a, b) => a.price.compareTo(b.price));

      return pricesList;
    } catch (e) {
      print("Fiyat listesi hatası: $e");
      return [];
    }
  }
}
