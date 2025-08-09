import 'package:flutter/material.dart';
import 'package:perinatal_app/features/profile/profile.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/dashboard.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/services/services_list.dart';
import 'providers/auth_provider.dart';
import 'features/services/services_provider.dart';

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
          '/dashboard': (context) => const DashboardScreen(),
          '/services': (context) => const FindServicesScreen(),
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
  @override
  void initState() {
    super.initState();
    // Check authentication status when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash screen while checking auth status
        if (authProvider.isLoading) {
          return const SplashScreen();
        }

        // Navigate based on authentication status
        if (authProvider.isAuthenticated) {
          return const DashboardScreen();
        } else {
          return const SplashScreenWithNavigation();
        }
      },
    );
  }
}

// Updated splash screen that navigates to login
class SplashScreenWithNavigation extends StatefulWidget {
  const SplashScreenWithNavigation({super.key});

  @override
  State<SplashScreenWithNavigation> createState() => _SplashScreenWithNavigationState();
}

class _SplashScreenWithNavigationState extends State<SplashScreenWithNavigation> {
  @override
  void initState() {
    super.initState();
    // Navigate to login after splash screen duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
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