import 'package:flutter/material.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint #${complaint.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            complaint.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, Icons.info_outline, 'Status', complaint.status.name, color: complaint.statusColor),
          _buildDetailRow(context, complaint.departmentIcon, 'Department', complaint.department),
          _buildDetailRow(context, Icons.priority_high, 'Priority', complaint.priority),
          _buildDetailRow(context, Icons.calendar_today, 'Submitted On', DateFormat.yMMMd().format(complaint.submittedDate)),
          const Divider(height: 32),
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Divider(height: 32),
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // In a real app, you might show a map here.
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.grey),
              const SizedBox(width: 8),
              Text('Lat: ${complaint.latitude}, Lon: ${complaint.longitude}'),
            ],
          )
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
