
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grad_qr_project/services/api_price_service.dart';
import 'resultPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Browse Products',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search products, brands...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF2E7D32),
                    ),
                    suffixIcon:
                        _searchCtrl.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed:
                                  () => setState(() => _searchCtrl.clear()),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<List<String>>(
                  future: ApiPriceService.getCategories(),
                  builder: (context, snapshot) {
                    List<String> cats = ['All'];
                    if (snapshot.hasData) {
                      cats.addAll(snapshot.data ?? []);
                    }
                    return SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        itemBuilder: (context, index) {
                          final cat = cats[index];
                          final selected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap:
                                () =>
                                    setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    selected
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      selected
                                          ? Colors.transparent
                                          : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.poppins(
                                  color:
                                      selected ? Colors.white : Colors.grey[700],
                                  fontWeight:
                                      selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: ApiPriceService.getAllProducts(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
                search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmpty();
                }

                var products = snapshot.data ?? [];

                if (products.isEmpty) return _buildEmpty();

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data = products[index];
                    final barcode = data['barcode']?.toString() ?? '';
                    return _ProductGridCard(data: data, barcode: barcode);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String barcode;

  const _ProductGridCard({required this.data, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final productName = data['productName']?.toString() ?? 'Unknown';
    final category = data['category']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(barcode: barcode),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child:
                    imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder:
                                (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey,
                                    size: 36,
                                  ),
                                ),
                          ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey,
                            size: 36,
                          ),
                        ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: const Color(0xFF1A1A2E),
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (category.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: const Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
