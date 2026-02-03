// job_details.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/services/gamification_service.dart';
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
            // START WORK BUTTON
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
            Container(
              height: 100, width: double.infinity,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.camera_alt, color: Colors.grey),
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