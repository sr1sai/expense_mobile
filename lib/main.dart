import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'Screens/login_screen.dart';
import 'Screens/register_screen.dart';
import 'Screens/transactions_screen.dart';
import 'theme.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider, CounterProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() {
  // Initialize the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state to all widgets
    // When adding new providers, include them in the providers list below
    return MultiProvider(
      providers: [
        // Counter provider for managing counter state
        ChangeNotifierProvider(create: (_) => CounterProvider()),

        // TODO (agent): Add new providers here as you extend the app
        // Example:
        // ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp.router(
        title: 'Dreamflow Starter',
        debugShowCheckedModeBanner: false,

        // Theme configuration
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,

        // Router configuration
        // TODO (agent): Replace with AppRouter.router when you have more
        // routes. Use context.go() or context.push() to navigate to the routes.
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
            // Home route
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (context, state) => NoTransitionPage(
                child: const MyHomePage(title: 'Dreamflow Starter Project'),
              ),
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
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final counterProvider = Provider.of<CounterProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBarTheme.of(context).backgroundColor,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '${counterProvider.counter}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counterProvider.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CounterProvider extends ChangeNotifier {
  int _counter = 0;

  /// Current counter value
  int get counter => _counter;

  /// Increment the counter and notify listeners
  void increment() {
    _counter++;
    notifyListeners();
  }

  /// Reset the counter to zero
  void reset() {
    if (_counter != 0) {
      _counter = 0;
      notifyListeners();
    }
  }
}
