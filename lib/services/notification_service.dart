import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../globals.dart';
import 'firestore_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService;

  NotificationService(this._firestoreService);

  void initializeForegroundListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showInAppNotification(message);
      }
    });
  }

  void _showInAppNotification(RemoteMessage message) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_active, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.notification?.title != null)
                          Text(
                            message.notification!.title!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        if (message.notification?.title != null && message.notification?.body != null)
                          const SizedBox(height: 4),
                        if (message.notification?.body != null)
                          Text(
                            message.notification!.body!,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (overlayEntry.mounted) {
                        overlayEntry.remove();
                      }
                    },
                  ),
                ],
              ),
            ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn(),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

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
      final plush = await _firestoreService.getPlushForUser(uid);
      if (plush != null) {
        final user = await _firestoreService.getUser(uid);
        if (user != null) {
          bool isOwnerA = plush.ownerA == uid;
          await _firestoreService.updatePlushFcmInfo(plush.plushId, isOwnerA, token, user.displayName);
          print('FCM Token and name updated in plush for user $uid');
        }
      }
    }
  }
}
