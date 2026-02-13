import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPlushImage(String uid, File imageFile) async {
    final ref = _storage.ref().child('plush_images').child('$uid-${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }
}
