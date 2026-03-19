import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/plush_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plush = ref.watch(plushProvider);

    if (plush == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
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
                  if (plush.ownerB == null)
                    Chip(
                      label: Text('Code: ${plush.inviteCode}'),
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                ],
              ),
            ),
            const Spacer(),
            // Animated Plush
            Center(
              child: GestureDetector(
                onTap: () {}, // Trigger bounce
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
                    ref.read(plushProvider.notifier).feed();
                  }, AppTheme.secondaryColor),
                  _buildActionButton(Icons.videogame_asset, 'Play', () {
                    ref.read(plushProvider.notifier).play();
                  }, AppTheme.tertiaryColor),
                  _buildActionButton(Icons.favorite, 'Cuddle', () {
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
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
