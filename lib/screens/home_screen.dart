import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/plush_provider.dart';
import '../providers/auth_provider.dart';
import '../models/plush_model.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showNoteDialog(BuildContext context, WidgetRef ref, String? currentText) {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                        onPressed: () => _showNoteDialog(context, ref, myNote?.text),
                        icon: Icon(myNote == null ? Icons.edit_note : Icons.mark_chat_read, 
                          color: AppTheme.primaryColor, size: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Animated Plush with Notes
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(plushProvider.notifier).squeeze();
                    }, // Trigger bounce
                    child: Hero(
                      tag: 'plush',
                      child: Image.network(
                        plush.image2DUrl ?? plush.imageOriginalUrl,
                        height: 250,
                        width: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 100),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.05, 0.95), duration: 1000.ms, curve: Curves.easeInOut),
                  ),

                  // Partner's Note (Envelope or Post-it)
                  if (partnerNote != null)
                    Positioned(
                      top: -40,
                      right: -20,
                      child: GestureDetector(
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
                ],
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
                    HapticFeedback.lightImpact();
                    ref.read(plushProvider.notifier).feed();
                  }, AppTheme.secondaryColor),
                  _buildActionButton(Icons.videogame_asset, 'Play', () {
                    HapticFeedback.lightImpact();
                    ref.read(plushProvider.notifier).play();
                  }, AppTheme.tertiaryColor),
                  _buildActionButton(Icons.favorite, 'Cuddle', () {
                    HapticFeedback.lightImpact();
                    ref.read(plushProvider.notifier).cuddle();
                  }, AppTheme.accentColor),
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
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF176), // Post-it Yellow
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 4, offset: const Offset(2, 2)),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.push_pin, size: 16, color: Colors.redAccent),
            const SizedBox(height: 4),
            Text(
              note.text,
              maxLines: 2,
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(
           begin: const Offset(1, 1),
           end: const Offset(1.1, 1.1),
           duration: 2000.ms,
           curve: Curves.easeInOut,
         ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
