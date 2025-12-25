import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:complaint_system/screens/complaint_detail_screen.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:complaint_system/models/Application.dart';
//import 'package:firebase_storage/firebase_storage.dart'; // Add this for images


class AddComplaintScreen extends StatefulWidget {
  const AddComplaintScreen({super.key});

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  File? _image;
  Position? _currentPosition;
  bool _isSubmitting = false;
  bool _isLocating = false;


  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final cloudinary = CloudinaryPublic(
        cloud_name,
        complaint_img,
        cache: false,
      );

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );

      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Upload Error: $e");
      return null;
    }
  }

  // --- 2. KEYWORDS GENERATOR (For Substring Search) ---
  List<String> _generateSearchKeywords(String id) {
    List<String> keywords = [];
    String upperId = id.toUpperCase();
    for (int i = 0; i < upperId.length; i++) {
      for (int j = i + 1; j <= upperId.length; j++) {
        keywords.add(upperId.substring(i, j));
      }
    }
    return keywords.toSet().toList(); // Remove duplicates
  }

  // --- 3. PICK IMAGE ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // --- 4. GET LOCATION ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPosition = position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location Error: $e")));
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // --- 5. SUBMIT COMPLAINT ---
  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String? finalImageUrl;

      // CALL Cloudinary if image exists
      if (_image != null) {
        finalImageUrl = await _uploadToCloudinary(_image!);
      }

      // Generate Custom ID
      String customId = "COM-${DateTime.now().millisecondsSinceEpoch}-${user?.uid.substring(0, 5)}".toUpperCase();

      // Generate Keywords for Search
      //List<String> keywords = _generateSearchKeywords(customId);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('complaints').doc(customId).set({
        'complaintId': customId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'category':  "Water Supply Board",
        'userId': user?.uid,
        'imageUrl': finalImageUrl,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'status': 'Pending',
        'priority': 'MEDIUM',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Filed Successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Complaint')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Issue Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Please describe the issue' : null,
              ),

              const SizedBox(height: 20),

              // Image Section
              _image != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover),
              )
                  : Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
              TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Select Photo")
              ),

              const Divider(height: 30),

              // Location Section
              _isLocating
                  ? const CircularProgressIndicator()
                  : Column(
                children: [
                  Icon(Icons.location_on, color: _currentPosition == null ? Colors.grey : Colors.red),
                  Text(_currentPosition == null
                      ? "Location not attached"
                      : "Verified: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}"),
                ],
              ),
              TextButton(
                  onPressed: _getCurrentLocation,
                  child: const Text("Capture Current Location")
              ),

              const SizedBox(height: 30),

              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: _submitComplaint,
                  child: const Text("SUBMIT COMPLAINT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ComplaintSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ""),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // This triggers when the user hits "Enter"
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This triggers while the user is typing
    if (query.isEmpty) return const Center(child: Text("Search by ID (e.g., COM-123...)"));
    return _buildSearchResults(query);
  }

  // --- Helper to query Firestore ---
  Widget _buildSearchResults(String searchText) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('complaintId', isGreaterThanOrEqualTo: searchText.trim().toUpperCase())
          .where('complaintId', isLessThanOrEqualTo: searchText.trim().toUpperCase() + '\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No complaints found."));
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            // 1. Map Firestore data to your NEW Complaint model
            final data = docs[index].data() as Map<String, dynamic>;
            final complaint = Complaint.fromFirestore(data);

            return ListTile(
              leading: const Icon(Icons.description, color: Color(0xFF0D47A1)),
              title: Text(complaint.complaintId),
              subtitle: Text(complaint.title),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                // 2. Close the search bar first
                close(context, null);

                // 3. Navigate to the Details Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintDetailsPage(complaint: complaint),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
