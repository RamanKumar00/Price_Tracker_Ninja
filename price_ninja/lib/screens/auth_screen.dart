import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/color_constants.dart';
import '../widgets/glass_input.dart';
import '../widgets/neon_button.dart';
import '../widgets/premium_logo.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Invalid email format. Please enter a valid email address.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmail(email, password);
      } else {
        await authService.signUpWithEmail(email, password);
      }
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed. Please try again.';
      
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'This email does not exist or wrong password. Please check again.';
        if (!_isLogin) {
           // If they are trying to sign up and get an error (less common to get not-found here)
           errorMessage = e.message ?? errorMessage;
        }
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered! Please switch to Sign In.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password. Try again.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your internet connection.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: NinjaColors.rose),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NinjaColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            if (Navigator.canPop(context))
              Positioned(
                top: 0,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: NinjaColors.glassBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NinjaColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: NinjaColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
              const Center(child: PremiumLogo(size: 80)),
              const SizedBox(height: 24),
              const Text(
                'Price Ninja',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: NinjaColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin ? 'Welcome back! Sign in to continue.' : 'Create an account to save tracks in cloud.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: NinjaColors.textSecondary),
              ),
              const SizedBox(height: 48),

              GlassInput(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'you@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                colorIndex: 0,
              ),
              const SizedBox(height: 16),
              GlassInput(
                controller: _passwordController,
                labelText: 'Password',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
                colorIndex: 1,
              ),
              const SizedBox(height: 32),

              NeonButton(
                text: _isLogin ? 'Sign In' : 'Sign Up',
                icon: _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                isLoading: _isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? "Don't have an account? " : "Already have an account? ",
                    style: TextStyle(color: NinjaColors.textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(
                        color: NinjaColors.violet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}
