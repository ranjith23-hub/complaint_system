import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:complaint_system/screens/complaint_detail_screen.dart';
import 'package:complaint_system/models/complaint_model.dart';
//import 'package:firebase_storage/firebase_storage.dart'; // Add this for images


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

  // --- Logic: Pick Image ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  // --- Logic: Get Location ---
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

  // --- Logic: Submit to Firebase ---
  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String? imageUrl;

      // 1. Upload Image to Firebase Storage if exists
     /* if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('complaint_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }*/

      // 2. Generate your Custom ID (as we discussed)
      // Example: COM-1734963000-USERUID123
      String customId = "COM-${DateTime.now().millisecondsSinceEpoch}-${user?.uid.substring(0, 5)}";

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('complaints').doc(customId).set({
        'complaintId': customId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'department':"null",
        'userId': user?.uid,
        'imageUrl': imageUrl, // Store the URL link
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 20),
              // Image Preview
              _image != null
                  ? Image.file(_image!, height: 150)
                  : const Text("No Image Selected"),
              TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera),
                  label: const Text("Add Photo")
              ),

              const Divider(),
              // Location Preview
              _isLocating
                  ? const CircularProgressIndicator()
                  : Text(_currentPosition == null
                  ? "Location not attached"
                  : "Lat: ${_currentPosition!.latitude.toStringAsFixed(3)},Lon: ${_currentPosition!.longitude.toStringAsFixed(3)}"),
              TextButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.location_on),
                  label: const Text("Get Location")
              ),

              const SizedBox(height: 30),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: _submitComplaint,
                  child: const Text("SUBMIT")
              ),
            ],
          ),
        ),
      ),
    );
  }
}