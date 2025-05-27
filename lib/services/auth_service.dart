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

  // Verification code
  String? _verificationId;
  int? _resendToken;

  // Getters
  AuthState get authState => _authState;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authState == AuthState.authenticated && _currentUser != null;
  bool get isLoading => _authState == AuthState.loading;
  AuthMethod? get lastMethod => _lastMethod;
  String? get phoneNumber => _phoneNumber;
  bool get isPhoneVerified => _isPhoneVerified;
  GoogleSignInAccount? get googleAccount => _googleAccount;
  User? get currentUser => _currentUser;
  String? get verificationId => _verificationId;

  Future<void> initialize() async {
    _authState = AuthState.initial;

    try {
      // Listen to auth state changes
      _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

      // Check current user
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

    if (user != null) {
      _authState = AuthState.authenticated;
      await _saveAuthMethod();
    } else {
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

  Future<void> _clearGoogleSignInCache() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
      print('Cleared Google Sign-In cache');
    } catch (e) {
      print('Error clearing Google cache: $e');
    }
  }

  // Enhanced Google Sign In with proper UI flow
  Future<bool> signInWithGoogle() async {
    print('=== Starting Google Sign-In ===');

    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _clearGoogleSignInCache();
      await Future.delayed(const Duration(milliseconds: 500));

      print('Initiating Google Sign-In flow with account picker...');

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

  // Proper Phone verification with Firebase
  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    print('=== Starting Phone Verification ===');
    print('Phone number: $phoneNumber');

    _authState = AuthState.loading;
    _lastMethod = AuthMethod.phone;
    _errorMessage = null;
    _phoneNumber = phoneNumber;
    notifyListeners();

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            print('✅ Auto verification completed');
            final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

            if (userCredential.user != null) {
              _lastMethod = AuthMethod.phone;
              _isPhoneVerified = true;
              _authState = AuthState.authenticated;
              _currentUser = userCredential.user;
              await _saveAuthMethod();
              notifyListeners();
            }
          } catch (e) {
            print('❌ Auto-verification failed: $e');
            _errorMessage = 'Auto-verification failed.';
            _authState = AuthState.error;
            notifyListeners();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Phone verification failed: ${e.code} - ${e.message}');
          _authState = AuthState.error;
          _errorMessage = _getFirebaseAuthErrorMessage(e);
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ SMS code sent successfully');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _authState = AuthState.unauthenticated;
          _errorMessage = null;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto-retrieval timeout');
          _verificationId = verificationId;
        },
      );

      return true;
    } catch (e) {
      print('❌ Phone verification error: $e');
      _authState = AuthState.error;
      _errorMessage = 'Phone verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Proper SMS code verification with Firebase
  Future<bool> verifySmsCode(String smsCode) async {
    print('=== Verifying SMS Code ===');
    print('Code: $smsCode');

    if (_verificationId == null) {
      print('❌ No verification ID available');
      _authState = AuthState.error;
      _errorMessage = 'Verification session expired. Please request a new code.';
      notifyListeners();
      return false;
    }

    _authState = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create PhoneAuthCredential with verification ID and SMS code
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Sign in with the credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('✅ Phone verification successful');
        print('User ID: ${userCredential.user!.uid}');
        print('Phone: ${userCredential.user!.phoneNumber}');

        _isPhoneVerified = true;
        _lastMethod = AuthMethod.phone;
        _authState = AuthState.authenticated;
        _currentUser = userCredential.user;

        await _saveAuthMethod();
        notifyListeners();
        return true;
      } else {
        throw Exception('Firebase authentication returned null user');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ SMS verification error: ${e.code} - ${e.message}');
      _authState = AuthState.error;
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ SMS verification error: $e');
      _authState = AuthState.error;
      _errorMessage = 'Invalid verification code. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Resend verification code
  Future<bool> resendVerificationCode() async {
    if (_phoneNumber == null) {
      _errorMessage = 'No phone number available for resend.';
      notifyListeners();
      return false;
    }

    print('=== Resending Verification Code ===');
    return await verifyPhoneNumber(_phoneNumber!);
  }

  // Enhanced sign out
  Future<void> signOut() async {
    print('=== Signing Out ===');
    _authState = AuthState.loading;
    notifyListeners();

    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google if needed
      if (_lastMethod == AuthMethod.google || _googleAccount != null) {
        try {
          await _googleSignIn.signOut();
          await _googleSignIn.disconnect();
        } catch (e) {
          print('Google sign out error: $e');
        }
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
      _verificationId = null;
      _resendToken = null;
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
      case 'invalid-phone-number':
        return 'The phone number format is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
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
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'requires-recent-login':
        return 'Please sign in again to continue.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in.';
      notifyListeners();
      return false;
    }

    _authState = AuthState.loading;
    notifyListeners();

    try {
      await _currentUser!.delete();
      await signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      _authState = AuthState.error;
      _errorMessage = _getFirebaseAuthErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = 'Failed to delete account. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Update phone number
  Future<bool> updatePhoneNumber(String newPhoneNumber) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in.';
      notifyListeners();
      return false;
    }

    // This would require re-verification process
    return await verifyPhoneNumber(newPhoneNumber);
  }

  // Get user display name
  String? getUserDisplayName() {
    if (_currentUser == null) return null;

    if (_currentUser!.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      return _currentUser!.displayName;
    }

    if (_currentUser!.email != null && _currentUser!.email!.isNotEmpty) {
      return _currentUser!.email;
    }

    if (_currentUser!.phoneNumber != null && _currentUser!.phoneNumber!.isNotEmpty) {
      return _currentUser!.phoneNumber;
    }

    return 'User';
  }

  // Check if user email is verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // Send email verification
  Future<bool> sendEmailVerification() async {
    if (_currentUser == null) return false;

    try {
      await _currentUser!.sendEmailVerification();
      return true;
    } catch (e) {
      print('Error sending email verification: $e');
      return false;
    }
  }
}