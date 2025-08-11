// Updated frontend/lib/main.dart
import 'package:flutter/material.dart';
import 'package:perinatal_app/features/profile/profile.dart';
import 'package:perinatal_app/features/resources/resources_list.dart';
import 'package:perinatal_app/features/support_groups/support_groups_list.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/dashboard_router.dart'; // Updated import
import 'features/journey/journey_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/services/services_list.dart';
import 'features/referrals/referral_provider.dart'; // New import
import 'providers/auth_provider.dart';
import 'features/services/services_provider.dart';
import 'features/profile/profile_provider.dart';
import 'features/profile/privacy_provider.dart';
import 'features/resources/resources_provider.dart';
import 'features/support_groups/support_groups_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PrivacyProvider()),
        ChangeNotifierProvider(create: (_) => ResourcesProvider()),
        ChangeNotifierProvider(create: (_) => SupportGroupsProvider()),
        ChangeNotifierProvider(create: (_) => JourneyProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
      ],
      child: MaterialApp(
        title: 'Perinatal Mental Health App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Inter',
          primarySwatch: Colors.blue,
        ),
        home: const AppWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardRouter(), // Updated route
          '/services': (context) => const FindServicesScreen(),
          '/resources': (context) => const ResourcesListScreen(),
          '/support-groups': (context) => const SupportGroupsListScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _showSplash = true;
  bool _authCheckComplete = false;

  @override
  void initState() {
    super.initState();

    // Start authentication check immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndWait();
    });
  }

  Future<void> _checkAuthAndWait() async {
    // Start auth check
    final authProvider = context.read<AuthProvider>();

    // Run auth check and splash timer concurrently
    await Future.wait([
      authProvider.checkAuthStatus(),
      Future.delayed(const Duration(seconds: 6)), // 6 second splash
    ]);

    // Mark auth check as complete and hide splash
    if (mounted) {
      setState(() {
        _authCheckComplete = true;
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show splash screen first
    if (_showSplash) {
      return const SplashScreen();
    }

    // After splash, show appropriate screen based on auth status
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If auth check is not complete yet, show loading
        if (!_authCheckComplete) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Navigate based on authentication status
        if (authProvider.isAuthenticated) {
          return const DashboardRouter(); // Updated to use router
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}