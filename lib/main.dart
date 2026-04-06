import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/create_join_selector_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/plush_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('showOnboarding') ?? true;
  
  final container = ProviderContainer();
  container.read(onboardingProvider.notifier).state = showOnboarding;

  runApp(UncontrolledProviderScope(
    container: container,
    child: const PlushBondApp(),
  ));
}

class PlushBondApp extends ConsumerWidget {
  const PlushBondApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final showOnboarding = ref.watch(onboardingProvider);

    // Listen to auth state and update FCM token when user is logged in
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        ref.read(notificationServiceProvider).updateUserFcmToken(next.value!.uid);
      }
    });

    return MaterialApp(
      title: 'PlushBond',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showOnboarding 
        ? const OnboardingScreen()
        : authState.when(
            data: (user) {
              if (user == null) return const AuthScreen();
              return const MainScreenContainer();
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, s) => Scaffold(body: Center(child: Text(e.toString()))),
          ),
    );
  }
}

class MainScreenContainer extends ConsumerWidget {
  const MainScreenContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plush = ref.watch(plushProvider);
    
    // If user has a plush, show home, otherwise show create/join selector
    if (plush == null) {
      return const CreateJoinSelectorScreen();
    }
    
    return const HomeScreen();
  }
}
