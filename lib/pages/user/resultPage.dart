// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultPage extends StatefulWidget {
  final String barcode;

  const ResultPage({super.key, required this.barcode});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>>? _prices;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("🔴 DEBUG: ResultPage başlatıldı: ${widget.barcode}");
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    String cleanBarcode = widget.barcode.trim();

    try {
      // 1. ÜRÜN SORGUSU
      DocumentSnapshot productDoc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(cleanBarcode)
              .get();

      // --- NAVİGASYON MANTIĞI (ScanPage ile uyumlu) ---
      if (!productDoc.exists) {
        if (kDebugMode) {
          print("🔴 DEBUG: Ürün bulunamadı. 'not_found' sinyali gönderiliyor.");
        }
        if (mounted) {
          // Sayfayı kapat ve 'not_found' döndür (ScanPage bunu yakalayacak)
          Navigator.pop(context, 'not_found');
        }
        return;
      }
      // ------------------------------------------------

      // 2. FİYAT SORGUSU (En ucuzdan pahalıya sıralı)
      QuerySnapshot priceSnapshot =
          await FirebaseFirestore.instance
              .collection('prices')
              .where('productBarcode', isEqualTo: cleanBarcode)
              .orderBy('price')
              .get();

      // 3. MARKET BİLGİLERİNİ EŞLEŞTİRME
      List<Map<String, dynamic>> tempPrices = [];

      for (var doc in priceSnapshot.docs) {
        var priceData = doc.data() as Map<String, dynamic>;
        String marketId = priceData['marketId'] ?? '';

        if (marketId.isNotEmpty) {
          var marketDoc =
              await FirebaseFirestore.instance
                  .collection('supermarkets')
                  .doc(marketId)
                  .get();

          if (marketDoc.exists) {
            var marketData = marketDoc.data() as Map<String, dynamic>;
            priceData['marketName'] = marketData['name'];
            priceData['marketLogoUrl'] = marketData['logoUrl'];
          } else {
            priceData['marketName'] = "Unknown Market";
          }
        }
        tempPrices.add(priceData);
      }

      if (mounted) {
        setState(() {
          _product = productDoc.data() as Map<String, dynamic>;
          _prices = tempPrices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("🔴 DEBUG: HATA: $e");
      }
      if (mounted) {
        setState(() {
          _errorMessage = "Sistem hatası: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- ÜRÜN BİLGİ KARTI ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Ürün Resmi
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      image:
                          (_product!['imageUrl'] != null &&
                                  _product!['imageUrl'].toString().isNotEmpty)
                              ? DecorationImage(
                                image: NetworkImage(_product!['imageUrl']),
                                fit: BoxFit.contain,
                              )
                              : null,
                    ),
                    child:
                        (_product!['imageUrl'] == null ||
                                _product!['imageUrl'].toString().isEmpty)
                            ? const Icon(
                              Icons.shopping_bag,
                              size: 80,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(height: 20),

                  // Ürün İsmi
                  Text(
                    _product!['productName'] ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Barkod
                  Text(
                    'Barcode: ${widget.barcode}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 12),

                  // Kategori Chip
                  if (_product!['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _product!['category'],
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- FİYAT LİSTESİ BAŞLIĞI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Price Comparison',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- FİYAT LİSTESİ ---
            if (_prices != null && _prices!.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _prices!.length,
                itemBuilder: (context, index) {
                  final priceData = _prices![index];

                  // Liste fiyata göre sıralı geldiği için ilk eleman (index 0) en ucuzdur.
                  final bool isBestPrice = index == 0;

                  return _buildPriceCard(priceData, isBestPrice);
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No prices found for this product."),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- GELİŞMİŞ FİYAT KARTI TASARIMI ---
  Widget _buildPriceCard(Map<String, dynamic> priceData, bool isBestPrice) {
    double price = double.tryParse(priceData['price'].toString()) ?? 0.0;
    String currency = priceData['currency'] ?? 'TRY';
    String marketName = priceData['marketName'] ?? 'Unknown Market';
    String? logoUrl = priceData['marketLogoUrl'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // En ucuzsa yeşil çerçeve, değilse şeffaf
        border:
            isBestPrice
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // MARKET LOGOSU
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBestPrice ? const Color(0xFFE8F5E9) : Colors.grey[100],
              shape: BoxShape.circle,
              image:
                  (logoUrl != null && logoUrl.isNotEmpty)
                      ? DecorationImage(
                        image: NetworkImage(logoUrl),
                        fit: BoxFit.contain, // Logoyu sığdır
                      )
                      : null,
            ),
            child:
                (logoUrl == null || logoUrl.isEmpty)
                    ? Icon(
                      Icons.store_mall_directory_rounded,
                      color:
                          isBestPrice ? const Color(0xFF2E7D32) : Colors.grey,
                    )
                    : null,
          ),

          const SizedBox(width: 16),

          // MARKET ADI VE 'BEST DEAL' ROZETİ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marketName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isBestPrice)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Best Deal!',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // FİYAT METNİ
          Text(
            '${price.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              // En ucuzsa yeşil, değilse siyah
              color: isBestPrice ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
