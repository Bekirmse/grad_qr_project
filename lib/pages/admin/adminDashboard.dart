// ignore_for_file: file_names

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT SIDE MENU
          _SideMenu(selectedIndex: _selectedIndex, onMenuClick: _onMenuSelect),

          // 2. RIGHT CONTENT AREA
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
                        _selectedIndex == 0
                            ? const _DashboardOverview()
                            : const _AddProductForm(),
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

// --- ADD PRODUCT FORM (REVISED & DYNAMIC CATEGORY) ---
class _AddProductForm extends StatefulWidget {
  const _AddProductForm();

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedMarketId;
  bool _isLoading = false;

  // Static Market List (For initialization)
  final List<Map<String, String>> _markets = [
    {
      'id': 'market_erulku',
      'name': 'Erülkü Süpermarket',
      'city': 'Lefkoşa',
      'logoUrl': 'https://placehold.co/100x100?text=Erulku',
    },
    {
      'id': 'market_sokmar',
      'name': 'Şokmar',
      'city': 'Gazimağusa',
      'logoUrl': 'https://placehold.co/100x100?text=Sokmar',
    },
    {
      'id': 'market_macro',
      'name': 'Macro Supermarket',
      'city': 'Lefkoşa',
      'logoUrl': 'https://placehold.co/100x100?text=Macro',
    },
    {
      'id': 'market_kiler',
      'name': 'Kiler',
      'city': 'Girne',
      'logoUrl': 'https://placehold.co/100x100?text=Kiler',
    },
    {
      'id': 'market_dima',
      'name': 'Dima',
      'city': 'Gazimağusa',
      'logoUrl': 'https://placehold.co/100x100?text=Dima',
    },
  ];

  // --- FUNCTION: INITIALIZE SUPERMARKETS (Run once) ---
  Future<void> _initializeSupermarkets() async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = _firestore.batch();

      for (var market in _markets) {
        DocumentReference ref = _firestore
            .collection('supermarkets')
            .doc(market['id']);
        batch.set(ref, {
          'marketId': market['id'],
          'name': market['name'],
          'city': market['city'],
          'logoUrl': market['logoUrl'],
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Supermarkets initialized successfully!"),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FUNCTION: ADD NEW CATEGORY DIALOG ---
  void _showAddCategoryDialog() {
    TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add New Category"),
            content: TextField(
              controller: catController,
              decoration: const InputDecoration(hintText: "e.g. Stationery"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (catController.text.isNotEmpty) {
                    String newCategory = catController.text.trim();

                    // Save to Firestore 'categories' collection
                    await _firestore
                        .collection('categories')
                        .doc(newCategory)
                        .set({'name': newCategory});

                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedCategory =
                            newCategory; // Auto-select the new category
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  // --- FUNCTION: SAVE PRODUCT ---
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMarketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a supermarket!")),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String barcode = _barcodeCtrl.text.trim();

      // 1. Save Product Data
      await _firestore.collection('products').doc(barcode).set({
        'barcode': barcode,
        'productName': _nameCtrl.text.trim(),
        'category': _selectedCategory,
        'brand': _brandCtrl.text.trim(),
        'imageUrl': _imageCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Save Price Data
      String priceDocId = "${barcode}_$_selectedMarketId";
      await _firestore.collection('prices').doc(priceDocId).set({
        'productBarcode': barcode,
        'marketId': _selectedMarketId,
        'price': double.parse(_priceCtrl.text.trim()),
        'currency': 'TRY',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success! ${_nameCtrl.text} added."),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _barcodeCtrl.clear();
    _nameCtrl.clear();
    _brandCtrl.clear();
    _imageCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    setState(() {
      _selectedMarketId = null;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 1000),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add New Product / Price",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _initializeSupermarkets,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Initialize Markets (Run Once)"),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // BARCODE & NAME
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Barcode No",
                      _barcodeCtrl,
                      icon: Icons.qr_code,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      "Product Name",
                      _nameCtrl,
                      icon: Icons.shopping_bag,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // CATEGORY (DYNAMIC) & BRAND
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DYNAMIC CATEGORY DROPDOWN
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('categories')
                              .orderBy('name')
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        List<DropdownMenuItem<String>> categoryItems = [];
                        for (var doc in snapshot.data!.docs) {
                          String catName = doc['name'];
                          categoryItems.add(
                            DropdownMenuItem(
                              value: catName,
                              child: Text(catName),
                            ),
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: "Category",
                                  prefixIcon: const Icon(
                                    Icons.category,
                                    color: Colors.grey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                items: categoryItems,
                                onChanged:
                                    (val) =>
                                        setState(() => _selectedCategory = val),
                                validator:
                                    (val) => val == null ? "Required" : null,
                              ),
                            ),
                            // ADD CATEGORY BUTTON
                            IconButton(
                              onPressed: _showAddCategoryDialog,
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF2E7D32),
                                size: 36,
                              ),
                              tooltip: "Add New Category",
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      "Brand",
                      _brandCtrl,
                      icon: Icons.branding_watermark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // IMAGE & DESCRIPTION
              _buildTextField("Image URL", _imageCtrl, icon: Icons.image),
              const SizedBox(height: 20),
              _buildTextField(
                "Description",
                _descCtrl,
                icon: Icons.description,
                maxLines: 2,
              ),

              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                "Pricing & Market",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // MARKET & PRICE
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedMarketId,
                      decoration: InputDecoration(
                        labelText: "Select Supermarket",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      items:
                          _markets.map((market) {
                            return DropdownMenuItem(
                              value: market['id'],
                              child: Text(market['name']!),
                            );
                          }).toList(),
                      onChanged:
                          (val) => setState(() => _selectedMarketId = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Price (TL)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ACTION BUTTONS
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    OutlinedButton(
                      onPressed: _clearForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                      ),
                      child: const Text("Clear"),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "SAVE PRODUCT",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator:
          (value) =>
              value == null || value.isEmpty ? "$label is required" : null,
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
                  'PriceScanner',
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
            title: "Add Product",
            icon: Icons.add_circle_outline,
            isSelected: selectedIndex == 1,
            press: () => onMenuClick(1),
          ),
          _DrawerListTile(
            title: "Users",
            icon: Icons.people_alt_rounded,
            press: () {},
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
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Total Users",
            value: "1,234",
            icon: Icons.people_outline,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            title: "Products",
            value: "5,678",
            icon: Icons.inventory_2_outlined,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _StatCard(
            title: "Pending",
            value: "12",
            icon: Icons.pending_actions,
            color: Colors.red,
          ),
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
