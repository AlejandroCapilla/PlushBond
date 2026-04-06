import 'package:firebase_messaging/firebase_messaging.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService;

  NotificationService(this._firestoreService);

  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> updateUserFcmToken(String uid) async {
    await requestPermissions();
    String? token = await getFcmToken();
    if (token != null) {
      await _firestoreService.updateFcmToken(uid, token);
      print('FCM Token updated for user $uid: $token');
    }
  }
}
