// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _onMenuSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // _AdminDashboardState sınıfı içindeki build metodunu şu şekilde güncelleyin:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SideMenu(selectedIndex: _selectedIndex, onMenuClick: _onMenuSelect),
          Expanded(
            child: Column(
              children: [
                const _Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Değişiklik BURADA: Seçili indekse göre widget gösterimi
                        if (_selectedIndex == 0) const _DashboardOverview(),
                        if (_selectedIndex == 1) const _AddProductForm(),
                        if (_selectedIndex == 2) const _UserManagementList(),
                        if (_selectedIndex == 3) const _ProductMaintenance(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ADD PRODUCT FORM (FULL DYNAMIC & INDEPENDENT VALIDATION) ---
class _AddProductForm extends StatefulWidget {
  const _AddProductForm();

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  // FORM KEYLERİ
  final _marketFormKey = GlobalKey<FormState>();
  final _productFormKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PRODUCT CONTROLLERS
  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // MARKET CONTROLLERS
  final _newMarketNameCtrl = TextEditingController();
  final _newMarketLogoCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedMarketId;

  bool _isMarketLoading = false;
  bool _isProductLoading = false;

  // ================== EXCEL IMPORT ==================
  Future<void> _importFromExcel() async {
    // Mevcut kategorileri cache'e alıyoruz
    final Set<String> existingCategories = {};
    final categorySnapshot = await _firestore.collection('categories').get();

    for (var doc in categorySnapshot.docs) {
      existingCategories.add(doc['name'].toString().toLowerCase());
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      if (result == null) return;

      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;

      final marketMap = await _loadMarketMap();
      WriteBatch batch = _firestore.batch();
      int successCount = 0;

      final markets = [
        "Dima",
        "Erülkü Süpermarket",
        "Kiler",
        "Macro Supermarket",
        "Şokmar",
      ];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        final barcode = row[0]?.value?.toString().trim() ?? "";
        if (barcode.isEmpty) continue;

        final productName = row[1]?.value?.toString() ?? "";
        final category = row[2]?.value?.toString() ?? "";
        final brand = row[3]?.value?.toString() ?? "";
        final imageUrl = row[4]?.value?.toString() ?? "";

        final normalizedCategory = category.trim();
        final categoryKey = normalizedCategory.toLowerCase();

        // Eğer category Firestore'da yoksa otomatik oluştur
        if (normalizedCategory.isNotEmpty &&
            !existingCategories.contains(categoryKey)) {
          final categoryId = normalizedCategory
              .toLowerCase()
              .replaceAll(' ', '_')
              .replaceAll(RegExp(r'[^\w_]'), '');

          batch.set(_firestore.collection('categories').doc(categoryId), {
            'name': normalizedCategory,
            'createdAt': FieldValue.serverTimestamp(),
          });

          existingCategories.add(categoryKey);
        }

        // PRODUCT
        final productRef = _firestore.collection('products').doc(barcode);
        batch.set(productRef, {
          'barcode': barcode,
          'productName': productName,
          'category': category,
          'brand': brand,
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // PRICES
        for (int m = 0; m < markets.length; m++) {
          final cell = row.length > 5 + m ? row[5 + m] : null;
          if (cell == null || cell.value == null) continue;

          final price =
              double.tryParse(cell.value.toString().replaceAll(',', '.')) ?? 0;
          if (price <= 0) continue;

          final marketId = marketMap[markets[m]];
          if (marketId == null) continue;

          final priceRef = _firestore
              .collection('prices')
              .doc("${barcode}_$marketId");

          batch.set(priceRef, {
            'productBarcode': barcode,
            'marketId': marketId,
            'price': price,
            'currency': 'TRY',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          successCount++;
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$successCount fiyat kaydı eklendi"),
            backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Excel import error: $e");
    }
  }

  Future<Map<String, String>> _loadMarketMap() async {
    final snapshot = await _firestore.collection('supermarkets').get();
    final map = <String, String>{};
    for (var doc in snapshot.docs) {
      map[doc['name']] = doc.id;
    }
    return map;
  }

  // ================== MARKET EKLE ==================
  Future<void> _addNewMarket() async {
    if (!_marketFormKey.currentState!.validate()) return;

    setState(() => _isMarketLoading = true);
    try {
      final marketId = "market_${DateTime.now().millisecondsSinceEpoch}";
      await _firestore.collection('supermarkets').doc(marketId).set({
        'marketId': marketId,
        'name': _newMarketNameCtrl.text.trim(),
        'logoUrl':
            _newMarketLogoCtrl.text.trim().isEmpty
                ? 'https://placehold.co/100x100?text=${_newMarketNameCtrl.text}'
                : _newMarketLogoCtrl.text.trim(),
        'city': 'Nicosia',
      });

      _newMarketNameCtrl.clear();
      _newMarketLogoCtrl.clear();
    } finally {
      if (mounted) setState(() => _isMarketLoading = false);
    }
  }

  // ================== MANUEL PRODUCT ==================
  Future<void> _saveProduct() async {
    if (!_productFormKey.currentState!.validate()) return;
    if (_selectedMarketId == null) return;

    setState(() => _isProductLoading = true);
    try {
      final barcode = _barcodeCtrl.text.trim();

      await _firestore.collection('products').doc(barcode).set({
        'barcode': barcode,
        'productName': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'brand': _brandCtrl.text.trim(),
        'imageUrl': _imageCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore
          .collection('prices')
          .doc("${barcode}_$_selectedMarketId")
          .set({
            'productBarcode': barcode,
            'marketId': _selectedMarketId,
            'price': double.parse(_priceCtrl.text.trim()),
            'currency': 'TRY',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _clearProductForm();
    } finally {
      if (mounted) setState(() => _isProductLoading = false);
    }
  }

  void _clearProductForm() {
    _barcodeCtrl.clear();
    _nameCtrl.clear();
    _brandCtrl.clear();
    _imageCtrl.clear();
    _priceCtrl.clear();
    _selectedMarketId = null;
    _selectedCategory = null;
    setState(() {});
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // MARKET FORM
          Form(
            key: _marketFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Market Setup",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  "Market Name",
                  _newMarketNameCtrl,
                  icon: Icons.store,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  "Logo URL",
                  _newMarketLogoCtrl,
                  icon: Icons.link,
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _isMarketLoading ? null : _addNewMarket,
                    child: const Text("ADD MARKET"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // PRODUCT FORM (❗️KAYBOLMAYAN KISIM)
          Form(
            key: _productFormKey,
            child: Column(
              children: [
                _buildTextField("Barcode", _barcodeCtrl, icon: Icons.qr_code),
                const SizedBox(height: 12),
                _buildTextField(
                  "Product Name",
                  _nameCtrl,
                  icon: Icons.shopping_bag,
                ),
                const SizedBox(height: 12),
                _buildTextField("Brand", _brandCtrl),
                const SizedBox(height: 12),
                _buildTextField("Image URL", _imageCtrl),
                const SizedBox(height: 12),
                _buildTextField("Price", _priceCtrl),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("IMPORT FROM EXCEL"),
                  onPressed: _importFromExcel,
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _isProductLoading ? null : _saveProduct,
                  child: const Text("SAVE PRODUCT"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== UI HELPERS ==================
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon ?? Icons.text_fields),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
    );
  }
}

// --- DASHBOARD WIDGETS ---

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _OverviewSection(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _RecentOrdersTable()),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _TopProductsList()),
          ],
        ),
      ],
    );
  }
}

// --- 1. USER MANAGEMENT LIST (Kullanıcı Listeleme ve Yönetme) ---
class _UserManagementList extends StatelessWidget {
  const _UserManagementList();

  Future<void> _deleteUser(
    BuildContext context,
    String uid,
    String name,
  ) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete User"),
            content: Text(
              "Are you sure you want to delete $name? This action cannot be undone.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Customer Management",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text("Something went wrong");
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              final users = snapshot.data!.docs;

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  var user = users[index].data() as Map<String, dynamic>;
                  String uid = users[index].id;
                  String name = user['fullName'] ?? user['name'] ?? "User";
                  String email = user['email'] ?? "No Email";

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Özellik: Doğrulama Durumu
                        Icon(
                          user['isVerified'] == true
                              ? Icons.verified
                              : Icons.warning_amber_rounded,
                          color:
                              user['isVerified'] == true
                                  ? Colors.blue
                                  : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // Özellik: Hesap Silme
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteUser(context, uid, name),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductMaintenance extends StatelessWidget {
  const _ProductMaintenance();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BAŞLIK BÖLÜMÜ
        const Text(
          "Product Inventory",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Manage catalog details, images, and inventory status.",
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 24),

        // ÜRÜN LİSTESİ
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(child: Text("Something went wrong"));
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());

            final products = snapshot.data!.docs;

            if (products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    "No products found in the database.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doc = products[index];
                final data = doc.data() as Map<String, dynamic>;

                return _buildProductCard(context, doc, data);
              },
            );
          },
        ),
      ],
    );
  }

  // MODERN ÜRÜN KARTI TASARIMI
  Widget _buildProductCard(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ÜRÜN RESMİ (Sol taraf)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              image:
                  data['imageUrl'] != null &&
                          data['imageUrl'].toString().isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(data['imageUrl']),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                data['imageUrl'] == null || data['imageUrl'].toString().isEmpty
                    ? const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    )
                    : null,
          ),
          const SizedBox(width: 20),

          // ÜRÜN DETAYLARI (Orta taraf)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['brand']?.toString().toUpperCase() ?? "GENERIC",
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "#${data['barcode']}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  data['productName'] ?? "Unnamed Product",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  data['category'] ?? "No Category",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),

          // AKSİYON BUTONLARI (Sağ taraf)
          Row(
            children: [
              _buildIconButton(
                icon: Icons.edit_outlined,
                color: Colors.blue,
                onTap: () => _showEditProductDialog(context, doc),
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.red,
                onTap: () => _deleteProductCascade(context, doc.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ÜRÜN DÜZENLEME MODALI (Güzelleştirilmiş)
  void _showEditProductDialog(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['productName']);
    final brandCtrl = TextEditingController(text: data['brand']);
    final imageCtrl = TextEditingController(text: data['imageUrl']);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Update Product",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                  nameCtrl,
                  "Product Name",
                  Icons.shopping_cart_outlined,
                ),
                const SizedBox(height: 12),
                _buildDialogField(
                  brandCtrl,
                  "Brand",
                  Icons.branding_watermark_outlined,
                ),
                const SizedBox(height: 12),
                _buildDialogField(imageCtrl, "Image URL", Icons.link_outlined),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await doc.reference.update({
                    'productName': nameCtrl.text.trim(),
                    'brand': brandCtrl.text.trim(),
                    'imageUrl': imageCtrl.text.trim(),
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text("Save Changes"),
              ),
            ],
          ),
    );
  }

  Widget _buildDialogField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // KADEMELİ SİLME (Cascade Delete) MANTIĞI
  Future<void> _deleteProductCascade(
    BuildContext context,
    String barcode,
  ) async {
    bool confirm = await _showConfirmDialog(context);
    if (!confirm) return;

    final firestore = FirebaseFirestore.instance;

    try {
      WriteBatch batch = firestore.batch();

      // 1. Ürüne bağlı fiyat kayıtlarını bul ve sil
      var pricesSnapshot =
          await firestore
              .collection('prices')
              .where('productBarcode', isEqualTo: barcode)
              .get();
      for (var priceDoc in pricesSnapshot.docs) {
        batch.delete(priceDoc.reference);
      }

      // 2. Ürünün kendisini sil
      batch.delete(firestore.collection('products').doc(barcode));

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product and associated prices removed."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Deletion error: $e");
    }
  }

  Future<bool> _showConfirmDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder:
              (c) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text("Delete Product?"),
                content: const Text(
                  "All pricing data for this product across all markets will also be deleted.",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text("Keep it"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text(
                      "Delete Everything",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

class _SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuClick;

  const _SideMenu({required this.selectedIndex, required this.onMenuClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ScanWiser',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DrawerListTile(
            title: "Dashboard",
            icon: Icons.dashboard_rounded,
            isSelected: selectedIndex == 0,
            press: () => onMenuClick(0),
          ),
          _DrawerListTile(
            title: "Users",
            icon: Icons.people_alt_rounded,
            isSelected: selectedIndex == 2, // Seçili olma durumu eklendi
            press: () => onMenuClick(2), // Tıklama fonksiyonu bağlandı
          ),
          _DrawerListTile(
            title: "Add Product",
            icon: Icons.add_circle_outline,
            isSelected: selectedIndex == 1,
            press: () => onMenuClick(1),
          ),
          _DrawerListTile(
            title: "Manage Products",
            icon: Icons.inventory_2_outlined,
            isSelected: selectedIndex == 3,
            press: () => onMenuClick(3),
          ),

          const Spacer(),
          const Divider(),
          _DrawerListTile(
            title: "Logout",
            icon: Icons.logout_rounded,
            color: Colors.red,
            press: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DrawerListTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback press;
  final bool isSelected;
  final Color? color;

  const _DrawerListTile({
    required this.title,
    required this.icon,
    required this.press,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      leading: Icon(
        icon,
        color: color ?? (isSelected ? const Color(0xFF2E7D32) : Colors.grey),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              color ??
              (isSelected ? const Color(0xFF2E7D32) : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE8F5E9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            "Admin Panel",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person, color: Color(0xFF2E7D32)),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KULLANICILAR (Sayı + Liste Özeti)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  List<String> names =
                      docs
                          .map(
                            (d) =>
                                (d.data() as Map<String, dynamic>)['fullName']
                                    ?.toString() ??
                                "User",
                          )
                          .take(3)
                          .toList();
                  return _StatCard(
                    title: "Total Users",
                    value: docs.length.toString(),
                    icon: Icons.people_outline,
                    color: Colors.blue,
                    items: names,
                    hasMore: docs.length > 3,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // 2. ÜRÜNLER (Sayı + Liste Özeti)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  List<String> names =
                      docs
                          .map(
                            (d) =>
                                (d.data()
                                        as Map<String, dynamic>)['productName']
                                    ?.toString() ??
                                "Product",
                          )
                          .take(3)
                          .toList();
                  return _StatCard(
                    title: "Total Products",
                    value: docs.length.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: Colors.orange,
                    items: names,
                    hasMore: docs.length > 3,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // 3. MARKETLER (Tüm Market İsimleri)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('supermarkets')
                        .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  List<String> names =
                      docs
                          .map(
                            (d) =>
                                (d.data() as Map<String, dynamic>)['name']
                                    ?.toString() ??
                                "Market",
                          )
                          .toList();
                  return _StatCard(
                    title: "Active Markets",
                    value: docs.length.toString(),
                    icon: Icons.store_mall_directory_outlined,
                    color: Colors.green,
                    items: names,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            // 4. KATEGORİLER (Tüm Kategori İsimleri)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('categories')
                        .snapshots(),
                builder: (context, snapshot) {
                  final docs = snapshot.data?.docs ?? [];
                  List<String> names =
                      docs
                          .map(
                            (d) =>
                                (d.data() as Map<String, dynamic>)['name']
                                    ?.toString() ??
                                "Category",
                          )
                          .toList();
                  return _StatCard(
                    title: "Categories",
                    value: docs.length.toString(),
                    icon: Icons.category_outlined,
                    color: Colors.purple,
                    items: names,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<String> items;
  final bool hasMore;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.items = const [],
    this.hasMore = false,
  });

  // --- GELİŞMİŞ SİLME MANTIĞI (KADEMELİ SİLME) ---
  // İdari panel gereksinimlerine göre market ve kategorileri kademeli olarak silebilir
  void _quickDelete(String type, String name) async {
    final firestore = FirebaseFirestore.instance;
    String collection =
        type == "Active Markets" ? "supermarkets" : "categories";

    try {
      // 1. KADEMELİ SİLME: Eğer bir KATEGORİ siliniyorsa, ona bağlı ürünleri ve fiyatları temizle
      if (type == "Categories") {
        // Silinecek kategoriye ait ürünleri bul
        var productsSnapshot =
            await firestore
                .collection('products')
                .where('category', isEqualTo: name)
                .get();

        WriteBatch batch = firestore.batch();

        for (var productDoc in productsSnapshot.docs) {
          String barcode = productDoc.id;

          // A) Ürüne ait tüm fiyat kayıtlarını bul ve sil
          var pricesSnapshot =
              await firestore
                  .collection('prices')
                  .where('productBarcode', isEqualTo: barcode)
                  .get();

          for (var priceDoc in pricesSnapshot.docs) {
            batch.delete(priceDoc.reference);
          }

          // B) Ürünün kendisini sil
          batch.delete(productDoc.reference);
        }

        // Tüm ürün ve fiyat silme işlemlerini toplu olarak onayla
        await batch.commit();
      }

      // 2. ANA ÖĞEYİ SİL (Market veya Kategori)
      var snap =
          await firestore
              .collection(collection)
              .where('name', isEqualTo: name)
              .get();

      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Kademeli silme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Bilgi Satırı: İkon ve Sayısal Değer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Kart Başlığı (Örn: Total Users, Active Markets)
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Divider(height: 24),

          // İsimlerin Listelendiği Alan (Badge Sistemi)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...items.map(
                (name) => Container(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 4,
                    top: 4,
                    bottom: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // İsim Metni
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Hızlı Silme Butonu (Market ve Kategoriler için Aktif)
                      if (title == "Active Markets" || title == "Categories")
                        GestureDetector(
                          onTap: () => _quickDelete(title, name),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: color.withOpacity(0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Eğer liste sınırlanmışsa devamı olduğunu belirtir
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "...",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          // Veri yoksa gösterilecek mesaj
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "No data available yet",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentOrdersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Expanded(child: Center(child: Text("No data available"))),
        ],
      ),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Products",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          Expanded(child: Center(child: Text("No data available"))),
        ],
      ),
    );
  }
}
