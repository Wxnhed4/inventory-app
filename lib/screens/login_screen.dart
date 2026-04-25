// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      print('Attempting login with email: ${_emailController.text.trim()}');

      // Add timeout to prevent indefinite waiting
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Login request timed out after 30 seconds. Please check your internet connection.',
              );
            },
          );

      print('Login successful');
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      setState(() {
        _error = 'Timeout: ${e.message}';
      });
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
      String errorMsg = e.message ?? 'Unknown error';

      // Provide more helpful error messages
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found with this email address';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format';
      } else if (e.code == 'too-many-requests') {
        errorMsg = 'Too many login attempts. Please try again later';
      } else if (e.code == 'operation-not-allowed') {
        errorMsg = 'Email/password login is disabled';
      }

      setState(() {
        _error = errorMsg;
      });
    } catch (e) {
      print('General error: $e');
      setState(() {
        _error = "Login failed: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.inventory, size: 100, color: Colors.green),
            const SizedBox(height: 10),
            const Text(
              "Inventory System",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 50),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "you@example.com",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                hintText: "••••••••",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 10),

            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Log In", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Use an account you created in Firebase Console"),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
