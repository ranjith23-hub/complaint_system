import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
//import 'package:complaint_system/models/Application.dart';
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
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:complaint_system/models/Application.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  String? _selectedRole;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController =TextEditingController();
  bool _loading = false;

  // Define colors from your logo for consistent branding
  static const Color civicBlue = Color(0xFF0D47A1); // Example blue
  static const Color civicGreen = Color(0xFF4CAF50); // Example green


  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks[0];
      return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
    } catch (e) {
      return "Address not found";
    }
  }

  double? lat, lng;
  String? _currentAddress;
  final TextEditingController _addressController = TextEditingController();
  bool _loadingLocation = false;
  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled on the phone
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled. Please turn on GPS.')),
      );
      return;
    }

    // 2. Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission if denied
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    // 3. Handle permanent denial
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions are permanently denied. Please enable in settings.')),
      );
      return;
    }
    setState(() => _loadingLocation = true);
    setState(() => _loadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      Placemark p = placemarks[0];
      String formattedAddress = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";

      setState(() {
        _addressController.text = formattedAddress;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission or service denied.")),
      );
    } finally {
      setState(() => _loadingLocation = false);
    }
  }


  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      String cloudName =Application.cloud_name;
      String uploadPreset= Application.complaint_img;


      final cloudinary = CloudinaryPublic(
        cloudName,
        uploadPreset,
        cache: false,
      );

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );

      print("UPLOAD SUCCESS: ${response.secureUrl}");
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }

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
      String? finalImageUrl;

      if (_pickedImage != null) {
        finalImageUrl = await _uploadToCloudinary(_pickedImage!);
      }
      // Store user profile in Firestore (NO PASSWORD)
      double? finalLat = lat;
      double? finalLng = lng;

      try {
        // Silent background fetch to get the most up-to-date "Hard Fact"
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5), // Don't let it hang forever
        );
        finalLat = position.latitude;
        finalLng = position.longitude;
      } catch (e) {
        debugPrint("Background location fetch failed, using previous or null");
      }

      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'url': finalImageUrl,
        'address': _addressController.text.trim(),
        'latitude':  finalLat ?? 0.0,
        'longitude': finalLng?? 0.0,
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


  Future<void> _pickImage() async {
    final picFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picFile != null) {
      setState(() => _pickedImage= File(picFile.path));
    }
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
                onTap: _pickImage,
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
                            _pickedImage!.path.split('/').last, // Get filename from path
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Home Address",
                  hintText: "Enter your address or tap the icon",
                  prefixIcon: const Icon(Icons.home_outlined),
                  border:inputBorder,

                  // --- ICON BUTTON TO AUTO-FILL ---
                  suffixIcon: _loadingLocation
                      ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : IconButton(
                    icon: const Icon(Icons.my_location, color: Color(0xFF0D47A1)),
                    onPressed: _getUserLocation,
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
                    backgroundColor: const Color(0xFF5B2D91),
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