import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/plush_provider.dart';
import '../providers/auth_provider.dart';
import '../models/plush_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isFeeding = false;
  bool _isPlaying = false;
  bool _isCuddling = false;
  bool _isTouching = false;

  DateTime? _lastFeedTime;
  DateTime? _lastPlayTime;
  DateTime? _lastCuddleTime;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadCooldowns();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermissions();
    });
  }

  Future<void> _checkNotificationPermissions() async {
    final notificationService = ref.read(notificationServiceProvider);
    final isGranted = await notificationService.isPermissionGranted();
    
    if (!isGranted) {
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final hasSeenModal = prefs.getBool('hasSeenNotificationModal') ?? false;

      if (!hasSeenModal) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Mantente conectado!'),
            content: const Text('Para saber cuando tu pareja interactúa con el peluche o te envía notas, te sugerimos activar las notificaciones. ¿Deseas permitirlas ahora?'),
            actions: [
              TextButton(
                onPressed: () {
                  prefs.setBool('hasSeenNotificationModal', true);
                  Navigator.pop(ctx);
                },
                child: const Text('Ahora no'),
              ),
              ElevatedButton(
                onPressed: () async {
                  prefs.setBool('hasSeenNotificationModal', true);
                  Navigator.pop(ctx);
                  await notificationService.requestPermissions();
                  
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    notificationService.updateUserFcmToken(user.uid);
                  }
                },
                child: const Text('Permitir'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final feedStr = prefs.getString('lastFeedTime');
        if (feedStr != null) _lastFeedTime = DateTime.parse(feedStr);

        final playStr = prefs.getString('lastPlayTime');
        if (playStr != null) _lastPlayTime = DateTime.parse(playStr);

        final cuddleStr = prefs.getString('lastCuddleTime');
        if (cuddleStr != null) _lastCuddleTime = DateTime.parse(cuddleStr);
      });
    }
  }

  Duration _getCooldown(DateTime? lastActionTime) {
    if (lastActionTime == null) return Duration.zero;
    final now = DateTime.now();
    final difference = now.difference(lastActionTime);
    const cooldownDuration = Duration(minutes: 15);
    if (difference < cooldownDuration) {
      return cooldownDuration - difference;
    }
    return Duration.zero;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleAction(String type, VoidCallback action) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    if (mounted) {
      setState(() {
        if (type == 'feed') {
          _lastFeedTime = now;
          prefs.setString('lastFeedTime', now.toIso8601String());
        } else if (type == 'play') {
          _lastPlayTime = now;
          prefs.setString('lastPlayTime', now.toIso8601String());
        } else if (type == 'cuddle') {
          _lastCuddleTime = now;
          prefs.setString('lastCuddleTime', now.toIso8601String());
        }
      });
    }

    HapticFeedback.lightImpact();
    _triggerAnimation(type);
    action();
  }

  void _triggerAnimation(String type) {
    setState(() {
      if (type == 'feed') _isFeeding = true;
      if (type == 'play') _isPlaying = true;
      if (type == 'cuddle') _isCuddling = true;
      if (type == 'touch') _isTouching = true;
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          if (type == 'feed') _isFeeding = false;
          if (type == 'play') _isPlaying = false;
          if (type == 'cuddle') _isCuddling = false;
          if (type == 'touch') _isTouching = false;
        });
      }
    });
  }

  void _showNoteDialog(BuildContext context, String? currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send a Note ❤️'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 100,
          decoration: const InputDecoration(
            hintText: 'Write something sweet...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(plushProvider.notifier).sendNote(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note sent!')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plush = ref.watch(plushProvider);
    final user = ref.watch(userModelProvider).value;

    if (plush == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myUid = user.uid;
    final partnerUid = plush.ownerA == myUid ? plush.ownerB : plush.ownerA;

    // Logic for partner's note
    PlushNote? partnerNote;
    if (partnerUid != null && plush.notes.containsKey(partnerUid)) {
      final note = plush.notes[partnerUid]!;
      final difference = DateTime.now().difference(note.timestamp);
      if (difference.inHours < 24) {
        partnerNote = note;
      }
    }

    // Logic for my own note (to edit)
    PlushNote? myNote;
    if (plush.notes.containsKey(myUid)) {
      final note = plush.notes[myUid]!;
      final difference = DateTime.now().difference(note.timestamp);
      if (difference.inHours < 24) {
        myNote = note;
      }
    }

    Widget plushWidget = Image.network(
      plush.image2DUrl ?? plush.imageOriginalUrl,
      height: 250,
      width: 250,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 100),
    );

    if (_isFeeding) {
      plushWidget = plushWidget.animate(key: const ValueKey('feed'))
        .scale(duration: 500.ms, curve: Curves.easeOut, begin: const Offset(1,1), end: const Offset(1.06, 1.02))
        .then()
        .scale(duration: 500.ms, curve: Curves.easeInOut, begin: const Offset(1.06, 1.02), end: const Offset(1,1));
    } else if (_isPlaying) {
      plushWidget = plushWidget.animate(key: const ValueKey('play'))
        .moveY(begin: 0, end: -25, duration: 400.ms, curve: Curves.easeOut)
        .shakeX(hz: 3, amount: 2, duration: 800.ms)
        .then()
        .moveY(begin: -25, end: 0, duration: 400.ms, curve: Curves.bounceOut);
    } else if (_isCuddling) {
      plushWidget = plushWidget.animate(key: const ValueKey('cuddle'))
        .scale(duration: 500.ms, curve: Curves.easeInOut, begin: const Offset(1,1), end: const Offset(1.04, 0.96))
        .shakeX(hz: 2, amount: 1.5, duration: 1000.ms)
        .then()
        .scale(duration: 500.ms, curve: Curves.easeInOut, begin: const Offset(1.04, 0.96), end: const Offset(1, 1));
    } else if (_isTouching) {
       plushWidget = plushWidget.animate(key: const ValueKey('touch'))
        .scale(duration: 150.ms, curve: Curves.easeOut, begin: const Offset(1,1), end: const Offset(1.01, 0.99))
        .then()
        .scale(duration: 250.ms, curve: Curves.easeInOut, begin: const Offset(1.01, 0.99), end: const Offset(1, 1));
    } else {
      plushWidget = plushWidget.animate(key: const ValueKey('idle'), onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 0.95), duration: 1000.ms, curve: Curves.easeInOut);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plush.name,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Level ${plush.level}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (plush.ownerB == null)
                        Chip(
                          label: Text('Code: ${plush.inviteCode}'),
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showNoteDialog(context, myNote?.text),
                        icon: Icon(myNote == null ? Icons.edit_note : Icons.mark_chat_read, 
                          color: AppTheme.primaryColor, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Animated Plush with Notes and Particles
            Center(
              child: SizedBox(
                width: 350,
                height: 350,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _triggerAnimation('touch');
                        ref.read(plushProvider.notifier).squeeze();
                      },
                      child: Hero(
                        tag: 'plush',
                        child: plushWidget,
                      ),
                    ),

                    // Partner's Note (Envelope or Post-it)
                    if (partnerNote != null)
                      Positioned(
                        top: 10, // Adjusted for 350x350 stack (Plush top is at 50, so 10 is 40px above)
                        right: 30, // Adjusted (Plush right is at 300, so 30 is 20px outside)
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (!partnerNote!.readByPartner) {
                              ref.read(plushProvider.notifier).readNote(partnerUid!);
                            }
                            // Show the note text in a dialog too
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFFFFF9C4), // Post-it Yellow
                                shape: const RoundedRectangleBorder(),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.push_pin, color: Colors.redAccent),
                                    const SizedBox(height: 16),
                                    Text(
                                      partnerNote!.text,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto', // Ideally a handwriting font
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Shared ${partnerNote.timestamp.hour}:${partnerNote.timestamp.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: _buildNoteWidget(partnerNote).animate()
                            .shake(duration: 500.ms)
                            .scale(duration: 300.ms, curve: Curves.bounceIn),
                        ),
                      ),

                  Positioned(
                    bottom: 40, // Adjusted to be inside 350x350 (Plush bottom is at 300)
                    left: 30, // Adjusted (Plush left is at 50, so 30 is 20px outside)
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _triggerAnimation('touch');
                        ref.read(plushProvider.notifier).squeeze();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Touch sent!')),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.touch_app, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            const Spacer(),
            // Status Bars
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatusBar('Hunger', plush.hunger / 100, Colors.orangeAccent),
                      const SizedBox(height: 12),
                      _buildStatusBar('Happiness', plush.happiness / 100, Colors.pinkAccent),
                      const SizedBox(height: 12),
                      _buildStatusBar('Energy', plush.energy / 100, Colors.blueAccent),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.restaurant, 'Feed', () {
                    _handleAction('feed', () {
                      ref.read(plushProvider.notifier).feed();
                    });
                  }, AppTheme.secondaryColor, _getCooldown(_lastFeedTime)),
                  _buildActionButton(Icons.videogame_asset, 'Play', () {
                    _handleAction('play', () {
                      ref.read(plushProvider.notifier).play();
                    });
                  }, AppTheme.tertiaryColor, _getCooldown(_lastPlayTime)),
                  _buildActionButton(Icons.favorite, 'Cuddle', () {
                    _handleAction('cuddle', () {
                      ref.read(plushProvider.notifier).cuddle();
                    });
                  }, AppTheme.accentColor, _getCooldown(_lastCuddleTime)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteWidget(PlushNote note) {
    if (!note.readByPartner) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.mail, color: Colors.redAccent, size: 40),
      );
    } else {
      return Container(
        width: 88,
        height: 80,
        padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF176), // Post-it Yellow
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 4, offset: const Offset(2, 2)),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.push_pin, size: 12, color: Colors.redAccent),
            const SizedBox(height: 2),
            Text(
              note.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${(value * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color, Duration cooldown) {
    final bool isOnCooldown = cooldown > Duration.zero;

    Widget buttonContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnCooldown ? Colors.grey.shade400 : color,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isOnCooldown)
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );

    Widget inkWell = InkWell(
      onTap: isOnCooldown ? null : onTap,
      borderRadius: BorderRadius.circular(50),
      child: buttonContent,
    );

    if (!isOnCooldown) {
      inkWell = inkWell.animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(
           begin: const Offset(1, 1),
           end: const Offset(1.1, 1.1),
           duration: 2000.ms,
           curve: Curves.easeInOut,
         );
    }

    return Column(
      children: [
        inkWell,
        const SizedBox(height: 12),
        Text(
          isOnCooldown ? _formatDuration(cooldown) : label,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w500,
            color: isOnCooldown ? Colors.grey.shade600 : null,
          ),
        ),
      ],
    );
  }
}
