import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> sendOrderCancelledNotification({
    required String userId,
    required String productName,
    required String marketName,
    required String reason,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'type': 'order_cancelled',
        'productName': productName,
        'marketName': marketName,
        'reason': reason,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending order cancelled notification: $e');
    }
  }

  static Future<void> sendDiscountNotification({
    required String userId,
    required String productName,
    required String barcode,
    required double originalPrice,
    required double discountPrice,
    String? marketName,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('Error sending discount notification: $e');
    }
  }

  static Future<void> sendOrderReceivedNotification({
    required String userId,
    required String productName,
    required String marketName,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'type': 'order_received',
        'productName': productName,
        'marketName': marketName,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending order received notification: $e');
    }
  }

  static Future<void> sendOrderPreparingNotification({
    required String userId,
    required String productName,
    required String marketName,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'type': 'order_preparing',
        'productName': productName,
        'marketName': marketName,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending order preparing notification: $e');
    }
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
    try {
      await _db.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  static Future<void> markAllAsRead(String userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();
      for (var doc in snap.docs) {
        try {
          await doc.reference.update({'read': true});
        } catch (e) {
          debugPrint('Error marking individual notification as read: $e');
        }
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
