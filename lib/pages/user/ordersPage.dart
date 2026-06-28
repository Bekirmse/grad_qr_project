// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'My Orders',
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
          user == null
              ? Center(
                child: Text(
                  'Please login to view orders',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('purchases')
                        .where('userId', isEqualTo: user.uid)
                        .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                      ),
                    );
                  }
                  if (snap.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 72,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start shopping to see your orders here',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final sortedDocs = snap.data!.docs.toList();
                  sortedDocs.sort((a, b) {
                    final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                    return (bTime?.toDate() ?? DateTime.now()).compareTo(
                      aTime?.toDate() ?? DateTime.now(),
                    );
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedDocs.length,
                    itemBuilder: (_, i) {
                      final p = sortedDocs[i].data() as Map<String, dynamic>;
                      final date = (p['timestamp'] as Timestamp).toDate();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    (p['imageUrl'] as String?) ?? '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: const Color(0xFFF5F7FA),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['productName'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        p['marketName'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (p['discountPrice'] != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${(p['originalPrice'] as num?)?.toStringAsFixed(2) ?? '0'} ${p['currency'] ?? 'TRY'}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            Text(
                                              '${p['price']?.toStringAsFixed(2) ?? '0'} ${p['currency'] ?? 'TRY'}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: const Color(0xFFE53935),
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          '${p['price']?.toStringAsFixed(2) ?? '0'} ${p['currency'] ?? 'TRY'}',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: const Color(0xFF2E7D32),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildOrderTimeline(
                              p['orderStatus'] as String? ?? 'pending',
                            ),
                            const SizedBox(height: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    _buildStatusBadge(
                                      p['orderStatus'] as String? ?? 'pending',
                                    ),
                                  ],
                                ),
                                if (p['orderStatus'] == 'cancelled' &&
                                    p['cancellationReason'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        'Reason: ${p['cancellationReason']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (p['orderStatus'] == 'pending')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed:
                                            () => _showCancelDialog(
                                              context,
                                              sortedDocs[i].id,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[100],
                                          foregroundColor: Colors.red[700],
                                          minimumSize: const Size(
                                            double.infinity,
                                            40,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Cancel Order',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, String orderId) async {
    final reasonCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    final quickReasons = [
      'Changed my mind',
      'Ordered by mistake',
      'Found a better price',
      'Delivery time too long',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          String? selectedReason;
          bool isLoading = false;

          return StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
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
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.cancel_outlined,
                              color: Colors.red[700], size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cancel Order',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              'Tell us why you\'re cancelling',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Quick Reasons',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...quickReasons.map((reason) {
                      final isChosen = selectedReason == reason;
                      return GestureDetector(
                        onTap: () {
                          setSheet(() {
                            selectedReason = reason;
                            reasonCtrl.text = reason;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? Colors.red[50]
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isChosen
                                  ? Colors.red[300]!
                                  : Colors.grey.shade200,
                              width: isChosen ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChosen
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isChosen
                                    ? Colors.red[600]
                                    : Colors.grey[400],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: isChosen
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isChosen
                                      ? Colors.red[700]
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Other reason',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 13),
                      onChanged: (v) =>
                          setSheet(() => selectedReason = null),
                      decoration: InputDecoration(
                        hintText: 'Describe your reason...',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: Colors.red[300]!, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'Go Back',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (reasonCtrl.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.red[400],
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        content: Text('Please select or enter a reason',
                                            style: GoogleFonts.poppins()),
                                      ));
                                      return;
                                    }
                                    setSheet(() => isLoading = true);
                                    try {
                                      final orderDoc = await FirebaseFirestore
                                          .instance
                                          .collection('purchases')
                                          .doc(orderId)
                                          .get();
                                      final data = orderDoc.data() ?? {};
                                      await FirebaseFirestore.instance
                                          .collection('purchases')
                                          .doc(orderId)
                                          .update({
                                        'orderStatus': 'cancelled',
                                        'cancellationReason':
                                            reasonCtrl.text.trim(),
                                        'cancelledAt':
                                            FieldValue.serverTimestamp(),
                                        'cancelledBy': user?.uid,
                                      });
                                      await FirebaseFirestore.instance
                                          .collection('cancellationLogs')
                                          .add({
                                        'orderId': orderId,
                                        'userId': user?.uid,
                                        'userEmail': user?.email ?? '',
                                        'productName': data['productName'] ?? '',
                                        'marketName': data['marketName'] ?? '',
                                        'reason': reasonCtrl.text.trim(),
                                        'cancelledAt': FieldValue.serverTimestamp(),
                                        'cancelledBy': 'user',
                                      });
                                      if (user != null) {
                                        await NotificationService
                                            .sendOrderCancelledNotification(
                                          userId: user.uid,
                                          productName:
                                              data['productName'] ?? '',
                                          marketName:
                                              data['marketName'] ?? '',
                                          reason: reasonCtrl.text.trim(),
                                        );
                                      }
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            const Color(0xFF2E7D32),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        content: Text(
                                            'Order cancelled successfully',
                                            style: GoogleFonts.poppins()),
                                      ));
                                    } catch (e) {
                                      setSheet(() => isLoading = false);
                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text('Error: $e',
                                            style: GoogleFonts.poppins()),
                                      ));
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Cancel Order',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'pending': (bg: const Color(0xFFFFF3E0), text: const Color(0xFFE65100)),
      'completed': (bg: const Color(0xFFE8F5E9), text: const Color(0xFF2E7D32)),
      'cancelled': (bg: const Color(0xFFFFEBEE), text: Colors.red[700]!),
    };
    final labels = {
      'pending': 'Pending',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    final color = colors[status] ?? colors['pending']!;
    final label = labels[status] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: color.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(String status) {
    const green = Color(0xFF2E7D32);
    const orange = Color(0xFFF57C00);
    const grey = Color(0xFFE0E0E0);
    const red = Color(0xFFD32F2F);
    const dotSize = 18.0;
    const dotRadius = dotSize / 2;

    final steps = ['Purchase', 'Order\nReceived', 'Delivery', 'Delivered'];

    // dot color per step per status
    // pending:   green, green, orange, grey
    // completed: green, green, green,  green
    // cancelled: green, green, red,    grey
    Color dot(int i) {
      if (status == 'completed') return green;
      if (status == 'cancelled') {
        if (i <= 1) return green;
        if (i == 2) return red;
        return grey;
      }
      // pending
      if (i <= 1) return green;
      if (i == 2) return orange;
      return grey;
    }

    // line color between step i and i+1
    // pending:   green(0→1), orange(1→2), grey(2→3)
    // completed: all green
    // cancelled: green(0→1), red(1→2),   grey(2→3)
    Color line(int i) {
      if (status == 'completed') return green;
      if (status == 'cancelled') {
        if (i == 0) return green;
        if (i == 1) return red;
        return grey;
      }
      // pending
      if (i == 0) return green;
      if (i == 1) return orange;
      return grey;
    }

    // icon inside dot
    Widget dotIcon(int i) {
      if (status == 'cancelled' && i == 2) {
        return const Icon(Icons.close_rounded, color: Colors.white, size: 11);
      }
      if (status == 'completed' ||
          (status == 'pending' && i <= 1) ||
          (status == 'cancelled' && i <= 1)) {
        return const Icon(Icons.check_rounded, color: Colors.white, size: 11);
      }
      if (status == 'pending' && i == 2) {
        return const Icon(Icons.access_time_rounded,
            color: Colors.white, size: 11);
      }
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          Positioned(
            top: dotRadius - 1,
            left: dotRadius,
            right: dotRadius,
            child: Row(
              children: List.generate(steps.length - 1, (i) => Expanded(
                child: Container(height: 2, color: line(i)),
              )),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (i) {
              final color = dot(i);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(child: dotIcon(i)),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 60,
                    child: Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: color == grey ? Colors.grey[400] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
