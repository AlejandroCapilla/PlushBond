import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> transformPlushImage(String folderUid) async {
    final HttpsCallable callable = _functions.httpsCallable('transformPlushImage');
    
    final response = await callable.call({
      'folderUid': folderUid,
      'useNanoBanana': true,
    });

    return Map<String, dynamic>.from(response.data);
  }
}
