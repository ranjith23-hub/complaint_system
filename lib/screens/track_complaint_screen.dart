import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/complaint_detail_screen.dart';

class TrackComplaintScreen extends StatefulWidget {
  const TrackComplaintScreen({super.key});

  @override
  State<TrackComplaintScreen> createState() => _TrackComplaintScreenState();
}

class _TrackComplaintScreenState extends State<TrackComplaintScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isSearching = false;

  Future<void> _searchComplaint() async {
    String searchId = _idController.text.trim();

    if (searchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a Complaint ID")),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Search Firestore by the document ID
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('complaints')
          .doc(searchId)
          .get();

      if (doc.exists) {
        // Map the data to your model
        Complaint complaint = Complaint.fromFirestore(doc.data() as Map<String, dynamic>);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplaintDetailsPage(complaint: complaint),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No complaint found with this ID")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Complaint Status"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Complaint ID",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the unique tracking ID to view the status of any public complaint.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                hintText: "e.g. ABC123XYZ",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSearching
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Track Status",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}