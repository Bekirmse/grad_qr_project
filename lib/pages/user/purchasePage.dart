// ignore: file_names

// ignore_for_file: duplicate_ignore, file_names

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../services/notification_service.dart';
import '../../services/card_encryption_service.dart';

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
  bool _isBuying = false;
  bool _isProcessing = false;
  bool _showSuccess = false;

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
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    _cvvFocus.addListener(() {
      if (_cvvFocus.hasFocus && !_isFlipped) {
        _isFlipped = true;
        _flipCtrl.forward();
      } else if (!_cvvFocus.hasFocus && _isFlipped) {
        _isFlipped = false;
        _flipCtrl.reverse();
      }
    });

    _numberCtrl.addListener(
      () => setState(() => _cardNumber = _numberCtrl.text),
    );
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
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('paymentMethods')
              .limit(1)
              .get();
      if (snap.docs.isNotEmpty) {
        final card = snap.docs.first.data();
        _numberCtrl.text = await CardEncryptionService.decrypt(card['encryptedNumber'] ?? '');
        _nameCtrl.text = card['cardHolder'] ?? '';
        _expiryCtrl.text = card['expiry'] ?? '';
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }


  static const _labelIcons = {
    'home': Icons.home_rounded,
    'ev': Icons.home_rounded,
    'work': Icons.work_rounded,
    'iş': Icons.work_rounded,
    'office': Icons.work_rounded,
    'school': Icons.school_rounded,
    'okul': Icons.school_rounded,
    'other': Icons.location_on_rounded,
  };

  IconData _labelIcon(String label) {
    final key = label.toLowerCase();
    for (final e in _labelIcons.entries) {
      if (key.contains(e.key)) return e.value;
    }
    return Icons.location_on_rounded;
  }

  Future<void> _showAddressSelection() async {
    if (_user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      final addresses = (doc.data()?['addresses'] as List?) ?? [];
      final List<Map<String, dynamic>> addressList =
          List<Map<String, dynamic>>.from(addresses);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // handle
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: _green, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'Choose where to deliver',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(height: 1),
                ),
                const SizedBox(height: 8),
                // address list
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (addressList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.location_off_rounded,
                                  size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'No saved addresses yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...addressList.map((addr) {
                        final isSelected =
                            _selectedAddress == addr['address'];
                        final label = addr['label'] as String? ?? '';
                        return GestureDetector(
                          onTap: () {
                            setState(
                                () => _selectedAddress = addr['address']);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE8F5E9)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? _green
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _green.withValues(alpha: 0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _green.withValues(alpha: 0.15)
                                        : const Color(0xFFF5F7FA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _labelIcon(label),
                                    color: isSelected
                                        ? _green
                                        : Colors.grey[400],
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        addr['address'] as String? ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: _green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 16),
                                  )
                                else
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                // add new address button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAddNewAddress();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _green.withValues(alpha: 0.08),
                            _green.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: _green, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Add New Address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  void _showAddNewAddress() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String? selectedLabel;

    final quickLabels = ['Home', 'Work', 'School', 'Other'];
    final quickIcons = [
      Icons.home_rounded,
      Icons.work_rounded,
      Icons.school_rounded,
      Icons.location_on_rounded,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_location_alt_rounded,
                          color: _green, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Add New Address',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Address Type',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(quickLabels.length, (i) {
                    final isChosen = selectedLabel == quickLabels[i];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setSheet(() => selectedLabel = quickLabels[i]);
                          labelCtrl.text = quickLabels[i];
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right: i < quickLabels.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? _green
                                : const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChosen
                                  ? _green
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                quickIcons[i],
                                color: isChosen
                                    ? Colors.white
                                    : Colors.grey[500],
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                quickLabels[i],
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isChosen
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Text(
                  'Label',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: labelCtrl,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Home, Work...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.label_outline_rounded,
                        color: _green, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _green, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Address',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: addressCtrl,
                  maxLines: 3,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Street, Building, Apartment...',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.map_outlined,
                          color: _green, size: 20),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _green, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (labelCtrl.text.isEmpty ||
                          addressCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.red[400],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            content: Text('Please fill all fields',
                                style: GoogleFonts.poppins()),
                          ),
                        );
                        return;
                      }
                      if (_user != null) {
                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user.uid)
                            .get();
                        final existing =
                            (doc.data()?['addresses'] as List?) ?? [];
                        existing.add({
                          'label': labelCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'id': DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                        });
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user.uid)
                            .update({'addresses': existing});
                        setState(() =>
                            _selectedAddress = addressCtrl.text.trim());
                      }
                      if (mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Address',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCardAndBuy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a delivery address',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }
    setState(() => _isBuying = true);

    try {
      final lastFour = _cardNumber
          .replaceAll(' ', '')
          .substring(max(0, _cardNumber.replaceAll(' ', '').length - 4));
      final brand = _cardNumber.startsWith('4') ? 'Visa' : 'Mastercard';

      if (_saveCard) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('paymentMethods')
            .doc('primary')
            .set({
              'lastFour': lastFour,
              'cardHolder': _nameCtrl.text.trim(),
              'expiry': _expiryCtrl.text.trim(),
              'brand': brand,
              'encryptedNumber': await CardEncryptionService.encrypt(_cardNumber.replaceAll(' ', '')),
              'addedAt': FieldValue.serverTimestamp(),
            });
      }

      await _completePurchase(lastFour);
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

    await NotificationService.sendOrderReceivedNotification(
      userId: _user.uid,
      productName: widget.productName,
      marketName: widget.marketName,
    );

    await NotificationService.sendOrderPreparingNotification(
      userId: _user.uid,
      productName: widget.productName,
      marketName: widget.marketName,
    );

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
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
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
                            color:
                                _selectedAddress == null
                                    ? Colors.grey.shade200
                                    : _green,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color:
                                  _selectedAddress == null
                                      ? Colors.grey
                                      : _green,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery Address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedAddress ?? 'Tap to select address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _selectedAddress == null
                                              ? Colors.grey
                                              : const Color(0xFF1A1A2E),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                              size: 20,
                            ),
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
                            onChanged:
                                (val) =>
                                    setState(() => _saveCard = val ?? false),
                            activeColor: _green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Save card for future purchases',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w500,
                              ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _isBuying
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                : Text(
                                  'Buy · ${widget.price.toStringAsFixed(2)} ${widget.currency}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Card data is encrypted & securely stored',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
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
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Purchase Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.productName}\n${widget.marketName} · ${widget.price.toStringAsFixed(2)} ${widget.currency}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    () => Navigator.popUntil(
                      context,
                      (r) => r.isFirst || r.settings.name == '/home',
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
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
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
          child:
              isBack
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

  const _FrontCard({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
  });

  String get _displayNumber {
    final clean = cardNumber.replaceAll(' ', '');
    final padded = clean.padRight(16, '•');
    final groups = [
      padded.substring(0, 4),
      padded.substring(4, 8),
      padded.substring(8, 12),
      padded.substring(12, 16),
    ];
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ScanWiser Pay',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.credit_card,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _displayNumber,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          cardHolder.isEmpty
                              ? 'YOUR NAME'
                              : cardHolder.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRES',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          expiry.isEmpty ? 'MM/YY' : expiry,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
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
                      color:
                          cvv.isEmpty ? Colors.grey : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildField(
              'Card Number',
              numberCtrl,
              TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              maxLength: 19,
              validator:
                  (v) =>
                      (v == null || v.replaceAll(' ', '').length < 16)
                          ? 'Enter valid card number'
                          : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              'Cardholder Name',
              nameCtrl,
              TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'MM/YY',
                    expiryCtrl,
                    TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    maxLength: 5,
                    validator:
                        (v) => (v == null || v.length < 5) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildField(
                    'CVV',
                    cvvCtrl,
                    TextInputType.number,
                    focusNode: cvvFocus,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 3,
                    obscure: true,
                    validator:
                        (v) => (v == null || v.length < 3) ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    TextInputType type, {
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final String productName;
  final String marketName;
  final double price;
  final String currency;
  final String imageUrl;

  const _OrderSummary({
    required this.productName,
    required this.marketName,
    required this.price,
    required this.currency,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
            child:
                imageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                      ),
                    )
                    : const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey,
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  marketName,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${price.toStringAsFixed(2)} $currency',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final digits = next.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
