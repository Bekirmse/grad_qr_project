// ignore_for_file: file_names

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_price_service.dart';

class ResultPage extends StatefulWidget {
  final String barcode;

  const ResultPage({super.key, required this.barcode});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Map<String, dynamic>? _product;
  List<Map<String, dynamic>> _prices = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final cleanBarcode = widget.barcode.trim();

    try {
      final apiResult = await ApiPriceService.getProductWithPrices(cleanBarcode);

      if (apiResult != null) {
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
          setState(() {
            _product = {
              'productName': apiResult['productName'],
              'brand': apiResult['brand'],
              'category': apiResult['category'],
              'imageUrl': apiResult['imageUrl'],
            };
            _prices = List<Map<String, dynamic>>.from(apiResult['prices']);
            _isFavorite = isFav;
            _isLoading = false;
          });
        }
        return;
      }

      final productDoc =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(cleanBarcode)
              .get();

      if (!productDoc.exists) {
        if (mounted) Navigator.pop(context, 'not_found');
        return;
      }

      final priceSnapshot =
          await FirebaseFirestore.instance
              .collection('prices')
              .where('productBarcode', isEqualTo: cleanBarcode)
              .orderBy('price')
              .get();

      final List<Map<String, dynamic>> tempPrices = [];
      for (final doc in priceSnapshot.docs) {
        final priceData = Map<String, dynamic>.from(doc.data());
        final marketId = priceData['marketId'] ?? '';
        if (marketId.isNotEmpty) {
          final marketDoc =
              await FirebaseFirestore.instance
                  .collection('supermarkets')
                  .doc(marketId)
                  .get();
          if (marketDoc.exists) {
            final m = marketDoc.data() as Map<String, dynamic>;
            priceData['marketName'] = m['name'];
            priceData['marketLogoUrl'] = m['logoUrl'];
          } else {
            priceData['marketName'] = 'Unknown Market';
          }
        }
        tempPrices.add(priceData);
      }

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
        setState(() {
          _product = productDoc.data() as Map<String, dynamic>;
          _prices = tempPrices;
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('ResultPage error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_user == null || _product == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('favorites')
        .doc(widget.barcode);

    setState(() => _isFavorite = !_isFavorite);

    if (_isFavorite) {
      await ref.set({
        'productName': _product!['productName'] ?? '',
        'category': _product!['category'] ?? '',
        'brand': _product!['brand'] ?? '',
        'imageUrl': _product!['imageUrl'] ?? '',
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
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    final imageUrl = _product!['imageUrl']?.toString() ?? '';
    final productName = _product!['productName']?.toString() ?? 'Unknown';
    final category = _product!['category']?.toString() ?? '';
    final brand = _product!['brand']?.toString() ?? '';

    return Scaffold(
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
                ],
              ),
            ),
          ),
          if (_prices.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildPriceCard(_prices[index], index == 0),
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
    );
  }

  Widget _buildPriceCard(Map<String, dynamic> priceData, bool isBest) {
    final price = double.tryParse(priceData['price'].toString()) ?? 0.0;
    final currency = priceData['currency'] ?? 'TRY';
    final marketName = priceData['marketName'] ?? 'Unknown Market';
    final logoUrl = priceData['marketLogoUrl']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            isBest
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color:
                isBest
                    ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color:
                  isBest
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF5F7FA),
              shape: BoxShape.circle,
            ),
            child:
                logoUrl.isNotEmpty
                    ? ClipOval(
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Icon(
                              Icons.store_rounded,
                              color:
                                  isBest
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey,
                              size: 26,
                            ),
                      ),
                    )
                    : Icon(
                      Icons.store_rounded,
                      color:
                          isBest ? const Color(0xFF2E7D32) : Colors.grey,
                      size: 26,
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marketName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if (isBest)
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
                    child: Text(
                      'Best Deal',
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
          Text(
            '${price.toStringAsFixed(2)} $currency',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:
                  isBest
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}
