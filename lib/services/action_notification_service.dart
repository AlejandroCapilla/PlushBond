import 'package:cloud_functions/cloud_functions.dart';

class ActionNotificationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> sendSqueezeNotification({required String plushUid, required String caller}) async {
    try {
      final callable = _functions.httpsCallable('sendSqueezeNotification');
      await callable.call({
        'plushUid': plushUid,
        'caller': caller,
      });
      print('Squeeze notification sent successfully.');
    } catch (e) {
      print('Error sending squeeze notification: $e');
    }
  }

  Future<void> sendSecretNoteNotification({required String plushUid, required String caller}) async {
    try {
      final callable = _functions.httpsCallable('sendSecretNoteNotification');
      await callable.call({
        'plushUid': plushUid,
        'caller': caller,
      });
      print('Secret note notification sent successfully.');
    } catch (e) {
      print('Error sending secret note notification: $e');
    }
  }
}
