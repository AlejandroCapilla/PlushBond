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
  bool _isFinished = false;

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

    setState(() {
      _isLoading = true;
      _isFinished = false;
    });
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
        lastUpdate: DateTime.now(),
        inviteCode: _generateInviteCode(),
      );

      await firestore.createPlush(plush);

      // Trigger the 2D transformation
      await functions.transformPlushImage(plushId);
      
      // Update FCM token since now the user has a plush document
      await ref.read(notificationServiceProvider).updateUserFcmToken(authUser.uid);

      if (mounted) setState(() => _isFinished = true);
      await Future.delayed(const Duration(milliseconds: 600));

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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                ElevatedButton(
                  onPressed: _isLoading ? null : _create,
                  child: const Text('Create & Generate Invite Code'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {}, // Absorb all taps
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/images/plush_loading.png',
                            width: 250,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Crafting your plush...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 64.0),
                        child: _FakeProgressBar(isFinished: _isFinished),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FakeProgressBar extends StatefulWidget {
  final bool isFinished;
  const _FakeProgressBar({required this.isFinished});

  @override
  State<_FakeProgressBar> createState() => _FakeProgressBarState();
}

class _FakeProgressBarState extends State<_FakeProgressBar> {
  double _target = 0.0;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startFakeProgress();
  }

  @override
  void didUpdateWidget(_FakeProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFinished && !oldWidget.isFinished) {
      setState(() {
        _target = 1.0;
        _duration = const Duration(milliseconds: 400);
      });
    }
  }

  Future<void> _startFakeProgress() async {
    // 1. Initial moderate load
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || widget.isFinished) return;
    setState(() {
      _target = 0.35;
      _duration = const Duration(milliseconds: 2500);
    });

    // 2. Stop for a few seconds
    await Future.delayed(const Duration(milliseconds: 4500)); // 2.5s animating + 2s stop

    // 3. Load up to near the end
    if (!mounted || widget.isFinished) return;
    setState(() {
      _target = 0.88;
      _duration = const Duration(milliseconds: 2000);
    });

    // 4. Advance ultra slowly
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted || widget.isFinished) return;
    setState(() {
      _target = 0.98;
      _duration = const Duration(seconds: 25);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _target),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
