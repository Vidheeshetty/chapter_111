import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../services/network_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_button.dart';
import '../app.dart'; // Import for AppNavigator

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showNetworkError = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.isAuthenticated) {
        AppNavigator.navigateToHome();
      }
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Check network connectivity
    if (!networkService.isConnected) {
      setState(() => _showNetworkError = true);
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _showNetworkError = false;
    });

    try {
      // Clear any previous errors
      authService.resetError();

      print('🚀 Starting Google Sign-In from UI');

      // Attempt Google Sign-In - simplified, no confirmation dialog
      final success = await authService.signInWithGoogle();

      if (mounted) {
        setState(() => _isGoogleLoading = false);

        if (success) {
          print('✅ Google Sign-In successful, navigating to success');

          // Show brief success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Successfully signed in with Google!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate directly to success screen
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppNavigator.navigateToAuthSuccess(animated: true);
            }
          });
        } else {
          print('❌ Google Sign-In failed');

          if (authService.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(authService.errorMessage!)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Google Sign-In exception: $e');
      if (mounted) {
        setState(() => _isGoogleLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Sign-in failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePhoneSignIn() async {
    final networkService = Provider.of<NetworkService>(context, listen: false);

    if (!networkService.isConnected) {
      setState(() => _showNetworkError = true);
      return;
    }

    setState(() {
      _isPhoneLoading = true;
      _showNetworkError = false;
    });

    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isPhoneLoading = false);
      AppNavigator.navigateToPhoneVerification();
    }
  }

  void _retryConnection() async {
    final networkService = Provider.of<NetworkService>(context, listen: false);
    final isConnected = await networkService.checkConnection();
    setState(() => _showNetworkError = !isConnected);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkService, AuthService>(
      builder: (context, networkService, authService, child) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 80),

                          // App Logo
                          const AppLogo(),
                          const SizedBox(height: 32),

                          // Welcome Text
                          Text(
                            AppConstants.welcomeMessage,
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.signInOrSignUp,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Google Sign-In Button
                          _buildGoogleSignInButton(),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  AppConstants.orContinueWith,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Phone Sign-In Button
                          CustomButton(
                            text: AppConstants.continueWithPhone,
                            onPressed: _handlePhoneSignIn,
                            isLoading: _isPhoneLoading,
                          ),

                          const SizedBox(height: 24),

                          // Network Error (only)
                          if (_showNetworkError)
                            _buildErrorCard(
                              icon: Icons.wifi_off,
                              title: 'No Internet Connection',
                              message: AppConstants.networkError,
                              actionText: 'Retry',
                              onAction: _retryConnection,
                              color: Colors.orange,
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // Footer with test info
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGoogleLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  // Google Icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard({
    required IconData icon,
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(actionText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstants.alreadyMember,
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () {},
                child: Text(AppConstants.logIn),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstants.dontHaveAccount,
                style: TextStyle(color: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () {},
                child: Text(AppConstants.signUp),
              ),
            ],
          ),

          // Test credentials info
          if (MediaQuery.of(context).size.height > 600) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Test Credentials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phone: 7718059613 | Code: 123456',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}