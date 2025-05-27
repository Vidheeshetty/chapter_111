import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Authentication Debug Helper
///
/// Provides comprehensive debugging for authentication flows.
/// Only runs in debug mode - safe for production builds.
class AuthDebugHelper {

  /// Log current authentication state
  static void logAuthState() {
    if (!kDebugMode) return;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    print('🔍 === AUTH STATE DEBUG ===');
    print('📱 Current User: ${user?.uid ?? 'null'}');
    print('📧 Email: ${user?.email ?? 'null'}');
    print('📞 Phone: ${user?.phoneNumber ?? 'null'}');
    print('👤 Display Name: ${user?.displayName ?? 'null'}');
    print('✅ Email Verified: ${user?.emailVerified ?? false}');
    print('🔄 Anonymous: ${user?.isAnonymous ?? false}');
    print('⏰ Created: ${user?.metadata.creationTime ?? 'unknown'}');
    print('🔄 Last Sign In: ${user?.metadata.lastSignInTime ?? 'unknown'}');

    if (user?.providerData.isNotEmpty == true) {
      print('🔗 Providers:');
      for (final provider in user!.providerData) {
        print('   - ${provider.providerId}: ${provider.uid}');
        print('     Email: ${provider.email ?? 'null'}');
        print('     Phone: ${provider.phoneNumber ?? 'null'}');
        print('     Display Name: ${provider.displayName ?? 'null'}');
      }
    }

    print('🔍 === END AUTH STATE ===');
  }

  /// Log Google Sign-In specific state
  static void logGoogleSignInState() async {
    if (!kDebugMode) return;

    final googleSignIn = GoogleSignIn();

    print('🔍 === GOOGLE SIGN-IN STATE ===');
    print('📱 Current User: ${googleSignIn.currentUser?.email ?? 'null'}');
    print('🔄 Is Signed In: ${await googleSignIn.isSignedIn()}');

    final account = googleSignIn.currentUser;
    if (account != null) {
      print('👤 Display Name: ${account.displayName}');
      print('📧 Email: ${account.email}');
      print('🆔 ID: ${account.id}');
      print('🖼️ Photo URL: ${account.photoUrl ?? 'null'}');
      print('🔑 Server Auth Code: ${account.serverAuthCode ?? 'null'}');
    }

    print('🔍 === END GOOGLE STATE ===');
  }

  /// Log Firebase configuration details
  static void logFirebaseConfig() {
    if (!kDebugMode) return;

    final auth = FirebaseAuth.instance;

    print('🔍 === FIREBASE CONFIG ===');
    print('🏠 App Name: ${auth.app.name}');
    print('🔑 Project ID: ${auth.app.options.projectId}');
    print('📱 App ID: ${auth.app.options.appId}');
    print('🌐 Auth Domain: ${auth.app.options.authDomain ?? 'null'}');
    print('🔥 API Key: ${auth.app.options.apiKey.substring(0, 10)}...');
    print('📊 Measurement ID: ${auth.app.options.measurementId ?? 'null'}');
    print('🗄️ Storage Bucket: ${auth.app.options.storageBucket ?? 'null'}');
    print('📬 Messaging Sender ID: ${auth.app.options.messagingSenderId ?? 'null'}');
    print('🔍 === END CONFIG ===');
  }

  /// Log detailed error information
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    print('❌ === ERROR in $context ===');
    print('🚨 Error: $error');
    print('📍 Type: ${error.runtimeType}');
    print('⏰ Time: ${DateTime.now()}');

    if (error is FirebaseAuthException) {
      print('🔥 Firebase Error Details:');
      print('   Code: ${error.code}');
      print('   Message: ${error.message}');
      print('   Email: ${error.email ?? 'null'}');
      print('   Phone: ${error.phoneNumber ?? 'null'}');
      print('   Credential: ${error.credential?.providerId ?? 'null'}');
      print('   Tenant ID: ${error.tenantId ?? 'null'}');
    }

    if (error is Exception) {
      print('🔥 Exception Details: ${error.toString()}');
    }

    if (stackTrace != null) {
      print('📚 Stack Trace:');
      final lines = stackTrace.toString().split('\n');
      for (int i = 0; i < lines.length && i < 10; i++) {
        print('   ${lines[i]}');
      }
      if (lines.length > 10) {
        print('   ... (${lines.length - 10} more lines)');
      }
    }

    print('❌ === END ERROR ===');
  }

  /// Log phone authentication state
  static void logPhoneAuthState(String? verificationId, String? phoneNumber) {
    if (!kDebugMode) return;

    print('🔍 === PHONE AUTH STATE ===');
    print('📞 Phone Number: ${phoneNumber ?? 'null'}');
    print('🔑 Verification ID: ${verificationId != null ? 'present' : 'null'}');
    print('📏 ID Length: ${verificationId?.length ?? 0}');
    if (verificationId != null) {
      print('🔑 ID Preview: ${verificationId.substring(0, 20)}...');
    }
    print('⏰ Time: ${DateTime.now()}');
    print('🔍 === END PHONE AUTH ===');
  }

  /// Log network connectivity state
  static void logNetworkState(bool isConnected) {
    if (!kDebugMode) return;

    print('🔍 === NETWORK STATE ===');
    print('🌐 Connected: ${isConnected ? '✅' : '❌'}');
    print('⏰ Time: ${DateTime.now()}');
    print('🔍 === END NETWORK ===');
  }

  /// Mark the start of an authentication flow
  static void startAuthFlow(String flowName) {
    if (!kDebugMode) return;

    print('\n🚀 === STARTING $flowName ===');
    print('⏰ Time: ${DateTime.now()}');
    logAuthState();
    logFirebaseConfig();
    print('🚀 === $flowName INITIALIZED ===\n');
  }

  /// Mark the end of an authentication flow
  static void endAuthFlow(String flowName, bool success) {
    if (!kDebugMode) return;

    print('\n${success ? '✅' : '❌'} === $flowName ${success ? 'SUCCESS' : 'FAILED'} ===');
    print('⏰ Time: ${DateTime.now()}');
    if (success) {
      logAuthState();
    }
    print('${success ? '✅' : '❌'} === END $flowName ===\n');
  }

  /// Validate app setup and configuration
  static void validateSetup() {
    if (!kDebugMode) return;

    print('\n🔍 === SETUP VALIDATION ===');

    // Firebase Auth validation
    try {
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized');
      print('   🏠 App: ${auth.app.name}');
      print('   🔑 Project: ${auth.app.options.projectId}');
      print('   📱 App ID: ${auth.app.options.appId}');
    } catch (e) {
      print('❌ Firebase Auth setup issue: $e');
    }

    // Google Sign-In validation
    try {
      final googleSignIn = GoogleSignIn();
      print('✅ Google Sign-In initialized');
      print('   📧 Scopes: ${googleSignIn.scopes}');
    } catch (e) {
      print('❌ Google Sign-In setup issue: $e');
    }

    // Additional validations
    try {
      final auth = FirebaseAuth.instance;
      if (auth.app.options.apiKey.isEmpty) {
        print('⚠️  Warning: API Key is empty');
      }
      if (auth.app.options.projectId.isEmpty) {
        print('⚠️  Warning: Project ID is empty');
      }
    } catch (e) {
      print('⚠️  Warning: Could not validate Firebase config: $e');
    }

    print('🔍 === END VALIDATION ===\n');
  }

  /// Log user interaction event
  static void logUserAction(String action, {Map<String, dynamic>? data}) {
    if (!kDebugMode) return;

    print('👆 === USER ACTION: $action ===');
    print('⏰ Time: ${DateTime.now()}');
    if (data != null) {
      data.forEach((key, value) {
        print('   $key: $value');
      });
    }
    print('👆 === END ACTION ===');
  }

  /// Log authentication method attempt
  static void logAuthAttempt(String method, String status) {
    if (!kDebugMode) return;

    final emoji = status == 'start' ? '🏁' :
    status == 'success' ? '✅' :
    status == 'failure' ? '❌' : '🔄';

    print('$emoji AUTH ATTEMPT: $method - ${status.toUpperCase()}');
    print('   ⏰ ${DateTime.now()}');
  }

  /// Quick debug summary
  static void quickSummary() {
    if (!kDebugMode) return;

    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    print('📊 === QUICK DEBUG SUMMARY ===');
    print('   Auth: ${user != null ? '✅ Signed In' : '❌ Not Signed In'}');
    if (user != null) {
      print('   User: ${user.displayName ?? user.email ?? user.phoneNumber ?? 'Unknown'}');
      print('   UID: ${user.uid.substring(0, 8)}...');
      print('   Providers: ${user.providerData.map((p) => p.providerId).join(', ')}');
    }
    print('   Project: ${auth.app.options.projectId}');
    print('   Time: ${DateTime.now().toString().split('.')[0]}');
    print('📊 === END SUMMARY ===');
  }

  /// Performance timing helper
  static final Map<String, DateTime> _timers = {};

  static void startTimer(String name) {
    if (!kDebugMode) return;
    _timers[name] = DateTime.now();
    print('⏱️  Started timer: $name');
  }

  static void endTimer(String name) {
    if (!kDebugMode) return;
    final start = _timers[name];
    if (start != null) {
      final duration = DateTime.now().difference(start);
      print('⏱️  Timer $name: ${duration.inMilliseconds}ms');
      _timers.remove(name);
    }
  }
}