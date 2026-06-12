// ignore_for_file: file_names

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/market_api_service.dart';
import '../../services/cart_service.dart';

class ResultPage extends StatefulWidget {
  final String barcode;
  final String city;
  final Map<String, dynamic>? productData;
  final String? preferredCity;

  const ResultPage({
    super.key,
    required this.barcode,
    this.city = 'All',
    this.productData,
    this.preferredCity,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _prices = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isFavorite = false;
  bool _notFound = false;
  String _selectedCity = 'All';

  final _user = FirebaseAuth.instance.currentUser;

  static const List<String> _cities = [
    'All',
    'Nicosia',
    'Kyrenia',
    'Famagusta',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.preferredCity ?? widget.city;
    if (widget.productData != null) {
      debugPrint('ResultPage: Pre-loaded productData from favorites');
      debugPrint('Preferred city: ${widget.preferredCity}');
      _product = widget.productData;
    }
    _fetchData();
  }

  void _onCityChanged(String city) {
    setState(() {
      _selectedCity = city;
      _notFound = false;
      _isRefreshing = true;
    });
    _fetchData(isRefresh: true);
  }

Future<void> _fetchData({bool isRefresh = false}) async {
    if (!mounted) return;
    if (!isRefresh) setState(() => _isLoading = true);

    final cleanBarcode = widget.barcode.trim();
    debugPrint('===== ResultPage._fetchData START =====');
    debugPrint('Barcode: $cleanBarcode (length: ${cleanBarcode.length})');
    debugPrint('Selected City: $_selectedCity');
    debugPrint('Widget City: ${widget.city}');

    try {
      debugPrint('Calling MarketApiService.searchProductInCity...');
      final baseUrl = await MarketApiService.getBaseUrl();
      debugPrint('Base URL: $baseUrl');

      final cityResults = await MarketApiService.searchProductInCity(
        cleanBarcode,
        _selectedCity,
      );
      debugPrint('API Results count: ${cityResults.length}');
      if (cityResults.isNotEmpty) {
        for (final result in cityResults) {
          debugPrint('  - Market: ${result.marketName}, Price: ${result.price}, Barcode: ${result.barcode}');
        }
      } else {
        debugPrint('API returned empty results for barcode: $cleanBarcode, city: $_selectedCity');
      }

      if (cityResults.isNotEmpty) {
        FirebaseFirestore.instance.collection('scanLogs').add({
          'barcode': cleanBarcode,
          'productName': cityResults.first.name,
          'city': _selectedCity,
          'userEmail': _user?.email ?? 'guest',
          'userId': _user?.uid ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        });

        bool isFav = false;
        if (_user != null) {
          final favDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user.uid)
                  .collection('favorites')
                  .doc(cleanBarcode)
                  .get();
          isFav = favDoc.exists;
        }
        if (mounted) {
          final firebaseProduct = await FirebaseFirestore.instance
              .collection('products')
              .doc(cleanBarcode)
              .get();

          String realImageUrl = cityResults.first.photoUrl;
          String brand = '';
          String category = '';

          if (firebaseProduct.exists) {
            final data = firebaseProduct.data()!;
            realImageUrl = data['imageUrl'] ?? realImageUrl;
            brand = data['brand'] ?? '';
            category = data['category'] ?? '';
          }

          setState(() {
            _product = {
              'productName': cityResults.first.name,
              'brand': brand,
              'category': category,
              'imageUrl': realImageUrl,
            };
            final priceList =
                cityResults
                    .map(
                      (r) => {
                        'marketName': r.marketName,
                        'marketLogoUrl': '',
                        'price': r.price,
                        'discountPrice': r.discountPrice,
                        'currency': 'TRY',
                      },
                    )
                    .toList();
            priceList.sort((a, b) {
              final aEff = (a['discountPrice'] != null
                      ? double.tryParse(a['discountPrice'].toString())
                      : null) ??
                  (double.tryParse(a['price'].toString()) ?? 0.0);
              final bEff = (b['discountPrice'] != null
                      ? double.tryParse(b['discountPrice'].toString())
                      : null) ??
                  (double.tryParse(b['price'].toString()) ?? 0.0);
              return aEff.compareTo(bEff);
            });
            _prices = priceList;
            _isFavorite = isFav;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
        return;
      }

      if (_product != null) {
        debugPrint('API returned no results, but product data already loaded from favorites');
        if (mounted) {
          setState(() {
            _prices = [];
            _isLoading = false;
            _isRefreshing = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _notFound = true;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('ResultPage error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _showQuantityDialog(String marketName, double price, double? discountPrice, String currency) {
    int qty = 1;
    final displayPrice = discountPrice ?? price;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: Text('Select Quantity', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(onPressed: () => setState(() => qty = max(1, qty - 1)), icon: const Icon(Icons.remove)),
                  Text('$qty', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add)),
                ],
              ),
              const SizedBox(height: 16),
              if (discountPrice != null)
                Column(
                  children: [
                    Text(
                      '${(price * qty).toStringAsFixed(2)} $currency',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(discountPrice * qty).toStringAsFixed(2)} $currency',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '${(displayPrice * qty).toStringAsFixed(2)} $currency',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                cartService.addItem(CartItem(
                  barcode: widget.barcode,
                  productName: _product!['productName'] ?? 'Unknown',
                  marketName: marketName,
                  price: price,
                  discountPrice: discountPrice,
                  currency: currency,
                  city: _selectedCity,
                  imageUrl: _product!['imageUrl'] ?? '',
                  quantity: qty,
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added $qty item(s) to cart', style: GoogleFonts.poppins()), backgroundColor: const Color(0xFF2E7D32), duration: const Duration(seconds: 2)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_user == null || _product == null) return;

    final cleanBarcode = widget.barcode.trim();
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorites')
        .doc(cleanBarcode);

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await ref.set({
        'barcode': cleanBarcode,
        'productName': _product!['productName'] ?? '',
        'category': _product!['category'] ?? '',
        'brand': _product!['brand'] ?? '',
        'imageUrl': _product!['imageUrl'] ?? '',
        'city': _selectedCity,
        'savedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added to favorites', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _ShimmerLoading()),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _notFound) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1A1A2E),
                size: 18,
              ),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Color(0xFFE53935),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Product Not Found',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _notFound
                      ? 'This barcode is not in our database yet.\nTry selecting a different city.'
                      : _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Barcode: ${widget.barcode}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _CitySelector(
                  selected: _selectedCity,
                  cities: _cities,
                  onChanged: _onCityChanged,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text('Go Back', style: GoogleFonts.poppins()),
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)]),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A2E), size: 18),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 72, color: Color(0xFFE53935)),
              const SizedBox(height: 16),
              Text('Product Not Found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final imageUrl = _product!['imageUrl']?.toString() ?? '';
    final productName = _product!['productName']?.toString() ?? 'Unknown';
    final category = _product!['category']?.toString() ?? '';
    final brand = _product!['brand']?.toString() ?? '';

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF1A1A2E),
                      size: 18,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                            _isFavorite
                                ? const Color(0xFFE53935)
                                : const Color(0xFF1A1A2E),
                        size: 22,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        SizedBox(
                          height: 150,
                          width: 150,
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (_, __, ___) => const Icon(
                                          Icons.shopping_bag_outlined,
                                          size: 80,
                                          color: Colors.grey,
                                        ),
                                  )
                                  : const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            'Barcode: ${widget.barcode}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        productName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      if (brand.isNotEmpty)
                        Text(
                          brand,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Price Comparison',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_prices.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_prices.length} stores',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      _CitySelector(
                        selected: _selectedCity,
                        cities: _cities,
                        onChanged: _onCityChanged,
                      ),
                    ],
                  ),
                ),
              ),
              if (_prices.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final priceData = _prices[index];
                        return _buildPriceCard(
                          priceData,
                          index == 0,
                        );
                      },
                      childCount: _prices.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No price data available for this product.',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isRefreshing)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Updating prices...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> priceData, bool isBest) {
    final price = double.tryParse(priceData['price'].toString()) ?? 0.0;
    final discountPrice = priceData['discountPrice'] != null
        ? double.tryParse(priceData['discountPrice'].toString())
        : null;
    final effectivePrice = discountPrice ?? price;
    final currency = priceData['currency'] ?? 'TRY';
    final marketName = priceData['marketName'] ?? 'Unknown Market';
    final logoUrl = priceData['marketLogoUrl']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _showQuantityDialog(marketName, price, discountPrice, currency),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isBest ? Border.all(color: const Color(0xFF2E7D32), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: isBest
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Market icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isBest ? const Color(0xFFE8F5E9) : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: logoUrl.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.store_rounded,
                          color: isBest ? const Color(0xFF2E7D32) : Colors.grey,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.store_rounded,
                      color: isBest ? const Color(0xFF2E7D32) : Colors.grey,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Market name + best deal badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    marketName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (isBest)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🏆 Best Deal',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Price + Add to Cart
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (discountPrice != null)
                  Text(
                    '${price.toStringAsFixed(2)} $currency',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '${effectivePrice.toStringAsFixed(2)} $currency',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: discountPrice != null
                        ? const Color(0xFFE53935)
                        : isBest
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Add to Cart',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySelector extends StatelessWidget {
  final String selected;
  final List<String> cities;
  final ValueChanged<String> onChanged;

  const _CitySelector({
    required this.selected,
    required this.cities,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder:
                (ctx) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select City',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...cities.map(
                        (city) => ListTile(
                          onTap: () {
                            Navigator.pop(ctx);
                            onChanged(city);
                          },
                          title: Text(
                            city,
                            style: GoogleFonts.poppins(fontSize: 15),
                          ),
                          trailing:
                              selected == city
                                  ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF2E7D32),
                                  )
                                  : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selectedTileColor: const Color(0xFFE8F5E9),
                          selected: selected == city,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
          ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, size: 13, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              selected,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatefulWidget {
  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder:
          (_, __) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: double.infinity, height: 220, radius: 16),
                const SizedBox(height: 20),
                _shimmerBox(width: 100, height: 24, radius: 8),
                const SizedBox(height: 10),
                _shimmerBox(width: double.infinity, height: 32, radius: 8),
                const SizedBox(height: 8),
                _shimmerBox(width: 160, height: 20, radius: 6),
                const SizedBox(height: 28),
                _shimmerBox(width: 180, height: 24, radius: 8),
                const SizedBox(height: 14),
                _shimmerBox(width: double.infinity, height: 80, radius: 16),
                const SizedBox(height: 12),
                _shimmerBox(width: double.infinity, height: 80, radius: 16),
                const SizedBox(height: 12),
                _shimmerBox(width: double.infinity, height: 80, radius: 16),
              ],
            ),
          ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value, 0),
          colors: const [
            Color(0xFFE8E8E8),
            Color(0xFFF5F5F5),
            Color(0xFFE8E8E8),
          ],
        ),
      ),
    );
  }
}
