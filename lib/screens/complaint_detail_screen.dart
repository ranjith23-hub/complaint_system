import 'package:flutter/material.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:intl/intl.dart';

class ComplaintDetailsPage extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailsPage({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // CivicConnect Logo/Header area
            const Center(
              child: Column(
                children: [
                  Icon(Icons.business, size: 50, color: Colors.blueGrey),
                  Text(
                    "CivicConnect",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complaint.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _statusChip("Submitted", Colors.blue),
                        const SizedBox(width: 8),
                        _statusChip("MEDIUM", Colors.orange), // Assuming static for now
                      ],
                    ),
                    const Divider(height: 30),
                    _detailRow(Icons.home, "Category", "Water Supply Board"), // Map to your model category
                    const SizedBox(height: 10),
                    _detailRow(Icons.calendar_month, "Submitted On", DateFormat('MMM d, yyyy').format(complaint.date)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description Section
            _sectionBox("Description", complaint.description),

            const SizedBox(height: 16),

            // Location Section
            _sectionBox(
              "Location",
              "Lat: ${complaint.latitude?.toStringAsFixed(1) ?? '0.0'}, Lon: ${complaint.longitude?.toStringAsFixed(1) ?? '0.0'}",
              icon: Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Category/Date rows
  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Helper widget for the boxed sections
  Widget _sectionBox(String title, String content, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (icon != null) Icon(icon, color: Colors.red, size: 18),
              if (icon != null) const SizedBox(width: 8),
              Text(content),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}