import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> sendOrderCancelledNotification({
    required String userId,
    required String productName,
    required String marketName,
    required String reason,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': 'order_cancelled',
      'productName': productName,
      'marketName': marketName,
      'reason': reason,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendDiscountNotification({
    required String userId,
    required String productName,
    required String barcode,
    required double originalPrice,
    required double discountPrice,
    String? marketName,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': 'discount_alert',
      'productName': productName,
      'barcode': barcode,
      'marketName': marketName,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'savings': originalPrice - discountPrice,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendOrderReceivedNotification({
    required String userId,
    required String productName,
    required String marketName,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': 'order_received',
      'productName': productName,
      'marketName': marketName,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendOrderPreparingNotification({
    required String userId,
    required String productName,
    required String marketName,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'type': 'order_preparing',
      'productName': productName,
      'marketName': marketName,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          docs.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  static Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'read': true});
  }

  static Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.update({'read': true});
    }
  }
}
