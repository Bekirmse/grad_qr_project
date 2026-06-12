import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeed {
  static final _db = FirebaseFirestore.instance;

  static Future<void> run() async {
    await _seedCategories();
    await _seedProducts();
  }

  static Future<void> _seedCategories() async {
    final categories = ['Beverages', 'Snacks', 'Food', 'Dairy'];
    final col = _db.collection('categories');

    final existing = await col.get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    for (final name in categories) {
      await col.add({'name': name});
    }


  }

  static Future<void> _seedProducts() async {
    final col = _db.collection('products');

    final existing = await col.get();
    for (var doc in existing.docs) {
      await doc.reference.delete();
    }

    final products = [
      {
        'barcode': '8692005190019',
        'productName': 'KOOP Süt 1L Tam Yağlı',
        'category': 'Dairy',
        'brand': 'KOOP',
        'imageUrl':
            'https://www.kibrissanalmarket.com/wp-content/uploads/2021/08/8692005190019-1.jpg',
        'description': '1 litre tam yağlı pastörize süt.',
      },
      {
        'barcode': '5449000000996',
        'productName': 'Coca-Cola 330ML',
        'category': 'Beverages',
        'brand': 'Coca-Cola',
        'imageUrl':
            'https://www.torontopizza.com.cy/menu/menu/404-large_default/coca-cola.jpg',
        'description': '330ml kutu Coca-Cola.',
      },
      {
        'barcode': '5449000003102',
        'productName': 'Fanta 330ml',
        'category': 'Beverages',
        'brand': 'Fanta',
        'imageUrl':
            'https://images.migrosone.com/sanalmarket/product/08020000/08020000_1-c20362.jpg',
        'description': '330ml kutu Fanta portakal.',
      },
      {
        'barcode': '8690526095417',
        'productName': 'Eti Karam Gurme 50GR',
        'category': 'Snacks',
        'brand': 'Eti',
        'imageUrl':
            'https://images.migrosone.com/macrocenter/product/07160817/7160817-b58034.jpg',
        'description': '50gr Eti Karam Gurme bitter çikolata.',
      },
      {
        'barcode': '8690624105650',
        'productName': 'Filiz Spagetti Makarna 500G',
        'category': 'Food',
        'brand': 'Filiz',
        'imageUrl':
            'https://foodexfoodco.com/storage/uploads/products/5030356-59bd01-1650x1650_500x500.jpg',
        'description': '500gr Filiz spagetti makarna.',
      },
      {
        'barcode': '5053990127740',
        'productName': 'Pringles Sour Cream & Onion 165GR',
        'category': 'Snacks',
        'brand': 'Pringles',
        'imageUrl':
            'https://images.kglobalservices.com/www.pringles.com_ie/en_ie/product/product_6598150/prod_img-6598524_pringles-sour-cream-amp-onion-200g.png',
        'description': '165gr Pringles ekşi krema soğan.',
      },
      {
        'barcode': '8690526011073',
        'productName': 'Eti Tutku',
        'category': 'Snacks',
        'brand': 'Eti',
        'imageUrl':
            'https://images.migrosone.com/sanalmarket/product/7010979/7010979-37b062-1650x1650.jpg',
        'description': 'Eti Tutku çikolatalı bisküvi.',
      },
      {
        'barcode': '8690504020509',
        'productName': 'Ülker Çikolatalı Gofret 36GR',
        'category': 'Snacks',
        'brand': 'Ülker',
        'imageUrl':
            'https://images.migrosone.com/sanalmarket/product/07167716/7167716-c711c5-1650x1650.jpg',
        'description': '36gr Ülker çikolatalı gofret.',
      },
      {
        'barcode': '8690632031231',
        'productName': 'Nescafe Gold 100GR',
        'category': 'Beverages',
        'brand': 'Nescafe',
        'imageUrl':
            'https://images.migrosone.com/macrocenter/product/03231301/3231301_1-cbcfab.jpg',
        'description': '100gr Nescafe Gold çözünür kahve.',
      },
      {
        'barcode': '9002490100070',
        'productName': 'Redbull Energy Drink 250ML',
        'category': 'Beverages',
        'brand': 'Red Bull',
        'imageUrl':
            'https://images.migrosone.com/sanalmarket/product/08110030/08110030-a4b666-1650x1650.png',
        'description': '250ml Red Bull enerji içeceği.',
      },
      {
        'barcode': '8694997019118',
        'productName': 'Icy 0.5L Su',
        'category': 'Beverages',
        'brand': 'Icy',
        'imageUrl':
            'https://www.icysu.com/uploads/images/0-5-lt-icy-su-8299.jpg',
        'description': '500ml Icy doğal kaynak suyu.',
      },
    ];

    final productsCol = _db.collection('products');

    for (final p in products) {
      final barcode = p['barcode'] as String;
      await productsCol.doc(barcode).set(p, SetOptions(merge: true));
    }
  }
}
