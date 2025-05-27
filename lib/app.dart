import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/network_service.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/phone_verification/phone_input_screen.dart';
import 'screens/phone_verification/code_verification_screen.dart';
import 'screens/auth_result/auth_success_screen.dart';
import 'screens/auth_result/auth_failure_screen.dart';
import 'screens/home_screen.dart';

class ChapterApp extends StatelessWidget {
  const ChapterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, NetworkService>(
      builder: (context, authService, networkService, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,

          // Theme Configuration
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // Navigation Key for programmatic navigation
          navigatorKey: AppNavigator.navigatorKey,

          // Initial Route Logic
          home: _getInitialScreen(authService, networkService),

          // Route Definitions
          routes: {
            AppRoutes.splash: (context) => const SplashScreen(),
            AppRoutes.welcome: (context) => const WelcomeScreen(),
            AppRoutes.phoneVerification: (context) => const PhoneInputScreen(),
            AppRoutes.codeVerification: (context) => const CodeVerificationScreen(),
            AppRoutes.authSuccess: (context) => const AuthSuccessScreen(),
            AppRoutes.authFailure: (context) => const AuthFailureScreen(),
            AppRoutes.home: (context) => const HomeScreen(),
          },

          // Route Generation for Dynamic Routes
          onGenerateRoute: (RouteSettings settings) {
            return _generateRoute(settings, authService, networkService);
          },

          // Handle Unknown Routes
          onUnknownRoute: (RouteSettings settings) {
            return MaterialPageRoute(
              builder: (context) => _UnknownRouteScreen(
                routeName: settings.name ?? 'Unknown',
              ),
            );
          },

          // Builder for additional wrappers if needed
          builder: (context, child) {
            return ErrorBoundary(
              child: _AppWrapper(child: child!),
            );
          },
        );
      },
    );
  }

  /// Determine the initial screen based on app state
  Widget _getInitialScreen(AuthService authService, NetworkService networkService) {
    // Check network first
    if (!networkService.isConnected) {
      return const SplashScreen(); // Splash will handle network checking
    }

    // Check authentication state
    switch (authService.authState) {
      case AuthState.initial:
        return const SplashScreen();
      case AuthState.loading:
        return const SplashScreen();
      case AuthState.authenticated:
        return const HomeScreen();
      case AuthState.unauthenticated:
        return const WelcomeScreen();
      case AuthState.error:
        return const WelcomeScreen(); // Go to welcome to retry
      default:
        return const SplashScreen();
    }
  }

  /// Generate routes dynamically
  Route<dynamic>? _generateRoute(RouteSettings settings, AuthService authService, NetworkService networkService) {
    // Handle parameterized routes here if needed
    switch (settings.name) {
      case '/':
        return AppRouteTransitions.fadeTransition(
          _getInitialScreen(authService, networkService),
        );

      case '/auth_success_animated':
        return AppRouteTransitions.scaleTransition(const AuthSuccessScreen());

      case '/home_animated':
        return AppRouteTransitions.slideFromRight(const HomeScreen());

    // Add more dynamic routes as needed
      default:
        return null; // Let onUnknownRoute handle it
    }
  }
}

/// Wrapper widget for additional app-level functionality
class _AppWrapper extends StatelessWidget {
  final Widget child;

  const _AppWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Stack(
          children: [
            // Main app content
            this.child,

            // Global loading overlay
            if (authService.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Card(
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Please wait...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Screen shown for unknown routes
class _UnknownRouteScreen extends StatelessWidget {
  final String routeName;

  const _UnknownRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              AppNavigator.navigateToWelcome();
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 404 Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!, width: 2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Error message
              const Text(
                '404 - Page Not Found',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'The page "$routeName" doesn\'t exist or has been moved.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        AppNavigator.navigateToWelcome();
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => AppNavigator.navigateToWelcome(),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation helper class for programmatic navigation
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current navigator state
  static NavigatorState? get _navigator => navigatorKey.currentState;

  /// Navigate to a named route
  static Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) async {
    if (_navigator == null) return null;
    return _navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace current route with a named route
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
      String routeName, {
        TO? result,
        Object? arguments,
      }) async {
    if (_navigator == null) return null;
    return _navigator!.pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Navigate to a named route and clear the stack
  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
      String routeName,
      bool Function(Route<dynamic>) predicate, {
        Object? arguments,
      }) async {
    if (_navigator == null) return null;
    return _navigator!.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate,
      arguments: arguments,
    );
  }

  /// Pop the current route
  static void pop<T extends Object?>([T? result]) {
    if (_navigator == null) return;
    _navigator!.pop<T>(result);
  }

  /// Pop until a specific route
  static void popUntil(bool Function(Route<dynamic>) predicate) {
    if (_navigator == null) return;
    _navigator!.popUntil(predicate);
  }

  /// Check if we can pop
  static bool canPop() {
    if (_navigator == null) return false;
    return _navigator!.canPop();
  }

  /// Navigate based on auth state
  static void navigateBasedOnAuthState(AuthService authService) {
    if (authService.isAuthenticated) {
      pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } else {
      pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
    }
  }

  /// Navigate to auth success with animation
  static void navigateToAuthSuccess({bool animated = false}) {
    if (animated) {
      pushNamedAndRemoveUntil('/auth_success_animated', (route) => false);
    } else {
      pushNamedAndRemoveUntil(AppRoutes.authSuccess, (route) => false);
    }
  }

  /// Navigate to auth failure with error
  static void navigateToAuthFailure() {
    pushNamedAndRemoveUntil(AppRoutes.authFailure, (route) => false);
  }

  /// Navigate to home screen
  static void navigateToHome({bool animated = false}) {
    if (animated) {
      pushNamedAndRemoveUntil('/home_animated', (route) => false);
    } else {
      pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    }
  }

  /// Navigate to welcome screen
  static void navigateToWelcome() {
    pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
  }

  /// Navigate to splash screen
  static void navigateToSplash() {
    pushNamedAndRemoveUntil(AppRoutes.splash, (route) => false);
  }

  /// Navigate to phone verification
  static void navigateToPhoneVerification() {
    pushNamed(AppRoutes.phoneVerification);
  }

  /// Navigate to code verification
  static void navigateToCodeVerification() {
    pushNamed(AppRoutes.codeVerification);
  }

  /// Show a modal dialog
  static Future<T?> showModalDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) async {
    if (_navigator == null) return null;

    return showDialog<T>(
      context: _navigator!.context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  /// Show a bottom sheet
  static Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isScrollControlled = false,
  }) async {
    if (_navigator == null) return null;

    return showModalBottomSheet<T>(
      context: _navigator!.context,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => child,
    );
  }
}

/// Route names for type-safe navigation
class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String phoneVerification = '/phone_verification';
  static const String codeVerification = '/code_verification';
  static const String authSuccess = '/auth_success';
  static const String authFailure = '/auth_failure';
  static const String home = '/home';

  /// Get all route names
  static List<String> get allRoutes => [
    splash,
    welcome,
    phoneVerification,
    codeVerification,
    authSuccess,
    authFailure,
    home,
  ];

  /// Check if route exists
  static bool isValidRoute(String route) => allRoutes.contains(route);
}

/// Route transition animations
class AppRouteTransitions {
  /// Slide transition from right to left
  static Route<T> slideFromRight<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Slide transition from left to right
  static Route<T> slideFromLeft<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Fade transition
  static Route<T> fadeTransition<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Scale transition
  static Route<T> scaleTransition<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Custom slide and fade transition
  static Route<T> slideAndFade<T extends Object?>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.3);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Error boundary widget to catch and display errors gracefully
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails error)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();

    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error
      print('Flutter Error: ${details.exception}');
      print('Stack trace: ${details.stack}');

      // Update state to show error UI
      if (mounted) {
        setState(() {
          _error = details;
        });
      }
    };
  }

  /// Reset error state
  void _resetError() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          _DefaultErrorWidget(
            error: _error!,
            onRetry: _resetError,
          );
    }

    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final FlutterErrorDetails error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Something went wrong'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!, width: 2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'An unexpected error occurred. Please try again.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => AppNavigator.navigateToWelcome(),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Debug info (only in debug mode)
              if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                ExpansionTile(
                  title: const Text('Error Details'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        error.toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}