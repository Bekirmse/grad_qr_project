import 'package:flutter/material.dart';

class CartItem {
  final String barcode;
  final String productName;
  final String marketName;
  final double price;
  final double? discountPrice;
  final String currency;
  final String city;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.barcode,
    required this.productName,
    required this.marketName,
    required this.price,
    required this.currency,
    required this.city,
    required this.imageUrl,
    this.discountPrice,
    this.quantity = 1,
  });
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total => _items.fold(0, (sum, item) {
    final price = item.discountPrice ?? item.price;
    return sum + (price * item.quantity);
  });

  void addItem(CartItem item) {
    try {
      final existing = _items.firstWhere(
        (i) => i.barcode == item.barcode && i.marketName == item.marketName,
      );
      existing.quantity += item.quantity;
    } catch (_) {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String barcode, String marketName) {
    _items.removeWhere((i) => i.barcode == barcode && i.marketName == marketName);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

final cartService = CartService();
