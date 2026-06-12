// ignore_for_file: file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      NotificationService.markAllAsRead(_user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: const Color(0xFF1A1A2E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _user == null
          ? Center(
              child: Text('Please login to view notifications', style: GoogleFonts.poppins(color: Colors.grey)),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService.getNotifications(_user.uid),
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                final notifs = snap.data ?? [];
                if (notifs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 72, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No notifications', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('You\'re all caught up!',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifs.length,
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    final type = n['type'] as String?;
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
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type == 'order_cancelled' ? 'Order Cancelled' : 'Notification',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.red),
                                    ),
                                    const SizedBox(height: 4),
                                    if (type == 'order_cancelled') ...[
                                      Text(
                                        '${n['productName'] ?? ''} at ${n['marketName'] ?? ''}',
                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade200),
                                        ),
                                        child: Text(
                                          'Reason: ${n['reason'] ?? 'No reason provided'}',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ],
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
}
