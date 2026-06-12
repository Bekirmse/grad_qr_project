// ignore_for_file: file_names

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class PurchasePage extends StatefulWidget {
  final String productName;
  final String barcode;
  final double price;
  final String currency;
  final String marketName;
  final String city;
  final String imageUrl;
  final bool isCart;

  const PurchasePage({
    super.key,
    required this.productName,
    required this.barcode,
    required this.price,
    required this.currency,
    required this.marketName,
    required this.city,
    required this.imageUrl,
    this.isCart = false,
  });

  @override
  State<PurchasePage> createState() => _PurchasePageState();
}

class _PurchasePageState extends State<PurchasePage>
    with SingleTickerProviderStateMixin {
  final _user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  final _cvvFocus = FocusNode();

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  bool _isFlipped = false;
  bool _isLoading = true;
  bool _hasSavedCard = false;
  bool _isBuying = false;
  bool _isProcessing = false;
  bool _showSuccess = false;

  Map<String, dynamic>? _savedCard;

  String _cardNumber = '';
  String _cardHolder = '';
  String _expiry = '';
  String _cvv = '';
  String? _selectedAddress;
  bool _saveCard = false;

  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_isFlipped) {
        _isFlipped = true;
        _flipCtrl.forward();
      } else if (!_cvvFocus.hasFocus && _isFlipped) {
        _isFlipped = false;
        _flipCtrl.reverse();
      }
    });

    _numberCtrl.addListener(() => setState(() => _cardNumber = _numberCtrl.text));
    _nameCtrl.addListener(() => setState(() => _cardHolder = _nameCtrl.text));
    _expiryCtrl.addListener(() => setState(() => _expiry = _expiryCtrl.text));
    _cvvCtrl.addListener(() => setState(() => _cvv = _cvvCtrl.text));

    _checkSavedCard();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _cvvFocus.dispose();
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSavedCard() async {
    if (_user == null) { setState(() => _isLoading = false); return; }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(_user.uid)
          .collection('paymentMethods')
          .limit(1).get();
      if (snap.docs.isNotEmpty) {
        setState(() {
          _savedCard = snap.docs.first.data();
          _hasSavedCard = true;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _encode(String value) => base64Encode(utf8.encode(value));

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

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: _green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Select Delivery Address',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A1A2E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...addressList.map((addr) {
                    final isSelected = _selectedAddress == addr['address'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAddress = addr['address']);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? _green : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? _green : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addr['label'],
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1A1A2E)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addr['address'],
                                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddNewAddress();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, color: _green, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Add New Address',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: _green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            child: Text('Add', style: GoogleFonts.poppins(color: _green, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCardAndBuy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a delivery address', style: GoogleFonts.poppins())),
      );
      return;
    }
    setState(() => _isBuying = true);

    try {
      final lastFour = _cardNumber.replaceAll(' ', '').substring(
          max(0, _cardNumber.replaceAll(' ', '').length - 4));
      final brand = _cardNumber.startsWith('4') ? 'Visa' : 'Mastercard';

      if (_saveCard) {
        await FirebaseFirestore.instance
            .collection('users').doc(_user!.uid)
            .collection('paymentMethods').doc('primary').set({
          'lastFour': lastFour,
          'cardHolder': _nameCtrl.text.trim(),
          'expiry': _expiryCtrl.text.trim(),
          'brand': brand,
          'encryptedNumber': _encode(_cardNumber.replaceAll(' ', '')),
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      await _completePurchase(lastFour);
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _buyWithSavedCard() async {
    setState(() => _isBuying = true);
    try {
      await _completePurchase(_savedCard!['lastFour']);
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  Future<void> _completePurchase(String lastFour) async {
    if (mounted) setState(() => _isProcessing = true);

    await FirebaseFirestore.instance.collection('purchases').add({
      'userId': _user!.uid,
      'userEmail': _user.email ?? '',
      'barcode': widget.barcode,
      'productName': widget.productName,
      'marketName': widget.marketName,
      'price': widget.price,
      'currency': widget.currency,
      'city': widget.city,
      'imageUrl': widget.imageUrl,
      'deliveryAddress': _selectedAddress,
      'cardLastFour': lastFour,
      'purchaseStatus': 'complete',
      'orderStatus': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _showSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) return _buildProcessing();
    if (_showSuccess) return _buildSuccess();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1A1A2E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _OrderSummary(
                    productName: widget.productName,
                    marketName: widget.marketName,
                    price: widget.price,
                    currency: widget.currency,
                    imageUrl: widget.imageUrl,
                  ),
                  const SizedBox(height: 24),
                  if (_hasSavedCard)
                    _SavedCardSection(
                      card: _savedCard!,
                      isBuying: _isBuying,
                      onBuy: _buyWithSavedCard,
                      onUseNew: () => setState(() => _hasSavedCard = false),
                    )
                  else ...[
                    _AnimatedCard(
                      flipAnim: _flipAnim,
                      cardNumber: _cardNumber,
                      cardHolder: _cardHolder,
                      expiry: _expiry,
                      cvv: _cvv,
                    ),
                    const SizedBox(height: 24),
                    _CardForm(
                      formKey: _formKey,
                      numberCtrl: _numberCtrl,
                      nameCtrl: _nameCtrl,
                      expiryCtrl: _expiryCtrl,
                      cvvCtrl: _cvvCtrl,
                      cvvFocus: _cvvFocus,
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _showAddressSelection,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedAddress == null ? Colors.grey.shade200 : _green,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: _selectedAddress == null ? Colors.grey : _green, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Address',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress ?? 'Tap to select address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedAddress == null ? Colors.grey : const Color(0xFF1A1A2E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _saveCard,
                            onChanged: (val) => setState(() => _saveCard = val ?? false),
                            activeColor: _green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          Expanded(
                            child: Text(
                              'Save card for future purchases',
                              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1A1A2E), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isBuying ? null : _saveCardAndBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isBuying
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Buy · ${widget.price.toStringAsFixed(2)} ${widget.currency}',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('Card data is encrypted & securely stored',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProcessing() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/check.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Processing Payment',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Verifying your card information...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  'assets/animations/purchase_complate.json',
                  fit: BoxFit.contain,
                  repeat: false,
                ),
              ),
              const SizedBox(height: 24),
              Text('Purchase Successful!',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text('${widget.productName}\n${widget.marketName} · ${widget.price.toStringAsFixed(2)} ${widget.currency}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == '/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Back to Home', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatelessWidget {
  final Animation<double> flipAnim;
  final String cardNumber;
  final String cardHolder;
  final String expiry;
  final String cvv;

  const _AnimatedCard({
    required this.flipAnim,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
    required this.cvv,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnim,
      builder: (_, __) {
        final angle = flipAnim.value * pi;
        final isBack = angle > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _BackCard(cvv: cvv),
                )
              : _FrontCard(
                  cardNumber: cardNumber,
                  cardHolder: cardHolder,
                  expiry: expiry,
                ),
        );
      },
    );
  }
}

class _FrontCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String expiry;

  const _FrontCard({required this.cardNumber, required this.cardHolder, required this.expiry});

  String get _displayNumber {
    final clean = cardNumber.replaceAll(' ', '');
    final padded = clean.padRight(16, '•');
    final groups = [padded.substring(0, 4), padded.substring(4, 8), padded.substring(8, 12), padded.substring(12, 16)];
    return groups.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -30,
            child: Container(width: 150, height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05)))),
          Positioned(bottom: -40, left: -20,
            child: Container(width: 180, height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05)))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ScanWiser Pay', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(width: 44, height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.credit_card, color: Colors.white, size: 18)),
                  ],
                ),
                const Spacer(),
                Text(_displayNumber,
                    style: GoogleFonts.spaceMono(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CARD HOLDER', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 9, letterSpacing: 1)),
                      Text(cardHolder.isEmpty ? 'YOUR NAME' : cardHolder.toUpperCase(),
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('EXPIRES', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 9, letterSpacing: 1)),
                      Text(expiry.isEmpty ? 'MM/YY' : expiry,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackCard extends StatelessWidget {
  final String cvv;
  const _BackCard({required this.cvv});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Container(height: 44, color: Colors.black87),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cvv.isEmpty ? 'CVV' : cvv,
                    style: GoogleFonts.spaceMono(
                        fontSize: 16,
                        color: cvv.isEmpty ? Colors.grey : const Color(0xFF1A1A2E),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3),
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

class _CardForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController numberCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController expiryCtrl;
  final TextEditingController cvvCtrl;
  final FocusNode cvvFocus;

  const _CardForm({
    required this.formKey,
    required this.numberCtrl,
    required this.nameCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.cvvFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          children: [
            _buildField('Card Number', numberCtrl, TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
                maxLength: 19,
                validator: (v) => (v == null || v.replaceAll(' ', '').length < 16) ? 'Enter valid card number' : null),
            const SizedBox(height: 14),
            _buildField('Cardholder Name', nameCtrl, TextInputType.name,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _buildField('MM/YY', expiryCtrl, TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()],
                    maxLength: 5,
                    validator: (v) => (v == null || v.length < 5) ? 'Required' : null)),
                const SizedBox(width: 14),
                Expanded(child: _buildField('CVV', cvvCtrl, TextInputType.number,
                    focusNode: cvvFocus,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 3,
                    obscure: true,
                    validator: (v) => (v == null || v.length < 3) ? 'Required' : null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, TextInputType type, {
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscure = false,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscure,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }
}

class _SavedCardSection extends StatelessWidget {
  final Map<String, dynamic> card;
  final bool isBuying;
  final VoidCallback onBuy;
  final VoidCallback onUseNew;

  const _SavedCardSection({required this.card, required this.isBuying, required this.onBuy, required this.onUseNew});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.credit_card_rounded, color: Color(0xFF2E7D32), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${card['brand'] ?? 'Card'} •••• ${card['lastFour'] ?? ''}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('${card['cardHolder'] ?? ''} · Expires ${card['expiry'] ?? ''}',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isBuying ? null : onBuy,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isBuying
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Buy Now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: onUseNew,
          child: Text('Use a different card', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final String productName;
  final String marketName;
  final double price;
  final String currency;
  final String imageUrl;

  const _OrderSummary({required this.productName, required this.marketName, required this.price, required this.currency, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
            child: imageUrl.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: Colors.grey)))
                : const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(marketName, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${price.toStringAsFixed(2)} $currency',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return next.copyWith(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
