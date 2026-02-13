import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Capture Reality',
      'description': 'Take a photo of your favorite real-life plush toy.',
      'image': 'https://illustrations.popsy.co/pastel/taking-a-photo.svg',
    },
    {
      'title': 'Digital Magic',
      'description': 'Watch your plush come to life as a cute 2D digital companion.',
      'image': 'https://illustrations.popsy.co/pastel/cat-sitting-on-blocks.svg',
    },
    {
      'title': 'Shared Care',
      'description': 'Invite your partner and care for your companion together daily.',
      'image': 'https://illustrations.popsy.co/pastel/friendship.svg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(_pages[index]['image']!, height: 300)
                        .animate()
                        .fade(duration: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 48),
                    Text(
                      _pages[index]['title']!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pages[index]['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primaryColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_currentPage == _pages.length - 1) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('showOnboarding', false);
                        ref.read(onboardingProvider.notifier).state = false;
                      } else {
                        _pageController.nextPage(
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
