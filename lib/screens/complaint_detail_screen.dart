import 'package:flutter/material.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  // Helper to get color based on status string
  Color _getStatusColor(String status) {
    if (status == 'Resolved') return Colors.green;
    if (status == 'Pending') return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- TITLE ---
          Text(
            complaint.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // --- STATUS ---
          _buildDetailRow(
              context,
              Icons.info_outline,
              'Status',
              complaint.status,
              color: _getStatusColor(complaint.status)
          ),

          // --- DATE (Fixed: changed submittedDate to date) ---
          _buildDetailRow(
              context,
              Icons.calendar_today,
              'Submitted On',
              DateFormat.yMMMd().format(complaint.date)
          ),

          // --- ID ---
          _buildDetailRow(
            context,
            Icons.tag,
            'Complaint ID',
            complaint.id,
          ),

          const Divider(height: 32),

          // --- DESCRIPTION ---
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),

          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text('$label:', style: Theme.of(context).textTheme.titleSmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}