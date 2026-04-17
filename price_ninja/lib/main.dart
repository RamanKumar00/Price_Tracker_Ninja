import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme_config.dart';

import 'providers/providers.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/alerts_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/onboarding_provider.dart';
import 'screens/onboarding_screen.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Request notification permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  
  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const ProviderScope(child: PriceNinjaApp()));
}

class PriceNinjaApp extends ConsumerWidget {
  const PriceNinjaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Price Ninja',
      debugShowCheckedModeBanner: false,
      theme: NinjaTheme.lightTheme,
      darkTheme: NinjaTheme.darkTheme,
      themeMode: themeMode,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends ConsumerStatefulWidget {
  const _AppShell();

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  bool _showSplash = true;

  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onDone: () => setState(() => _showSplash = false),
      );
    }

    final authStateAsync = ref.watch(authStateProvider);
    final hasSeenOnboarding = ref.watch(onboardingProvider);

    if (!hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    return authStateAsync.when(
      loading: () => Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))),
      error: (e, __) => Scaffold(
          body: Center(
              child: Text('Auth Error: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)))),
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }
        final currentIndex = ref.watch(bottomNavIndexProvider);

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey<int>(currentIndex),
              child: _screens[currentIndex],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (i) => ref.read(bottomNavIndexProvider.notifier).state = i,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Dashboard'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline),
                    activeIcon: Icon(Icons.add_circle_rounded),
                    label: 'Add'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_outlined),
                    activeIcon: Icon(Icons.notifications_rounded),
                    label: 'Alerts'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.settings_outlined),
                    activeIcon: Icon(Icons.settings_rounded),
                    label: 'Settings'),
              ],
            ),
          ),
        );
      },
    );
  }
}
