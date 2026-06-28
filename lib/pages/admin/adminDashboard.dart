// ignore: file_names

// ignore_for_file: duplicate_ignore, file_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/market_api_service.dart';
import '../../services/notification_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const _green = Color(0xFF2E7D32);
  static const _bg = Color(0xFFF5F7FA);

  final _sections = const [
    'Dashboard',
    'Orders',
    'Users',
    'Scan Logs',
    'Cancellations',
    'API Settings',
    'Notifications',
  ];

  final _icons = const [
    Icons.dashboard_rounded,
    Icons.shopping_bag_rounded,
    Icons.people_alt_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.cancel_rounded,
    Icons.api_rounded,
    Icons.notifications_rounded,
  ];

  Widget _buildSection(int index) {
    switch (index) {
      case 0:
        return const _Dashboard();
      case 1:
        return const _Orders();
      case 2:
        return const _Users();
      case 3:
        return const _ScanLogs();
      case 4:
        return const _CancellationLogs();
      case 5:
        return const _ApiSettings();
      case 6:
        return const _Notifications();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          Container(
            width: 230,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
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
                          color: _green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ScanWiser',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  _sections.length,
                  (i) => _NavTile(
                    title: _sections[i],
                    icon: _icons[i],
                    selected: _selectedIndex == i,
                    onTap: () => setState(() => _selectedIndex = i),
                  ),
                ),
                const Spacer(),
                const Divider(height: 1),
                _NavTile(
                  title: 'Logout',
                  icon: Icons.logout_rounded,
                  selected: false,
                  color: Colors.red,
                  onTap:
                      () => Navigator.pushReplacementNamed(context, '/login'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        _sections[_selectedIndex],
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: _green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Administrator',
                              style: GoogleFonts.poppins(
                                color: _green,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildSection(_selectedIndex),
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

class _NavTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _NavTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (selected ? const Color(0xFF2E7D32) : Colors.grey[600]!);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c, size: 20),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: c,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFE8F5E9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Admin',
          style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _StatCard(
              title: 'Total Users',
              icon: Icons.people_outline,
              color: Colors.blue,
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              valueBuilder: (snap) => snap.docs.length.toString(),
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Total Scans',
              icon: Icons.qr_code_scanner_rounded,
              color: Colors.orange,
              stream:
                  FirebaseFirestore.instance.collection('scanLogs').snapshots(),
              valueBuilder: (snap) => snap.docs.length.toString(),
            ),
            const SizedBox(width: 16),
            _StatCard(
              title: 'Notifications Sent',
              icon: Icons.notifications_outlined,
              color: Colors.purple,
              stream:
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .snapshots(),
              valueBuilder: (snap) => snap.docs.length.toString(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _RecentScans()),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: _RecentUsers()),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot> stream;
  final String Function(QuerySnapshot) valueBuilder;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.valueBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder:
              (_, snap) => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        snap.hasData ? valueBuilder(snap.data!) : '...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        title,
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
      ),
    );
  }
}

class _RecentScans extends StatefulWidget {
  @override
  State<_RecentScans> createState() => _RecentScansState();
}

class _RecentScansState extends State<_RecentScans> {
  final Map<String, String> _nameCache = {};

  Future<String> _getFullName(String? userId, String? fallbackEmail) async {
    if (userId == null || userId.isEmpty) return fallbackEmail?.split('@').first ?? 'Unknown';
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final name = doc.data()?['fullName']?.toString() ?? '';
      final result = name.isNotEmpty ? name : (fallbackEmail?.split('@').first ?? 'Unknown');
      _nameCache[userId] = result;
      return result;
    } catch (_) {
      return fallbackEmail?.split('@').first ?? 'Unknown';
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
          Text(
            'Recent Scans',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('scanLogs')
                    .orderBy('timestamp', descending: true)
                    .limit(8)
                    .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return Text(
                  'No scans yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                );
              }
              return Column(
                children: snap.data!.docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl']?.toString() ?? '';
                  final userId = data['userId']?.toString();
                  final email = data['userEmail']?.toString();
                  return FutureBuilder<String>(
                    future: _getFullName(userId, email),
                    builder: (_, nameSnap) {
                      final name = nameSnap.data ?? email?.split('@').first ?? 'Unknown';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                                )
                              : _fallbackIcon(),
                        ),
                        title: Text(
                          data['productName']?.toString() ?? data['barcode']?.toString() ?? '',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          '$name · ${data['city'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: data['timestamp'] != null
                            ? Text(
                                _formatDate((data['timestamp'] as Timestamp).toDate()),
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                              )
                            : null,
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.qr_code_rounded, color: Color(0xFF2E7D32), size: 18),
      );

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _RecentUsers extends StatelessWidget {
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
          Text(
            'Recent Users',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .limit(6)
                    .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return Text(
                  'No users yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                );
              }
              return Column(
                children:
                    snap.data!.docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = data['fullName']?.toString() ?? 'User';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          radius: 18,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          data['email']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
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

class _Users extends StatelessWidget {
  const _Users();

  Future<void> _delete(BuildContext context, String uid, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete User',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Delete $name? This cannot be undone.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok == true) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
        await callable.call({'uid': uid});
      } catch (_) {}
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name deleted.'),
            backgroundColor: Colors.red,
          ),
        );
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
          Text(
            'Registered Users',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return Text(
                  'No users yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snap.data!.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data =
                      snap.data!.docs[i].data() as Map<String, dynamic>;
                  final uid = snap.data!.docs[i].id;
                  final name = data['fullName']?.toString() ?? 'User';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      data['email']?.toString() ?? '',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data['isVerified'] == true
                              ? Icons.verified
                              : Icons.warning_amber_rounded,
                          color:
                              data['isVerified'] == true
                                  ? Colors.blue
                                  : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _delete(context, uid, name),
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

class _Orders extends StatefulWidget {
  const _Orders();

  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  Future<void> _cancelOrder({
    required BuildContext context,
    required String purchaseId,
    required String userId,
    required String productName,
    required String marketName,
  }) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cancel Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$productName at $marketName',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                onChanged: (_) => setStateDialog(() {}),
                decoration: InputDecoration(
                  labelText: 'Reason for cancellation',
                  hintText: 'Please enter a reason...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: 3,
              ),
              if (reasonCtrl.text.trim().isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'You must enter a reason to confirm cancellation.',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.red[400]),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Abort', style: GoogleFonts.poppins()),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: reasonCtrl.text.trim().isNotEmpty ? Colors.red : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: reasonCtrl.text.trim().isNotEmpty
                    ? () => Navigator.pop(c, true)
                    : null,
                child: Text(
                  'Confirm',
                  style: GoogleFonts.poppins(
                    color: reasonCtrl.text.trim().isNotEmpty ? Colors.white : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true && reasonCtrl.text.trim().isNotEmpty) {
      final reason = reasonCtrl.text.trim();

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userEmail = userDoc.data()?['email'] as String? ?? '';

      await FirebaseFirestore.instance
          .collection('purchases')
          .doc(purchaseId)
          .update({
            'orderStatus': 'cancelled',
            'cancellationReason': reason,
            'cancelledAt': FieldValue.serverTimestamp(),
          });
      await FirebaseFirestore.instance.collection('cancellationLogs').add({
        'orderId': purchaseId,
        'userId': userId,
        'userEmail': userEmail,
        'productName': productName,
        'marketName': marketName,
        'reason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'admin',
      });
      await NotificationService.sendOrderCancelledNotification(
        userId: userId,
        productName: productName,
        marketName: marketName,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.red),
        );
      }
    }
    reasonCtrl.dispose();
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
          Text(
            'Orders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Track user purchases and manage cancellations',
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('purchases').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return Text(
                  'No orders yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                );
              }
              final sortedDocs =
                  snap.data!.docs.toList()..sort((a, b) {
                    final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                    final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                    return (bTime?.toDate() ?? DateTime.now()).compareTo(
                      aTime?.toDate() ?? DateTime.now(),
                    );
                  });
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = sortedDocs[i].data() as Map<String, dynamic>;
                  final docId = sortedDocs[i].id;
                  final ts = data['timestamp'] as Timestamp?;
                  final orderStatus =
                      data['orderStatus'] as String? ?? 'pending';
                  final isCancelled = orderStatus == 'cancelled';
                  final statusColor = isCancelled ? Colors.red : Colors.orange;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE8F5E9),
                      child: ClipOval(
                        child: (data['imageUrl'] as String?)?.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: data['imageUrl'] as String,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.shopping_bag_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                              )
                            : const Icon(
                                Icons.shopping_bag_rounded,
                                color: Color(0xFF2E7D32),
                                size: 20,
                              ),
                      ),
                    ),
                    title: Text(
                      data['productName']?.toString() ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['userEmail'] ?? ''} · ${data['marketName'] ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${data['price']?.toStringAsFixed(2) ?? ''} ${data['currency'] ?? 'TRY'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isCancelled
                                        ? Colors.red.shade50
                                        : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                orderStatus.replaceFirst(
                                  orderStatus[0],
                                  orderStatus[0].toUpperCase(),
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (ts != null)
                          Text(
                            '${ts.toDate().day}/${ts.toDate().month}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        if (!isCancelled)
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                            ),
                            onPressed:
                                () => _cancelOrder(
                                  context: context,
                                  purchaseId: docId,
                                  userId: data['userId'],
                                  productName: data['productName'],
                                  marketName: data['marketName'],
                                ),
                          ),
                      ],
                    ),
                    isThreeLine: true,
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

class _ScanLogs extends StatefulWidget {
  const _ScanLogs();

  @override
  State<_ScanLogs> createState() => _ScanLogsState();
}

class _ScanLogsState extends State<_ScanLogs> {
  final Map<String, String> _nameCache = {};

  Future<String> _getFullName(String? userId, String? fallbackEmail) async {
    if (userId == null || userId.isEmpty) {
      return fallbackEmail?.split('@').first ?? 'Unknown';
    }
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final name = doc.data()?['fullName']?.toString() ?? '';
      final result = name.isNotEmpty ? name : (fallbackEmail?.split('@').first ?? 'Unknown');
      _nameCache[userId] = result;
      return result;
    } catch (_) {
      return fallbackEmail?.split('@').first ?? 'Unknown';
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
          Text('Scan Logs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('All product scans by users', style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('scanLogs')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
              }
              if (snap.data!.docs.isEmpty) {
                return Text('No scan logs yet.', style: GoogleFonts.poppins(color: Colors.grey));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snap.data!.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final data = snap.data!.docs[i].data() as Map<String, dynamic>;
                  final ts = data['timestamp'] as Timestamp?;
                  final imageUrl = data['imageUrl']?.toString() ?? '';
                  final userId = data['userId']?.toString();
                  final email = data['userEmail']?.toString();
                  return FutureBuilder<String>(
                    future: _getFullName(userId, email),
                    builder: (_, nameSnap) {
                      final name = nameSnap.data ?? email?.split('@').first ?? 'Unknown';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                                )
                              : _fallbackIcon(),
                        ),
                        title: Text(
                          data['productName']?.toString() ?? data['barcode']?.toString() ?? '',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$name · ${data['city'] ?? ''} · Barcode: ${data['barcode'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: ts != null
                            ? Text(_fmt(ts.toDate()), style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey))
                            : null,
                        isThreeLine: true,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.qr_code_rounded, color: Color(0xFF2E7D32), size: 22),
      );

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _CancellationLogs extends StatelessWidget {
  const _CancellationLogs();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cancellationLogs')
          .snapshots(),
      builder: (_, snap) {
        if (snap.hasError) {
          return Padding(padding: const EdgeInsets.all(24), child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          );
        }
        if (snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No cancellations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ta = (a.data() as Map)['cancelledAt'];
              final tb = (b.data() as Map)['cancelledAt'];
              if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
              return 0;
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final log = docs[i].data() as Map<String, dynamic>;
              final ts = log['cancelledAt'];
              final date = ts is Timestamp ? ts.toDate() : DateTime.now();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                log['orderId'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            'Cancelled',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((log['productName'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${log['productName']} — ${log['marketName'] ?? ''}',
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Email',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              (log['userEmail'] != null && (log['userEmail'] as String).isNotEmpty)
                                  ? log['userEmail']
                                  : (log['cancelledBy'] == 'admin' ? 'Cancelled by Admin' : 'N/A'),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Date',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancellation Reason',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log['reason'] ?? 'No reason provided',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
  }
}

class _ApiSettings extends StatefulWidget {
  const _ApiSettings();

  @override
  State<_ApiSettings> createState() => _ApiSettingsState();
}

class _ApiSettingsState extends State<_ApiSettings> {
  final _urlCtrl = TextEditingController();
  String _savedUrl = '';
  bool _isSaving = false;
  bool _isTesting = false;
  bool? _testResult;

  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('marketApi')
          .get()
          .timeout(const Duration(seconds: 6));
      if (doc.exists && mounted) {
        final url = (doc.data()?['baseUrl'] ?? '').toString();
        setState(() {
          _savedUrl = url;
          _urlCtrl.text = url;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('marketApi')
          .set({'baseUrl': url, 'updatedAt': FieldValue.serverTimestamp()});
      MarketApiService.clearCache();
      setState(() => _savedUrl = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API URL saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _test() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final res = await http
          .get(Uri.parse('$url/api/products/search?barcode=test&city=Lefkosa'))
          .timeout(const Duration(seconds: 6));
      setState(
        () => _testResult = res.statusCode == 200 || res.statusCode == 404,
      );
    } catch (_) {
      setState(() => _testResult = false);
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market API Configuration',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'C# backend URL for barcode+city price queries',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              if (_savedUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: _green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _savedUrl,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _green,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'https://your-api.com',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _testResult!
                            ? const Color(0xFFE8F5E9)
                            : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testResult! ? Icons.check_circle : Icons.error_outline,
                        color: _testResult! ? _green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _testResult!
                            ? 'API is reachable ✓'
                            : 'API unreachable — check if server is running',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _testResult! ? _green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          _isTesting
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2E7D32),
                                ),
                              )
                              : const Icon(
                                Icons.wifi_tethering_rounded,
                                size: 18,
                              ),
                      label: Text(
                        'Test Connection',
                        style: GoogleFonts.poppins(),
                      ),
                      onPressed: _isTesting ? null : _test,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _green,
                        side: const BorderSide(color: _green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.save_outlined, size: 18),
                      label: Text('Save URL', style: GoogleFonts.poppins()),
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API Endpoint Info',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _EndpointRow(
                method: 'GET',
                path: '/api/products/search?barcode={barcode}&city={city}',
                desc:
                    'Returns product info + prices for given barcode in given city',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndpointRow extends StatelessWidget {
  final String method;
  final String path;
  final String desc;

  const _EndpointRow({
    required this.method,
    required this.path,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  method,
                  style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  path,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _Notifications extends StatefulWidget {
  const _Notifications();

  @override
  State<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<_Notifications> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _isSending = false;
  bool _sendToAll = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  String? _selectedUserId;
  String? _selectedUserEmail;
  final _userSearchCtrl = TextEditingController();
  bool _showUserList = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();
      setState(() {
        _users = snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
        _filteredUsers = _users;
      });
    } catch (_) {}
  }

  void _filterUsers(String query) {
    setState(() {
      _showUserList = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        final q = query.toLowerCase();
        _filteredUsers = _users.where((u) {
          final name = (u['fullName'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    if (!_sendToAll && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user')),
      );
      return;
    }
    setState(() => _isSending = true);
    try {
      final title = _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim();

      if (_sendToAll) {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in usersSnap.docs) {
          final ref = FirebaseFirestore.instance.collection('notifications').doc();
          batch.set(ref, {
            'userId': doc.id,
            'title': title,
            'body': body,
            'type': 'admin_broadcast',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'sentBy': 'admin',
          });
        }
        await batch.commit();
        await FirebaseFirestore.instance.collection('sentNotifications').add({
          'title': title,
          'body': body,
          'sentTo': 'all',
          'recipientCount': usersSnap.docs.length,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': _selectedUserId,
          'title': title,
          'body': body,
          'type': 'admin_broadcast',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'sentBy': 'admin',
        });
        await FirebaseFirestore.instance.collection('sentNotifications').add({
          'title': title,
          'body': body,
          'sentTo': _selectedUserEmail ?? _selectedUserId,
          'recipientCount': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _selectedUserId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sendToAll ? 'Notification sent to all users' : 'Notification sent to $_selectedUserEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Notification',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _sendToAll = true; _selectedUserId = null; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _sendToAll ? const Color(0xFF2E7D32) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _sendToAll ? const Color(0xFF2E7D32) : Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_rounded, size: 18, color: _sendToAll ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text('All Users', style: GoogleFonts.poppins(color: _sendToAll ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sendToAll = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_sendToAll ? const Color(0xFF2E7D32) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: !_sendToAll ? const Color(0xFF2E7D32) : Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_rounded, size: 18, color: !_sendToAll ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text('Select User', style: GoogleFonts.poppins(color: !_sendToAll ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_sendToAll) ...[
                const SizedBox(height: 14),
                if (_selectedUserId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E7D32)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _users.firstWhere((u) => u['uid'] == _selectedUserId, orElse: () => {})['fullName']?.toString() ?? '',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                _selectedUserEmail ?? '',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _selectedUserId = null;
                            _selectedUserEmail = null;
                            _userSearchCtrl.clear();
                            _showUserList = false;
                          }),
                          child: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: _userSearchCtrl,
                  onChanged: _filterUsers,
                  decoration: InputDecoration(
                    labelText: 'Search by name or email',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _userSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _userSearchCtrl.clear();
                              _filterUsers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                if (_showUserList && _filteredUsers.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (_, i) {
                        final u = _filteredUsers[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE8F5E9),
                            child: Text(
                              (u['fullName']?.toString() ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(u['fullName']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(u['email']?.toString() ?? '', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                          onTap: () => setState(() {
                            _selectedUserId = u['uid']?.toString();
                            _selectedUserEmail = u['email']?.toString();
                            _userSearchCtrl.clear();
                            _showUserList = false;
                          }),
                        );
                      },
                    ),
                  ),
                if (_showUserList && _filteredUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('No users found', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                  ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title_rounded, size: 20),
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
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _sendToAll ? 'Send to All Users' : 'Send to Selected User',
                    style: GoogleFonts.poppins(),
                  ),
                  onPressed: _isSending ? null : _send,
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sent Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sentNotifications')
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                  }
                  if (snap.data!.docs.isEmpty) {
                    return Text('No notifications sent yet.', style: GoogleFonts.poppins(color: Colors.grey));
                  }
                  final docs = snap.data!.docs.toList()
                    ..sort((a, b) {
                      final ta = (a.data() as Map)['createdAt'];
                      final tb = (b.data() as Map)['createdAt'];
                      if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                      return 0;
                    });
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final ts = data['createdAt'] as Timestamp?;
                      final sentTo = data['sentTo'] ?? '';
                      final count = data['recipientCount'] as int?;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2E7D32), size: 20),
                        ),
                        title: Text(data['title'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['body'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                            Text(
                              sentTo == 'all' ? 'Sent to all users${count != null ? ' ($count)' : ''}' : 'Sent to $sentTo',
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (ts != null)
                              Text(
                                '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}',
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => docs[i].reference.delete(),
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
        ),
      ],
    );
  }
}
