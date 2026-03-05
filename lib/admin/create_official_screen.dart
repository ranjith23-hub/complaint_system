import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:geolocator/geolocator.dart'; // New
import 'package:geocoding/geocoding.dart';
import 'package:complaint_system/models/Application.dart' ;

import '../models/Application.dart' as Application;



class CreateOfficialScreen extends StatefulWidget {
  const CreateOfficialScreen({super.key});

  @override
  State<CreateOfficialScreen> createState() => _CreateOfficialScreenState();
}

class _CreateOfficialScreenState extends State<CreateOfficialScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State Variables
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedRole;
  File? _imageFile;
  bool _loading = false;
  bool _gettingLocation = false; // For location button loading
  bool _obscurePassword = true;

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const List<String> _roles = ['AE', 'AEE', 'EE'];

  @override
  void dispose() {
    for (var controller in [_nameController, _emailController, _phoneController, _dobController, _aadhaarController, _wardController, _addressController, _passwordController, _confirmPasswordController]) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- LOCATION LOGIC ---
  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      // 1. Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      // 2. Get Coordinates
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. Reverse Geocode (Coordinates -> Address)
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        String fullAddress = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
        setState(() {
          _addressController.text = fullAddress;
        });
      }
    } catch (e) {
      _showSnackBar("Location Error: ${e.toString()}");
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  // --- IMAGE & CLOUDINARY LOGIC ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      String cloudName =Application.cloud_name;
      String uploadPreset= Application.complaint_img;
      final cloudinary = CloudinaryPublic(cloudName,
          uploadPreset,
           cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      return null;
    }
  }

  // --- CREATE ACCOUNT LOGIC ---
  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnackBar('Please upload a profile photo');
      return;
    }

    setState(() => _loading = true);
    final String email = _emailController.text.trim().toLowerCase();

    try {
      String? imageUrl = await _uploadToCloudinary(_imageFile!);
      if (imageUrl == null) throw "Image upload failed";

      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: "AdminAction_${DateTime.now().millisecondsSinceEpoch}",
        options: Firebase.app().options,
      );

      UserCredential credential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: _passwordController.text);

      if (credential.user?.uid != null) {
        await FirebaseFirestore.instance.collection('Users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': _nameController.text.trim(),
          'email': email,
          'phone': _phoneController.text.trim(),
          'dob': _dobController.text.trim(),
          'gender': _selectedGender,
          'bloodGroup': _selectedBloodGroup,
          'aadhar': _aadhaarController.text.trim(),
          'ward': _wardController.text.trim(),
          'address': _addressController.text.trim(),
          'officialRole': _selectedRole,
          'url': imageUrl,
          'role': 'OFFICIAL',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await secondaryApp.delete();
        if (!mounted) return;
        _showSnackBar('Official Registered Successfully!', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Official'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 25),
              _buildField(_nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              _buildField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(_phoneController, 'Phone', Icons.phone, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateField()),
                ],
              ),
              const SizedBox(height: 16),

              // --- ADDRESS FIELD WITH LOCATION BUTTON ---
              _buildField(
                _addressController,
                'Residential Address',
                Icons.home,
                maxLines: 2,
                suffix: _gettingLocation
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.blueAccent),
                  onPressed: _getCurrentLocation,
                  tooltip: "Get Current Location",
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(_wardController, 'Ward No', Icons.location_city, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('Role', _roles, _selectedRole, (v) => setState(() => _selectedRole = v))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Gender', _genders, _selectedGender, (v) => setState(() => _selectedGender = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDropdown('Blood', _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v))),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(_aadhaarController, 'Aadhaar Number', Icons.fingerprint, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildField(_passwordController, 'Password', Icons.lock, obscureText: _obscurePassword,
                  suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
              const SizedBox(height: 16),
              _buildField(_confirmPasswordController, 'Confirm Password', Icons.lock_clock, obscureText: true,
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blueAccent.withOpacity(0.1),
        backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
        child: _imageFile == null ? const Icon(Icons.add_a_photo, size: 30, color: Colors.blueAccent) : null,
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator, Widget? suffix, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
      decoration: _inputDecoration(label, icon).copyWith(suffixIcon: suffix),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: DateTime(1995), firstDate: DateTime(1950), lastDate: DateTime.now());
        if (picked != null) {
          _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
      decoration: _inputDecoration('DOB', Icons.calendar_today),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
      decoration: _inputDecoration(label, Icons.arrow_drop_down_circle_outlined),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _createAccount,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('REGISTER OFFICIAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green));
  }
}