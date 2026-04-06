import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/functions_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final storageServiceProvider = Provider((ref) => StorageService());
final functionsServiceProvider = Provider((ref) => FunctionsService());
final notificationServiceProvider = Provider((ref) => NotificationService(ref.read(firestoreServiceProvider)));

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState != null) {
    return await ref.read(firestoreServiceProvider).getUser(authState.uid);
  }
  return null;
});
final onboardingProvider = StateProvider<bool>((ref) => true);
