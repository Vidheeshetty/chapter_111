import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMethod { phone, google }
enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthService extends ChangeNotifier {
  // Firebase instances
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    forceCodeForRefreshToken: true,
  );

  // Auth state
  AuthState _authState = AuthState.initial;
  String? _errorMessage;
  AuthMethod? _lastMethod;

  // User info
  String? _phoneNumber;
  bool _isPhoneVerified = false;
  GoogleSignInAccount? _googleAccount;
  User? _currentUser;

  // Hardcoded values - ONLY THESE ARE HARDCODED
  static const String HARDCODED_PHONE = "7718059613";
  static const String HARDCODED_CODE = "123456";

  // Getters
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;
  AuthMethod? get lastMethod => _lastMethod;
  String? get phoneNumber => _phoneNumber;
  bool get isPhoneVerified => _isPhoneVerified;
  GoogleSignInAccount? get googleAccount => _googleAccount;
  User? get currentUser => _currentUser;

  Future<void> initialize() async {
    _authState = AuthState.initial;

    try {
      // Listen to auth state changes for Google Sign-In only
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

      // Check current user (Google only)
      _currentUser = _firebaseAuth.currentUser;

      if (_currentUser != null) {
        await _loadAuthMethod();
        _authState = AuthState.authenticated;
        print('User already authenticated: ${_currentUser!.uid}');
      } else {
        _authState = AuthState.unauthenticated;
      }
    } catch (e) {
      print('Error during initialization: $e');
      _authState = AuthState.unauthenticated;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void _onAuthStateChanged(User? user) async {
    print('Auth state changed: ${user?.uid}');
    _currentUser = user;

    if (user != null && _lastMethod == AuthMethod.google) {
      _authState = AuthState.authenticated;
      await _saveAuthMethod();
    } else if (user == null && _lastMethod == AuthMethod.google) {
      _authState = AuthState.unauthenticated;
      _lastMethod = null;
      _phoneNumber = null;
      _isPhoneVerified = false;
      _googleAccount = null;
    }

    notifyListeners();
  }

  Future<void> _loadAuthMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authMethod = prefs.getString('authMethod');

      if (authMethod == 'google') {
        _lastMethod = AuthMethod.google;
        _googleAccount = _googleSignIn.currentUser;
      } else if (authMethod == 'phone') {
        _lastMethod = AuthMethod.phone;
        _phoneNumber = prefs.getString('phoneNumber');
        _isPhoneVerified = true;
      }
    } catch (e) {
      print('Error loading auth method: $e');
    }
  }

  Future<void> _saveAuthMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastMethod == AuthMethod.google) {
        await prefs.setString('authMethod', 'google');
      } else if (_lastMethod == AuthMethod.phone) {
        await prefs.setString('authMethod', 'phone');
        if (_phoneNumber != null) {
          await prefs.setString('phoneNumber', _phoneNumber!);
        }
      }
    } catch (e) {
      print('Error saving auth method: $e');
    }
  }

  // Google Sign In - Keep Firebase implementation
  Future<bool> signInWithGoogle() async {
    print('=== Starting Google Sign-In ===');

    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Clear any previous sign-in
      await _googleSignIn.signOut();
      await Future.delayed(const Duration(milliseconds: 500));

      print('Initiating Google Sign-In flow...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        _authState = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      print('Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('✅ Firebase sign-in successful!');
        print('User ID: ${userCredential.user!.uid}');
        print('Email: ${userCredential.user!.email}');

        _googleAccount = googleUser;
        _lastMethod = AuthMethod.google;
        _authState = AuthState.authenticated;
        _currentUser = userCredential.user;

        await _saveAuthMethod();
        notifyListeners();

        return true;
      } else {
        throw Exception('Firebase authentication returned null user');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      _authState = AuthState.error;
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      _authState = AuthState.error;
      _errorMessage = 'Google Sign-in failed. Please check your internet connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // HARDCODED Phone verification - No Firebase involved
  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    print('=== Starting Hardcoded Phone Verification ===');
    print('Phone number: $phoneNumber');

    _authState = AuthState.loading;
    _lastMethod = AuthMethod.phone;
    _errorMessage = null;
    _phoneNumber = phoneNumber;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if phone number contains hardcoded value - be very lenient
    if (phoneNumber.contains(HARDCODED_PHONE) ||
        phoneNumber.contains("91 $HARDCODED_PHONE") ||
        phoneNumber.endsWith(HARDCODED_PHONE)) {
      print('✅ Hardcoded phone number accepted');
      _authState = AuthState.unauthenticated; // Ready for code verification
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      print('❌ Phone number not accepted');
      _authState = AuthState.error;
      _errorMessage = 'Please use the test number: $HARDCODED_PHONE';
      notifyListeners();
      return false;
    }
  }

  // HARDCODED SMS code verification - No Firebase involved
  Future<bool> verifySmsCode(String smsCode) async {
    print('=== Verifying Hardcoded SMS Code ===');
    print('Code: $smsCode');

    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (smsCode == HARDCODED_CODE) {
      print('✅ Hardcoded verification code accepted');

      _isPhoneVerified = true;
      _lastMethod = AuthMethod.phone;
      _authState = AuthState.authenticated;

      // Save auth method for phone
      await _saveAuthMethod();

      print('✅ Phone verification successful (hardcoded mode)');
      notifyListeners();
      return true;
    } else {
      print('❌ Invalid code. Expected: $HARDCODED_CODE');
      _authState = AuthState.error;
      _errorMessage = 'Invalid code. Use $HARDCODED_CODE for testing.';
      notifyListeners();
      return false;
    }
  }

  // Resend verification code (hardcoded)
  Future<bool> resendVerificationCode() async {
    if (_phoneNumber == null) {
      _errorMessage = 'No phone number available for resend.';
      notifyListeners();
      return false;
    }

    print('=== Resending Hardcoded Verification Code ===');
    return await verifyPhoneNumber(_phoneNumber!);
  }

  // Enhanced sign out
  Future<void> signOut() async {
    print('=== Signing Out ===');
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Sign out from Firebase (Google only)
      if (_lastMethod == AuthMethod.google) {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      }

      // Clear saved auth state
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset state
      _authState = AuthState.unauthenticated;
      _lastMethod = null;
      _phoneNumber = null;
      _isPhoneVerified = false;
      _googleAccount = null;
      _currentUser = null;
      _errorMessage = null;

      print('✅ Sign out successful');
      notifyListeners();
    } catch (e) {
      print('❌ Sign out error: $e');
      _errorMessage = 'Sign out failed. Please try again.';
      _authState = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  // Reset error state
  void resetError() {
    _errorMessage = null;
    if (_authState == AuthState.error) {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Helper method to get user-friendly error messages
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different account.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Get user display name
  String? getUserDisplayName() {
    if (_lastMethod == AuthMethod.google && _currentUser != null) {
      if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        return _currentUser!.displayName;
      }
      if (_currentUser!.email != null && _currentUser!.email!.isNotEmpty) {
        return _currentUser!.email!.split('@')[0];
      }
    } else if (_lastMethod == AuthMethod.phone && _phoneNumber != null) {
      return 'Phone User';
    }

    return 'User';
  }

  // Check if user email is verified (Google only)
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;
}