import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Screens/transactions_screen.dart';
import 'Services/permission_service.dart';
import 'theme.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Request SMS permission at app startup
  await PermissionService.requestSmsPermission();

  // Initialize the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dreamflow Starter',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      // Router configuration
      routerConfig: GoRouter(
        routes: [
          // Login route
          GoRoute(
            path: '/',
            name: 'login',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const LoginScreen()),
          ),

          // Register route
          GoRoute(
            path: '/register',
            name: 'register',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const RegisterScreen()),
          ),

          // Transactions route
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const TransactionsScreen()),
          ),
        ],
      ),
    );
  }
}
