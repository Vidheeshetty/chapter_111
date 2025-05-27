import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';
import 'services/network_service.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'utils/app_logger.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Handle uncaught errors in debug mode
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('🚨 Flutter Error: ${details.exception}');
      print('📍 Context: ${details.context}');
      if (details.stack != null) {
        print('📚 Stack: ${details.stack.toString().split('\n').take(5).join('\n')}');
      }
    };
  }

  // Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for better appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    print('🚀 === Initializing Chapter 11 App (Simplified Auth) ===');

    // Initialize Firebase with detailed logging
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize storage service
    print('💾 Initializing Storage Service...');
    final storageService = StorageService();
    await storageService.initialize();
    print('✅ Storage Service initialized');

    // Initialize network service
    print('🌐 Initializing Network Service...');
    final networkService = NetworkService();
    await networkService.initialize();
    print('✅ Network Service initialized - Connected: ${networkService.isConnected}');

    // Initialize simplified auth service
    print('🔐 Initializing Simplified Auth Service...');
    final authService = AuthService();
    await authService.initialize();
    print('✅ Auth Service initialized');

    if (kDebugMode) {
      print('📊 Auth Status: ${authService.isAuthenticated ? 'Authenticated' : 'Not Authenticated'}');
      if (authService.isAuthenticated) {
        print('👤 Current user: ${authService.currentUser?.uid ?? 'Phone User'}');
        print('📧 Email: ${authService.currentUser?.email ?? 'N/A'}');
        print('📞 Phone: ${authService.phoneNumber ?? 'N/A'}');
        print('🔄 Auth method: ${authService.lastMethod ?? 'Unknown'}');
      }
      print('🎯 Hardcoded values: Phone=7718059613, Code=123456');
    }

    print('🎉 All services initialized successfully!');
    print('🚀 Starting Chapter 11 App with Simplified Authentication...\n');

    // Run the app with providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NetworkService>.value(value: networkService),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          // Add more providers here as needed
        ],
        child: const ChapterApp(),
      ),
    );

  } catch (e, stackTrace) {
    print('\n❌ === CRITICAL INITIALIZATION ERROR ===');
    print('🚨 Error: $e');
    print('🔍 Type: ${e.runtimeType}');
    print('⏰ Time: ${DateTime.now()}');

    if (kDebugMode) {
      print('📚 Stack trace (first 10 lines):');
      final lines = stackTrace.toString().split('\n');
      for (int i = 0; i < lines.length && i < 10; i++) {
        print('   ${lines[i]}');
      }
    }

    // Log error using app logger if available
    try {
      AppLogger.e('Critical app initialization error', e, stackTrace);
    } catch (loggerError) {
      print('⚠️  Logger also failed: $loggerError');
    }

    print('❌ === END CRITICAL ERROR ===\n');

    // Show comprehensive error screen
    runApp(
      MaterialApp(
        title: 'Chapter 11 - Initialization Error',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          fontFamily: 'Poppins',
        ),
        home: _ErrorScreen(
          error: e.toString(),
          stackTrace: kDebugMode ? stackTrace.toString() : null,
        ),
      ),
    );
  }
}

/// Error screen shown when app initialization fails
class _ErrorScreen extends StatelessWidget {
  final String error;
  final String? stackTrace;

  const _ErrorScreen({
    required this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Error icon with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red[50],
                                border: Border.all(
                                  color: Colors.red[200]!,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Error title
                      const Text(
                        'App Initialization Failed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Error description
                      Text(
                        'We encountered an issue while starting the app. This is usually due to a configuration problem.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Common solutions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Try These Solutions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• Check your internet connection\n'
                                  '• Restart the app\n'
                                  '• Update the app if available\n'
                                  '• Clear app cache and restart\n'
                                  '• Contact support if the issue persists',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Debug info in debug mode
                      if (kDebugMode && stackTrace != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bug_report,
                                      color: Colors.grey[700], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Debug Information:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Error details
                              Text(
                                error,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Column(
                children: [
                  // Restart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Force close the app - user will need to restart manually
                        SystemNavigator.pop();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Restart App'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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