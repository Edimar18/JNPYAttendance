import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String confirmPassword = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join our community to start monitoring',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                // Email Field
                const Text(
                  'Email Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'example@parish.com',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (val) => email = val,
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                const SizedBox(height: 24),
                // Password Field
                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  onChanged: (val) => password = val,
                  validator: (val) => val!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 24),
                // Confirm Password Field
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onChanged: (val) => confirmPassword = val,
                  validator: (val) => val != password ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 40),
                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() => _isLoading = true);
                      try {
                        await _auth.registerWithEmailAndPassword(email, password);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
