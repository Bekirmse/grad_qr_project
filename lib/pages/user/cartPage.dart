// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:grad_qr_project/services/cart_service.dart';
import 'purchasePage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _user = FirebaseAuth.instance.currentUser;
  String? _selectedAddress;

  Future<void> _showAddressSelection() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      final addresses = doc.get('addresses') as List? ?? [];
      final List<Map<String, dynamic>> addressList =
          List<Map<String, dynamic>>.from(addresses);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Select Address', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...addressList.asMap().entries.map((entry) {
                  final addr = entry.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedAddress = addr['address']);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedAddress == addr['address']
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(addr['label'],
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(addr['address'],
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                              maxLines: 2),
                        ],
                      ),
                    ),
                  );
                }),
                const Divider(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAddNewAddress();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Text('Add New Address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: const Color(0xFF2E7D32),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  void _showAddNewAddress() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Address', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                hintText: 'Home, Work, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () async {
              if (labelCtrl.text.isEmpty || addressCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields', style: GoogleFonts.poppins())),
                );
                return;
              }

              if (_user != null) {
                final doc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user.uid)
                    .get();
                final addresses = doc.get('addresses') as List? ?? [];
                addresses.add({
                  'label': labelCtrl.text,
                  'address': addressCtrl.text,
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                });
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(_user.uid)
                    .update({'addresses': addresses});

                setState(() => _selectedAddress = addressCtrl.text);
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: Text('Add', style: GoogleFonts.poppins(color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout() async {
    if (cartService.items.isEmpty) return;
    if (_user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_user.uid)
          .collection('paymentMethods')
          .limit(1).get();

      if (snap.docs.isNotEmpty) {
        await _completePurchase(snap.docs.first.data()['lastFour']);
      } else {
        if (!mounted) return;
        final item = cartService.items.first;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PurchasePage(
            productName: cartService.items.map((i) => i.productName).join(', '),
            barcode: item.barcode,
            price: cartService.total,
            currency: item.currency,
            marketName: cartService.items.map((i) => i.marketName).join(', '),
            city: item.city,
            imageUrl: item.imageUrl,
            isCart: true,
          ),
        )).then((_) => cartService.clear());
      }
    } catch (_) {}
  }

  Future<void> _completePurchase(String lastFour) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a delivery address', style: GoogleFonts.poppins())),
      );
      return;
    }

    for (final item in cartService.items) {
      final finalPrice = item.discountPrice ?? item.price;
      await FirebaseFirestore.instance.collection('purchases').add({
        'userId': _user!.uid,
        'userEmail': _user.email,
        'barcode': item.barcode,
        'productName': item.productName,
        'marketName': item.marketName,
        'originalPrice': item.price * item.quantity,
        'price': finalPrice * item.quantity,
        'discountPrice': item.discountPrice != null ? item.discountPrice! * item.quantity : null,
        'currency': item.currency,
        'city': item.city,
        'deliveryAddress': _selectedAddress,
        'cardLastFour': lastFour,
        'purchaseStatus': 'complete',
        'orderStatus': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    if (!mounted) return;
    cartService.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Lottie.asset(
            'assets/animations/pizza_delivery.json',
            width: 300,
            height: 300,
            repeat: false,
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('Shopping Cart',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1A1A2E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartService.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Cart is empty',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  Text('Add products to get started',
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartService.items.length,
                    itemBuilder: (_, i) {
                      final item = cartService.items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(item.imageUrl,
                                  width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60, height: 60,
                                    color: const Color(0xFFF5F7FA),
                                    child: const Icon(Icons.shopping_bag_outlined),
                                  )),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productName,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text(item.marketName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (item.discountPrice != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item.price.toStringAsFixed(2)} ${item.currency}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                                color: Colors.grey,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            Text(
                                              '${item.discountPrice!.toStringAsFixed(2)} ${item.currency}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: const Color(0xFFE53935),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text('${item.price.toStringAsFixed(2)} ${item.currency}',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2E7D32))),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFF0F2F5), borderRadius: BorderRadius.circular(6)),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => setState(() => item.quantity = (item.quantity - 1).clamp(1, 99)),
                                              child: const Icon(Icons.remove, size: 14, color: Color(0xFF2E7D32)),
                                            ),
                                            const SizedBox(width: 6),
                                            Text('${item.quantity}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => setState(() => item.quantity++),
                                              child: const Icon(Icons.add, size: 14, color: Color(0xFF2E7D32)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => setState(() => cartService.removeItem(item.barcode, item.marketName)),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('${cartService.total.toStringAsFixed(2)} ${cartService.items.first.currency}',
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showAddressSelection,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFF2E7D32), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAddress ?? 'Select delivery address',
                                  style: GoogleFonts.poppins(fontSize: 13, color: _selectedAddress == null ? Colors.grey : const Color(0xFF1A1A2E)),
                                  maxLines: 2,
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Proceed to Checkout',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
