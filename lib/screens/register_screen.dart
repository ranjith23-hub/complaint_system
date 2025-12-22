import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:complaint_system/screens/citizen_dashboard_screen.dart';
import 'package:complaint_system/screens/official_dashboard_screen.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  String? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController =TextEditingController();
  bool _loading = false;

  // Define colors from your logo for consistent branding
  static const Color civicBlue = Color(0xFF0D47A1); // Example blue
  static const Color civicGreen = Color(0xFF4CAF50); // Example green


  Future<void> registerUser({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    required VoidCallback startLoading,
    required VoidCallback stopLoading,
  }) async {
    startLoading();

    try {
      // Create user in Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Store user profile in Firestore (NO PASSWORD)
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'url': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String msg = "Registration failed";

      if (e.code == 'email-already-in-use') {
        msg = "Email already exists";
      } else if (e.code == 'weak-password') {
        msg = "Weak password";
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      stopLoading();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

              // --- Name Field ---
              TextField(
                controller: _nameController, // <-- BUG FIX: Added controller
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),

              // --- Email Field ---
              TextField(
                controller: _emailController, // <-- BUG FIX: Added controller
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),


              //---------Password--------

              TextField(
                controller: _passwordController, // <-- BUG FIX: Added controller
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              // ---Phone NO-------
          TextField(
                controller: _phoneController, // <-- BUG FIX: Added controller
                decoration: InputDecoration(
                  labelText: 'Phone No',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // --- Upload Photo ---
              GestureDetector(
                onTap: (){},
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (_pickedImage != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_pickedImage!.path),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(
                              _pickedImage!.name.length > 20
                                  ? '${_pickedImage!.name.substring(0, 20)}...'
                                  : _pickedImage!.name,
                              overflow: TextOverflow.ellipsis,
                            )),
                        const Icon(Icons.photo_library_outlined, color: civicGreen),
                      ] else ...[
                        const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Expanded(
                            child: Text('Upload Your Photo (Optional)')),
                        const Icon(Icons.upload_file_outlined, color: Colors.grey),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Role dropdown ---
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Select your role',
                  border: inputBorder,
                  focusedBorder: focusedInputBorder,
                  prefixIcon: const Icon(Icons.group_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Citizen', child: Text('Citizen')),
                  DropdownMenuItem(value: 'Official', child: Text('Official')),
                ],
                onChanged: (v) => setState(() => _selectedRole = v),
                hint: const Text('Select role'),
              ),
              const SizedBox(height: 30),

              // --- Register Button ---
              // --- Register Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:_loading
                    ? null
                    : () async {
                    setState(() => _loading = true);

                    await registerUser(
                      context: context,
                      name: _nameController.text.trim(),
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                      phone: _phoneController.text.trim(),
                      role: _selectedRole == "Citizen" ? "CITIZEN" : "OFFICIAL", startLoading: () {  }, stopLoading: () {  },
                    );

                    if (mounted) setState(() => _loading = false);

                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Register',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Go to Login Button ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                    'Already have an account? Login',
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