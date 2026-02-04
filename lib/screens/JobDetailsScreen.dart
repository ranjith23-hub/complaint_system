// job_details.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/services/gamification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
class JobDetailScreen extends StatefulWidget {
  final Complaint task;
  const JobDetailScreen({super.key, required this.task});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}



class _JobDetailScreenState extends State<JobDetailScreen> {
  final TextEditingController _resolutionController = TextEditingController();
  Future<void> _openGoogleMaps() async {
    final Uri googleMapsUri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1"
          "&destination=${widget.task.latitude},${widget.task.longitude}"
          "&travelmode=driving",
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }
  // Helper to update Firestore
  Future<void> _updateFirestoreTask(String newStatus, {String? resolution}) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.task.complaintId) // Ensure your model has the doc ID
          .update({
        'status': newStatus,
        if (resolution != null) 'resolutionDetails': resolution,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() => widget.task.status = newStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // Or ImageSource.camera
        imageQuality: 70, // Compresses image for faster Firestore/Cloudinary upload
      );

      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }


  void _startWork() async {
    await _updateFirestoreTask("In Progress");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Status Updated: Citizen notified you are on-site!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Execution Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(),
            const SizedBox(height: 24),
            const Text("Issue Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(widget.task.description, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 24),
            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text("Lat: ${widget.task.latitude}, Lon: ${widget.task.longitude}"),
              trailing: TextButton(onPressed: _openGoogleMaps, child: const Text("NAVIGATE")),
            ),
            const SizedBox(height: 40),
            // START WORK BUTTON\
            if (widget.task.imageUrl != null && widget.task.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  widget.task.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: widget.task.status == "Assigned" ? _startWork : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text("START WORK / NOTIFY CITIZEN"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            // RESOLVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: widget.task.status == "In Progress" ? _showResolutionDialog : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("MARK AS RESOLVED"),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showResolutionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Submit Work Proof", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _resolutionController,
              decoration: const InputDecoration(labelText: "Action Taken", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage, // This calls the function below
              child: Container(
                height: 150, // Increased height for better preview
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _pickedImage!,
                    fit: BoxFit.cover,
                  ),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                    const SizedBox(height: 8),
                    Text("Select Photo", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _updateFirestoreTask("Resolved", resolution: _resolutionController.text);
                Navigator.pop(context); // Close sheet
                Navigator.pop(context); // Back to queue
                // 1. Existing logic to update the complaint status
                await _updateFirestoreTask("Resolved", resolution: _resolutionController.text);

                // 2. ADD THIS: Award points to the citizen who filed the complaint
                await GamificationService().awardPointsForResolution(widget.task.userId);

                Navigator.pop(context); // Close sheet
                Navigator.pop(context); // Back to queue

                // Optional: Update the snackbar to mention points
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Job Completed! Points awarded to citizen."))
                );


              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              child: const Text("FINALIZE & CLOSE"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    bool isAssigned = widget.task.status == "Assigned";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAssigned ? Colors.orange[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAssigned ? Colors.orange : Colors.green),
      ),
      child: Text(widget.task.status, style: TextStyle(color: isAssigned ? Colors.orange[900] : Colors.green[900], fontWeight: FontWeight.bold)),
    );
  }
}