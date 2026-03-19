import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../models/plush_model.dart';

class CreatePlushScreen extends ConsumerStatefulWidget {
  const CreatePlushScreen({super.key});

  @override
  ConsumerState<CreatePlushScreen> createState() => _CreatePlushScreenState();
}

class _CreatePlushScreenState extends ConsumerState<CreatePlushScreen> {
  final _nameController = TextEditingController();
  File? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  String _generateInviteCode() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  Future<void> _create() async {
    if (_image == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and enter a name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final storage = ref.read(storageServiceProvider);
    final firestore = ref.read(firestoreServiceProvider);
    final functions = ref.read(functionsServiceProvider);
    final authUser = ref.read(authServiceProvider).currentUser;

    if (authUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    try {
      final plushId = const Uuid().v4();
      final imageUrl = await storage.uploadPlushImage(plushId, _image!);
      
      final plush = PlushModel(
        plushId: plushId,
        ownerA: authUser.uid,
        imageOriginalUrl: imageUrl,
        image2DUrl: null,
        name: _nameController.text,
        createdAt: DateTime.now(),
        inviteCode: _generateInviteCode(),
      );

      await firestore.createPlush(plush);

      // Trigger the 2D transformation
      await functions.transformPlushImage(plushId);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Plush')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Plush Name'),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _create,
                    child: const Text('Create & Generate Invite Code'),
                  ),
          ],
        ),
      ),
    );
  }
}
