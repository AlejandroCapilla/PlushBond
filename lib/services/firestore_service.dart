import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/plush_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updatePartnerId(String uid, String? partnerId) async {
    await _db.collection('users').doc(uid).update({'partnerId': partnerId});
  }

  // Plush Operations
  Future<void> createPlush(PlushModel plush) async {
    await _db.collection('plush').doc(plush.plushId).set(plush.toMap());
  }

  Future<PlushModel?> getPlush(String plushId) async {
    final doc = await _db.collection('plush').doc(plushId).get();
    if (doc.exists) {
      return PlushModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<PlushModel?> getPlushByInviteCode(String inviteCode) async {
    final query = await _db
        .collection('plush')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return PlushModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  Future<void> updatePlush(PlushModel plush) async {
    await _db.collection('plush').doc(plush.plushId).update(plush.toMap());
  }

  Stream<PlushModel?> streamPlush(String plushId) {
    return _db.collection('plush').doc(plushId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return PlushModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Stream<PlushModel?> streamPlushForUser(String uid) {
    return _db
        .collection('plush')
        .where(Filter.or(
          Filter('ownerA', isEqualTo: uid),
          Filter('ownerB', isEqualTo: uid),
        ))
        .snapshots()
        .map((query) {
      if (query.docs.isNotEmpty) {
        return PlushModel.fromMap(query.docs.first.data(), query.docs.first.id);
      }
      return null;
    });
  }

  Future<PlushModel?> getPlushForUser(String uid) async {
    final query = await _db
        .collection('plush')
        .where('ownerA', isEqualTo: uid)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return PlushModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    
    final queryB = await _db
        .collection('plush')
        .where('ownerB', isEqualTo: uid)
        .limit(1)
        .get();
    if (queryB.docs.isNotEmpty) {
      return PlushModel.fromMap(queryB.docs.first.data(), queryB.docs.first.id);
    }
    
    return null;
  }
}
