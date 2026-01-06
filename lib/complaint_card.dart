import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/complaint_model.dart';
import '../screens/complaint_detail_screen.dart';
import 'package:flutter/services.dart';

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const ComplaintCard({super.key, required this.complaint});
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID Copied: $text'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final Color statusColor = complaint.status == 'Resolved' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComplaintDetailsPage(complaint: complaint))
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(complaint.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  Text(DateFormat('MMM d, yyyy').format(complaint.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              // REPLACE the Expanded block in your build method with this:
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "ID: ${complaint.complaintId}", // Ensure this field name matches your model
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.content_copy_rounded, color: Color(0xFF0D47A1), size: 18),
                    tooltip: "Copy ID",
                    onPressed: () => _copyToClipboard(context, complaint.complaintId),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(complaint.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              _buildBadge(complaint.status, statusColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}