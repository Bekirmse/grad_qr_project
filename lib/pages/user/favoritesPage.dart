// ignore: duplicate_ignore
// ignore: file_names
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grad_qr_project/services/market_api_service.dart';
import 'resultPage.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Favorites',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          user == null
              ? _buildEmptyState(
                icon: Icons.person_off_outlined,
                title: 'Not logged in',
                subtitle: 'Please log in to see your favorites',
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('favorites')
                        .orderBy('savedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No favorites yet',
                      subtitle:
                          'Tap the heart icon on any product\nto save it here',
                    );
                  }

                  final favDocs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: favDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          favDocs[index].data() as Map<String, dynamic>;
                      final barcode = favDocs[index].id.trim();

                      debugPrint('===== FavoritesPage Item =====');
                      debugPrint('>>> BARCODE TO OPEN: $barcode <<<');
                      debugPrint('Document ID (Barcode): "$barcode" (length: ${barcode.length})');
                      debugPrint('ProductName: ${data['productName']}');
                      debugPrint('Full Data: $data');

                      return _FavoriteCard(
                        barcode: barcode,
                        data: data,
                        userId: user.uid,
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: const Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> data;
  final String userId;

  const _FavoriteCard({
    required this.barcode,
    required this.data,
    required this.userId,
  });

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard> {
  late Future<(String, bool)> _productInfoFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 initState called for barcode: ${widget.barcode}');
    _productInfoFuture = _getProductInfo();
    debugPrint('🟢 _productInfoFuture assigned');
  }

  Future<void> _removeFavorite(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('favorites')
        .doc(widget.barcode)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<(String, bool)> _getProductInfo() async {
    var localImageUrl = widget.data['imageUrl']?.toString() ?? '';
    debugPrint('🖼️ FavoriteCard[${widget.barcode}] localImageUrl: "$localImageUrl"');

    if (localImageUrl.contains('via.placeholder')) {
      debugPrint('🖼️ FavoriteCard[${widget.barcode}] placeholder URL detected, fetching real from Firebase');
      try {
        final firebaseProduct = await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.barcode)
            .get();
        if (firebaseProduct.exists) {
          final realUrl = firebaseProduct.data()?['imageUrl'] ?? '';
          if (realUrl.isNotEmpty) {
            localImageUrl = realUrl;
            debugPrint('🖼️ FavoriteCard[${widget.barcode}] got real URL from Firebase: "$localImageUrl"');
          }
        }
      } catch (e) {
        debugPrint('🖼️ FavoriteCard[${widget.barcode}] error fetching from Firebase: $e');
      }
    }

    if (localImageUrl.isNotEmpty && !localImageUrl.contains('via.placeholder')) {
      try {
        final results = await MarketApiService.searchProductInCity(widget.barcode, 'All');
        final hasDiscount = results.isNotEmpty && results.any((r) => r.discountPrice != null && r.discountPrice! < r.price);
        debugPrint('🖼️ FavoriteCard[${widget.barcode}] found discount: $hasDiscount');
        return (localImageUrl, hasDiscount);
      } catch (e) {
        debugPrint('🖼️ FavoriteCard[${widget.barcode}] error checking discount: $e');
        return (localImageUrl, false);
      }
    }

    debugPrint('🖼️ FavoriteCard[${widget.barcode}] local URL empty or still placeholder, fetching from API');
    try {
      final results = await MarketApiService.searchProductInCity(widget.barcode, 'All');
      if (results.isNotEmpty) {
        final photoUrl = results.first.photoUrl;
        final hasDiscount = results.any((r) => r.discountPrice != null && r.discountPrice! < r.price);
        debugPrint('🖼️ FavoriteCard[${widget.barcode}] API photoUrl: "$photoUrl", hasDiscount: $hasDiscount');
        return (photoUrl.isNotEmpty ? photoUrl : localImageUrl, hasDiscount);
      }
    } catch (e) {
      debugPrint('🖼️ FavoriteCard[${widget.barcode}] Error fetching from API: $e');
    }

    debugPrint('🖼️ FavoriteCard[${widget.barcode}] returning empty URL');
    return (localImageUrl, false);
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.data['productName']?.toString() ?? 'Unknown Product';
    final category = widget.data['category']?.toString() ?? '';
    final brand = widget.data['brand']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                barcode: widget.barcode,
                productData: widget.data,
                preferredCity: (widget.data['city'] as String?) ?? 'All',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FutureBuilder<(String, bool)>(
                future: _productInfoFuture,
                builder: (context, snapshot) {
                  final photoUrl = snapshot.data?.$1 ?? '';
                  final hasDiscount = snapshot.data?.$2 ?? false;
                  final isLoading = snapshot.connectionState == ConnectionState.waiting;

                  debugPrint('🔵 FutureBuilder builder: photoUrl="$photoUrl", hasDiscount=$hasDiscount, isLoading=$isLoading');

                  return Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: isLoading
                            ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Color(0xFF2E7D32)),
                                ),
                              ),
                            )
                            : (photoUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    photoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.grey,
                                  size: 30,
                                )),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DISCOUNT',
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (brand.isNotEmpty)
                      Text(
                        brand,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _removeFavorite(context),
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE53935),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
