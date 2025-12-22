import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Needed for parsing login response
import 'package:firebase_auth/firebase_auth.dart';
import 'package:complaint_system/screens/citizen_dashboard_screen.dart';
import 'package:complaint_system/screens/official_dashboard_screen.dart';
import 'package:complaint_system/screens/register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;


  static const Color civicBlue = Color(0xFF0D47A1); // Example blue
  static const Color civicGreen = Color(0xFF4CAF50); // Example green

  Future<void> loginUser() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 4. Fetch User Role from Firestore (to know where to redirect)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users') // Must match the collection name in RegisterScreen
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        String role = userDoc.get('role');
        print("role "+role);
        // 5. Navigate based on Role
        if (role == "CITIZEN") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CitizenDashboardScreen()),
          );
        } else if (role == "OFFICIAL") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OfficialDashboardScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Unknown user role.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User record not found in database.")),
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found for this email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else if (e.code == 'invalid-credential') {
        message = "Invalid email or password.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Shared border style for all input fields
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: civicBlue, width: 2),
    );

    return Scaffold(
      backgroundColor: Colors.white, // Set background to white
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO PLACEHOLDER ---
              Icon(
                Icons.business_outlined, // Placeholder Icon
                size: 80,
                color: civicBlue,
              ),
              const SizedBox(height: 16),
              // --- TITLE FROM LOGO ---
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto', // Ensure you have this font or change as needed
                  ),
                  children: [
                    TextSpan(
                      text: 'Civic',
                      style: TextStyle(color: civicBlue),
                    ),
                    TextSpan(
                      text: 'Connect',
                      style: TextStyle(color: civicGreen),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Email Field ---
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- Password Field ---
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // --- Login Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: civicGreen, // Use logo color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Go to Register Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: civicBlue,
                    side: const BorderSide(color: civicBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Need an account? Register',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
