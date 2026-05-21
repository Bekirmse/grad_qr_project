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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SideMenu(
            selectedIndex: _selectedIndex,
            onMenuClick: (i) => setState(() => _selectedIndex = i),
          ),
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
                        if (_selectedIndex == 0) const _DashboardOverview(),
                        if (_selectedIndex == 1) const _AddProductForm(),
                        if (_selectedIndex == 2) const _UserManagementList(),
                        if (_selectedIndex == 3) const _ProductMaintenance(),
                        if (_selectedIndex == 4)
                          const _SupermarketManagement(),
                        if (_selectedIndex == 5)
                          const _NotificationModule(),
                        if (_selectedIndex == 6) const _ServiceModule(),
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

class _SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuClick;

  const _SideMenu({required this.selectedIndex, required this.onMenuClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ScanWiser',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _tile('Dashboard', Icons.dashboard_rounded, 0),
          _tile('Add Product', Icons.add_circle_outline, 1),
          _tile('Customers', Icons.people_alt_rounded, 2),
          _tile('Products', Icons.inventory_2_outlined, 3),
          _tile('Supermarkets', Icons.store_mall_directory_outlined, 4),
          _tile('Notifications', Icons.notifications_outlined, 5),
          _tile('Services', Icons.settings_outlined, 6),
          const Spacer(),
          const Divider(height: 1),
          _DrawerListTile(
            title: 'Logout',
            icon: Icons.logout_rounded,
            color: Colors.red,
            press: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _tile(String title, IconData icon, int index) {
    return _DrawerListTile(
      title: title,
      icon: icon,
      isSelected: selectedIndex == index,
      press: () => onMenuClick(index),
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
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              color ??
              (isSelected ? const Color(0xFF2E7D32) : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE8F5E9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Admin Panel',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFF2E7D32), size: 18),
                SizedBox(width: 6),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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

class _DashboardOverview extends StatelessWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back, Admin',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (_, snap) => _StatCard(
                  title: 'Total Users',
                  value: snap.data?.docs.length.toString() ?? '...',
                  icon: Icons.people_outline,
                  color: Colors.blue,
                  items: snap.data?.docs
                      .map((d) => (d.data() as Map)['fullName']?.toString() ?? 'User')
                      .take(3)
                      .toList() ?? [],
                  hasMore: (snap.data?.docs.length ?? 0) > 3,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (_, snap) => _StatCard(
                  title: 'Total Products',
                  value: snap.data?.docs.length.toString() ?? '...',
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange,
                  items: snap.data?.docs
                      .map((d) => (d.data() as Map)['productName']?.toString() ?? 'Product')
                      .take(3)
                      .toList() ?? [],
                  hasMore: (snap.data?.docs.length ?? 0) > 3,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('supermarkets').snapshots(),
                builder: (_, snap) => _StatCard(
                  title: 'Active Markets',
                  value: snap.data?.docs.length.toString() ?? '...',
                  icon: Icons.store_mall_directory_outlined,
                  color: Colors.green,
                  items: snap.data?.docs
                      .map((d) => (d.data() as Map)['name']?.toString() ?? 'Market')
                      .toList() ?? [],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                builder: (_, snap) => _StatCard(
                  title: 'Categories',
                  value: snap.data?.docs.length.toString() ?? '...',
                  icon: Icons.category_outlined,
                  color: Colors.purple,
                  items: snap.data?.docs
                      .map((d) => (d.data() as Map)['name']?.toString() ?? 'Category')
                      .toList() ?? [],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _RecentProductsTable()),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _RecentUsersWidget()),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Divider(height: 20),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...items.map(
                (name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (hasMore)
                Text('...', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          if (items.isEmpty)
            Text(
              'No data yet',
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _RecentProductsTable extends StatelessWidget {
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
          const Text('Recent Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text('No products yet', style: TextStyle(color: Colors.grey));
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 20),
                    ),
                    title: Text(
                      data['productName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(data['category'] ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['brand'] ?? 'Generic',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentUsersWidget extends StatelessWidget {
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
          const Text('Recent Users', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Text('No users yet', style: TextStyle(color: Colors.grey));
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['fullName'] ?? data['name'] ?? 'User').toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      radius: 18,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(data['email'] ?? '', style: const TextStyle(fontSize: 11)),
                    trailing: Icon(
                      data['isVerified'] == true ? Icons.verified : Icons.pending_outlined,
                      size: 16,
                      color: data['isVerified'] == true ? Colors.blue : Colors.orange,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddProductForm extends StatefulWidget {
  const _AddProductForm();

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _productFormKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _barcodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedMarketId;
  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _imageCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _importFromExcel() async {
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

      final Uint8List bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first]!;
      final marketMap = await _loadMarketMap();
      WriteBatch batch = _firestore.batch();
      int successCount = 0;
      final markets = ['Dima', 'Erülkü Süpermarket', 'Kiler', 'Macro Supermarket', 'Şokmar'];

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        final barcode = row[0]?.value?.toString().trim() ?? '';
        if (barcode.isEmpty) continue;

        final productName = row[1]?.value?.toString() ?? '';
        final category = row[2]?.value?.toString() ?? '';
        final brand = row[3]?.value?.toString() ?? '';
        final imageUrl = row[4]?.value?.toString() ?? '';
        final normalizedCategory = category.trim();
        final categoryKey = normalizedCategory.toLowerCase();

        if (normalizedCategory.isNotEmpty && !existingCategories.contains(categoryKey)) {
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

        batch.set(
          _firestore.collection('products').doc(barcode),
          {
            'barcode': barcode,
            'productName': productName,
            'category': category,
            'brand': brand,
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        for (int m = 0; m < markets.length; m++) {
          final cell = row.length > 5 + m ? row[5 + m] : null;
          if (cell?.value == null) continue;
          final price = double.tryParse(cell!.value.toString().replaceAll(',', '.')) ?? 0;
          if (price <= 0) continue;
          final marketId = marketMap[markets[m]];
          if (marketId == null) continue;
          batch.set(_firestore.collection('prices').doc('${barcode}_$marketId'), {
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
            content: Text('$successCount price records imported'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Excel import error: $e');
    }
  }

  Future<Map<String, String>> _loadMarketMap() async {
    final snapshot = await _firestore.collection('supermarkets').get();
    return {for (var doc in snapshot.docs) doc['name'].toString(): doc.id};
  }

  Future<void> _saveProduct() async {
    if (!_productFormKey.currentState!.validate()) return;
    if (_selectedMarketId == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category and market')),
      );
      return;
    }

    setState(() => _isLoading = true);
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

      await _firestore.collection('prices').doc('${barcode}_$_selectedMarketId').set({
        'productBarcode': barcode,
        'marketId': _selectedMarketId,
        'price': double.parse(_priceCtrl.text.trim()),
        'currency': 'TRY',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _barcodeCtrl.clear();
      _nameCtrl.clear();
      _brandCtrl.clear();
      _imageCtrl.clear();
      _priceCtrl.clear();
      setState(() {
        _selectedMarketId = null;
        _selectedCategory = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Product', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Form(
            key: _productFormKey,
            child: Column(
              children: [
                _field('Barcode', _barcodeCtrl, Icons.qr_code),
                const SizedBox(height: 14),
                _field('Product Name', _nameCtrl, Icons.shopping_bag_outlined),
                const SizedBox(height: 14),
                _field('Brand', _brandCtrl, Icons.branding_watermark_outlined),
                const SizedBox(height: 14),
                _field('Image URL', _imageCtrl, Icons.image_outlined, required: false),
                const SizedBox(height: 14),
                _field('Price (TRY)', _priceCtrl, Icons.price_change_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                  builder: (context, snap) {
                    final items = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: _deco('Category', Icons.category_outlined),
                      items: items
                          .map((d) => DropdownMenuItem(value: d['name'].toString(), child: Text(d['name'].toString())))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('supermarkets').snapshots(),
                  builder: (context, snap) {
                    final items = snap.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedMarketId,
                      decoration: _deco('Supermarket', Icons.store_outlined),
                      items: items
                          .map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'].toString())))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMarketId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Excel'),
                  onPressed: _importFromExcel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    foregroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: _isLoading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Product'),
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, bool required = true}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _deco(label, icon),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _UserManagementList extends StatelessWidget {
  const _UserManagementList();

  Future<void> _deleteUser(BuildContext context, String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete User'),
        content: Text('Delete $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final users = snap.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = users[i].data() as Map<String, dynamic>;
                  final uid = users[i].id;
                  final name = data['fullName'] ?? data['name'] ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data['isVerified'] == true ? Icons.verified : Icons.warning_amber_rounded,
                          color: data['isVerified'] == true ? Colors.blue : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
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
        const Text('Product Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Manage all products and their prices.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final products = snap.data!.docs;
            if (products.isEmpty) {
              return Center(child: Text('No products found.', style: TextStyle(color: Colors.grey[400])));
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ProductCard(doc: products[i]),
            );
          },
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _ProductCard({required this.doc});

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: const Text('All pricing data will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
    if (!confirm) return;

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final prices = await db.collection('prices').where('productBarcode', isEqualTo: doc.id).get();
    for (var p in prices.docs) { batch.delete(p.reference); }
    batch.delete(doc.reference);
    await batch.commit();
  }

  void _edit(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['productName']);
    final brandCtrl = TextEditingController(text: data['brand']);
    final imageCtrl = TextEditingController(text: data['imageUrl']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'Product Name', Icons.shopping_cart_outlined),
            const SizedBox(height: 10),
            _dialogField(brandCtrl, 'Brand', Icons.branding_watermark_outlined),
            const SizedBox(height: 10),
            _dialogField(imageCtrl, 'Image URL', Icons.link_outlined),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({
                'productName': nameCtrl.text.trim(),
                'brand': brandCtrl.text.trim(),
                'imageUrl': imageCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['imageUrl'], fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                  )
                : const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      data['brand']?.toString().toUpperCase() ?? 'GENERIC',
                      style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('#${data['barcode']}', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ]),
                const SizedBox(height: 4),
                Text(data['productName'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(data['category'] ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _iconBtn(Icons.edit_outlined, Colors.blue, () => _edit(context)),
              const SizedBox(width: 8),
              _iconBtn(Icons.delete_outline_rounded, Colors.red, () => _delete(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, color: color, size: 18)),
      ),
    );
  }
}

class _SupermarketManagement extends StatefulWidget {
  const _SupermarketManagement();

  @override
  State<_SupermarketManagement> createState() => _SupermarketManagementState();
}

class _SupermarketManagementState extends State<_SupermarketManagement> {
  final _nameCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _logoCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _addMarket() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final id = 'market_${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('supermarkets').doc(id).set({
        'marketId': id,
        'name': _nameCtrl.text.trim(),
        'logoUrl': _logoCtrl.text.trim().isEmpty
            ? 'https://placehold.co/100x100?text=${Uri.encodeComponent(_nameCtrl.text.trim())}'
            : _logoCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? 'Nicosia' : _cityCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _nameCtrl.clear();
      _logoCtrl.clear();
      _cityCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supermarket added'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMarket(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Supermarket?'),
        content: Text('Delete $name? All prices linked to this store will remain.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await FirebaseFirestore.instance.collection('supermarkets').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supermarket Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Add and manage supermarkets in the system.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Supermarket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInput('Market Name *', _nameCtrl, Icons.store_outlined)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildInput('City', _cityCtrl, Icons.location_city_outlined)),
                ],
              ),
              const SizedBox(height: 14),
              _buildInput('Logo URL (optional)', _logoCtrl, Icons.image_outlined),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: _isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Supermarket'),
                  onPressed: _isLoading ? null : _addMarket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Supermarkets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('supermarkets').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Text('No supermarkets added yet.', style: TextStyle(color: Colors.grey[400]));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final logoUrl = data['logoUrl']?.toString() ?? '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: logoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(logoUrl, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.grey)),
                                )
                              : const Icon(Icons.store, color: Colors.grey),
                        ),
                        title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        subtitle: Text(data['city'] ?? '', style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteMarket(context, id, data['name'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _NotificationModule extends StatefulWidget {
  const _NotificationModule();

  @override
  State<_NotificationModule> createState() => _NotificationModuleState();
}

class _NotificationModuleState extends State<_NotificationModule> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and message')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent to all users'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String id) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notification Module', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Send announcements and alerts to all users.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send New Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Notification Title',
                  prefixIcon: const Icon(Icons.title_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(Icons.message_outlined, size: 20),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: _isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send to All Users'),
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sent Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Text('No notifications sent yet.', style: TextStyle(color: Colors.grey[400]));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      Timestamp? ts = data['createdAt'];
                      String time = '';
                      if (ts != null) {
                        final d = ts.toDate();
                        time = '${d.day}/${d.month}/${d.year}';
                      }
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2E7D32), size: 20),
                        ),
                        title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['body'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (time.isNotEmpty)
                              Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _deleteNotification(id),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceModule extends StatefulWidget {
  const _ServiceModule();

  @override
  State<_ServiceModule> createState() => _ServiceModuleState();
}

class _ServiceModuleState extends State<_ServiceModule> {
  final _categoryNameCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _categoryNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _categoryNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final id = name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^\w_]'), '');
      await FirebaseFirestore.instance.collection('categories').doc(id).set({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _categoryNameCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added'), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category?'),
        content: Text('Delete "$name"? Products in this category will remain but lose their category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
    if (confirm) {
      await FirebaseFirestore.instance.collection('categories').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Module', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Manage categories, product listings, and app services.', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Category Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _categoryNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'New Category Name',
                        prefixIcon: const Icon(Icons.category_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: _isLoading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add'),
                    onPressed: _isLoading ? null : _addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Text('No categories yet.', style: TextStyle(color: Colors.grey[400]));
                  }
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: docs.map((d) {
                      final name = d['name'].toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(name, style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteCategory(context, d.id, name),
                              child: const Icon(Icons.close, size: 14, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('App Services Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _ServiceStatusTile(icon: Icons.qr_code_scanner_rounded, title: 'Barcode Scanning', status: 'Active'),
              _ServiceStatusTile(icon: Icons.compare_arrows_rounded, title: 'Price Comparison', status: 'Active'),
              _ServiceStatusTile(icon: Icons.notifications_active_rounded, title: 'Push Notifications', status: 'Active'),
              _ServiceStatusTile(icon: Icons.favorite_rounded, title: 'Favorites & Wishlists', status: 'Active'),
              _ServiceStatusTile(icon: Icons.search_rounded, title: 'Product Search', status: 'Active'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceStatusTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;

  const _ServiceStatusTile({required this.icon, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(status, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
