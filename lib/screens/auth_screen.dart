import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthMode { login, signup, resetPassword }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  AuthMode _authMode = AuthMode.login;
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    try {
      if (_authMode == AuthMode.login) {
        await authService.signIn(_emailController.text, _passwordController.text);
      } else if (_authMode == AuthMode.signup) {
        final creds = await authService.signUp(_emailController.text, _passwordController.text);
        final newUser = UserModel(
          uid: creds.user!.uid,
          email: _emailController.text,
          displayName: _nameController.text,
          createdAt: DateTime.now(),
        );
        await firestoreService.createUser(newUser);
      } else if (_authMode == AuthMode.resetPassword) {
        if (_emailController.text.isEmpty) {
          throw FirebaseAuthException(code: 'invalid-email', message: 'Please enter your email.');
        }
        await authService.sendPasswordResetEmail(_emailController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset link sent to your email!')),
          );
          setState(() => _authMode = AuthMode.login);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An authentication error occurred.';
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email.';
            break;
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Incorrect email or password.';
            break;
          case 'email-already-in-use':
            errorMessage = 'This email address is already in use.';
            break;
          case 'weak-password':
            errorMessage = 'The chosen password is too weak.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many attempts. Please try again later.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'This sign-in method is not enabled.';
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection and try again.';
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PlushBond',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Shared companions for couples',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              if (_authMode == AuthMode.resetPassword) ...[
                const Text(
                  'Enter your email to receive a password reset link',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],
              if (_authMode == AuthMode.signup) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'Display Name'),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              if (_authMode != AuthMode.resetPassword) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
                if (_authMode == AuthMode.login)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _authMode = AuthMode.resetPassword),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_authMode == AuthMode.login
                          ? 'Login'
                          : _authMode == AuthMode.signup
                              ? 'Register'
                              : 'Send Reset Link'),
                    ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_authMode == AuthMode.resetPassword) {
                      _authMode = AuthMode.login;
                    } else {
                      _authMode = _authMode == AuthMode.login
                          ? AuthMode.signup
                          : AuthMode.login;
                    }
                  });
                },
                child: Text(_authMode == AuthMode.login
                    ? 'Need an account? Register'
                    : _authMode == AuthMode.signup
                        ? 'Have an account? Login'
                        : 'Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
