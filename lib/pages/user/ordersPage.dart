
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        title: Text('My Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1A1A2E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? Center(
              child: Text('Please login to view orders', style: GoogleFonts.poppins(color: Colors.grey)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchases')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                if (snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No orders yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Start shopping to see your orders here',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final sortedDocs = snap.data!.docs.toList();
                sortedDocs.sort((a, b) {
                  final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                  return (bTime?.toDate() ?? DateTime.now()).compareTo(aTime?.toDate() ?? DateTime.now());
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
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network((p['imageUrl'] as String?) ?? '',
                                    width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: const Color(0xFFF5F7FA))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['productName'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(p['marketName'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    if (p['discountPrice'] != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${(p['originalPrice'] as num?)?.toStringAsFixed(2) ?? '0'} ${p['currency'] ?? 'TRY'}',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: Colors.grey,
                                              decoration: TextDecoration.lineThrough,
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
                                      Text('${p['price']?.toStringAsFixed(2) ?? '0'} ${p['currency'] ?? 'TRY'}',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2E7D32))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildOrderTimeline(p['orderStatus'] as String? ?? 'pending'),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${date.day}/${date.month}/${date.year}',
                                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                                  _buildStatusBadge(p['orderStatus'] as String? ?? 'pending'),
                                ],
                              ),
                              if (p['orderStatus'] == 'cancelled' && p['cancellationReason'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red[200]!),
                                    ),
                                    child: Text('Reason: ${p['cancellationReason']}',
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.red[700])),
                                  ),
                                ),
                              if (p['orderStatus'] == 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _showCancelDialog(context, sortedDocs[i].id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[100],
                                        foregroundColor: Colors.red[700],
                                        minimumSize: const Size(double.infinity, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: Text('Cancel Order',
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for cancellation:',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter cancellation reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Back', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a reason', style: GoogleFonts.poppins())),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('purchases')
                    .doc(orderId)
                    .update({
                  'orderStatus': 'cancelled',
                  'cancellationReason': reasonCtrl.text.trim(),
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'cancelledBy': user?.uid,
                });

                await FirebaseFirestore.instance.collection('cancellationLogs').add({
                  'orderId': orderId,
                  'userId': user?.uid,
                  'userEmail': user?.email,
                  'reason': reasonCtrl.text.trim(),
                  'cancelledAt': FieldValue.serverTimestamp(),
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order cancelled successfully', style: GoogleFonts.poppins())),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins())),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
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
      decoration: BoxDecoration(color: color.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 10, color: color.text, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildOrderTimeline(String status) {
    const green = Color(0xFF2E7D32);
    const orange = Color(0xFFF57C00);
    const grey = Color(0xFFE0E0E0);
    const red = Colors.red;

    final steps = ['Purchase', 'Order Received', 'Delivery', 'Delivered'];

    int completedStep = 1;
    if (status == 'completed') {
      completedStep = 3;
    } else if (status == 'cancelled') {
      completedStep = -1;
    }

    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Row(
                  children: List.generate(steps.length - 1, (i) {
                    Color lineColor;
                    if (i == 1) {
                      lineColor = orange;
                    } else if (i < completedStep || (status == 'completed' && i < 3)) {
                      lineColor = green;
                    } else {
                      lineColor = grey;
                    }
                    return Expanded(
                      child: Container(
                        height: 2,
                        color: lineColor,
                      ),
                    );
                  }),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(steps.length, (i) {
                  final isCancelled = status == 'cancelled';
                  Color dotColor;
                  if (i == 2) {
                    dotColor = orange;
                  } else if (isCancelled) {
                    dotColor = i == 0 ? green : red;
                  } else {
                    dotColor = i <= completedStep ? green : grey;
                  }

                  return Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          steps[i],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
