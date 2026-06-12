// ignore_for_file: file_names

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
}
