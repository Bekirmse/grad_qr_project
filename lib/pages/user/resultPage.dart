import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/price_model.dart';
import '../../services/product_service.dart';

class ResultPage extends StatefulWidget {
  final String barcode;

  const ResultPage({super.key, required this.barcode});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final ProductService _productService = ProductService();

  Product? _product;
  List<Price>? _prices;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // 1. Ürün bilgisini çek
    Product? product = await _productService.getProduct(widget.barcode);

    if (product == null) {
      if (mounted) {
        setState(() {
          // GÜNCELLENEN KISIM: Barkod numarasını mesajın içine ekledik (\n ile alt satıra geçtik)
          _errorMessage = "Ürün bulunamadı!\nBarkod: ${widget.barcode}";
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Fiyatları çek
    List<Price> prices = await _productService.getPricesForProduct(
      widget.barcode,
    );

    if (mounted) {
      setState(() {
        _product = product;
        _prices = prices;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yükleniyor durumu
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
      );
    }

    // Hata durumu
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
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center, // Metni ortaladık
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Başarılı durum (Sizin Tasarımınız)
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black),
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
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Ürün Resmi Alanı
                  Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      // Resim varsa göster, yoksa ikon göster
                      image:
                          _product!.imageUrl.isNotEmpty
                              ? DecorationImage(
                                image: NetworkImage(_product!.imageUrl),
                                fit: BoxFit.contain,
                              )
                              : null,
                    ),
                    child:
                        _product!.imageUrl.isEmpty
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
                    _product!.productName,
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
                    'Barcode: ${_product!.barcode}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Kategori Etiketi
                  if (_product!.category.isNotEmpty)
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
                        _product!.category,
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

            // Başlık: Fiyat Karşılaştırma
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

            // Dinamik Fiyat Listesi
            if (_prices != null && _prices!.isNotEmpty)
              ListView.builder(
                shrinkWrap: true, // ScrollView içinde olduğu için gerekli
                physics:
                    const NeverScrollableScrollPhysics(), // Ana scroll çalışsın diye
                itemCount: _prices!.length,
                itemBuilder: (context, index) {
                  final priceData = _prices![index];
                  // Listeyi zaten ucuzdan pahalıya sıralamıştık, ilk eleman en ucuzdur.
                  final bool isBestPrice = index == 0;

                  return _buildPriceCard(priceData, isBestPrice);
                },
              )
            else
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Bu ürün için fiyat bilgisi bulunamadı."),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // Alt Buton
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Sepete ekleme işlemi buraya gelecek
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Shopping list feature coming soon!"),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add to Shopping List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // Fiyat Kartı Widget'ı (Veri Modelini Alacak Şekilde Güncellendi)
  Widget _buildPriceCard(Price priceData, bool isBestPrice) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isBestPrice
                ? Border.all(color: const Color(0xFF2E7D32), width: 2)
                : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Market Logosu Alanı
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBestPrice ? const Color(0xFFE8F5E9) : Colors.grey[100],
              shape: BoxShape.circle,
              image:
                  (priceData.marketLogoUrl != null &&
                          priceData.marketLogoUrl!.isNotEmpty)
                      ? DecorationImage(
                        image: NetworkImage(priceData.marketLogoUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            // Logo yoksa ikon göster
            child:
                (priceData.marketLogoUrl == null ||
                        priceData.marketLogoUrl!.isEmpty)
                    ? Icon(
                      Icons.store_mall_directory_rounded,
                      color:
                          isBestPrice ? const Color(0xFF2E7D32) : Colors.grey,
                    )
                    : null,
          ),
          const SizedBox(width: 16),

          // Market İsmi ve Etiket
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceData.marketName ?? "Unknown Market",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isBestPrice)
                  const Text(
                    'Best Deal!',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Fiyat
          Text(
            '${priceData.price.toStringAsFixed(2)} ${priceData.currency}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isBestPrice ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
