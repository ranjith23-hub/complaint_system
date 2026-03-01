import 'package:flutter/material.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:intl/intl.dart';
import 'feedback_page.dart';

class ComplaintDetailsPage extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailsPage({super.key, required this.complaint});

  static const primaryPurple = Color(0xFF5B2D91);
  static const bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {

    // ✅ AUTO ROUTE TO FEEDBACK PAGE
    if ((complaint.status.toLowerCase() == "resolved" ||
        complaint.status.toLowerCase() == "closed") &&
        complaint.rating == null) {

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FeedbackPage(complaint: complaint),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Complaint Details"),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _topBanner(),
            _trackingTimeline(),
            _mainCard(),
            _infoSection("Description", complaint.description, Icons.notes),
            _infoSection(
              "Location",
              "Lat: ${complaint.latitude?.toStringAsFixed(2) ?? '0.0'}, "
                  "Lon: ${complaint.longitude?.toStringAsFixed(2) ?? '0.0'}",
              Icons.location_on,
            ),

            if (complaint.imageUrl != null &&
                complaint.imageUrl!.isNotEmpty)
              _imageSection(),

            // ✅ SHOW FEEDBACK IF ALREADY GIVEN
            if (complaint.rating != null)
              _feedbackSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _topBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius:
        BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Complaint Title",
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            complaint.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip(complaint.status),
              const SizedBox(width: 8),
              _priorityChip(complaint.priority),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TRACKING TIMELINE =================
  Widget _trackingTimeline() {
    List<String> stages = [
      "Submitted",
      "Assigned",
      "In Progress",
      "Resolved"
    ];

    int currentStep = _currentStepIndex(complaint.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Complaint Progress",
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Column(
            children: List.generate(stages.length, (index) {
              return _timelineTile(
                title: stages[index],
                isCompleted: index < currentStep,
                isCurrent: index == currentStep,
                isLast: index == stages.length - 1,
              );
            }),
          )
        ],
      ),
    );
  }

  int _currentStepIndex(String status) {
    switch (status.toLowerCase()) {
      case "submitted":
        return 0;
      case "assigned":
        return 1;
      case "in progress":
        return 2;
      case "resolved":
      case "closed":
        return 3;
      default:
        return 0;
    }
  }

  Widget _timelineTile({
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color color = isCompleted
        ? Colors.green
        : isCurrent
        ? primaryPurple
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? color
                    : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check,
                  size: 14, color: Colors.white)
                  : isCurrent
                  ? const Icon(Icons.radio_button_checked,
                  size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 45,
                color: isCompleted
                    ? Colors.green
                    : Colors.grey.shade300,
              )
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCompleted || isCurrent
                    ? Colors.black87
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= MAIN CARD =================
  Widget _mainCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _detailRow(
                  Icons.category, "Category", complaint.category),
              const SizedBox(height: 12),
              _detailRow(
                Icons.calendar_month,
                "Submitted On",
                DateFormat('MMM d, yyyy')
                    .format(complaint.date),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FEEDBACK SECTION =================
  Widget _feedbackSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Feedback",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                  "Rating: ${complaint.rating?.toStringAsFixed(1)} ⭐"),
              const SizedBox(height: 6),
              Text(complaint.feedback ?? ""),
            ],
          ),
        ),
      ),
    );
  }

  // ================= IMAGE =================
  Widget _imageSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            complaint.imageUrl!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _infoSection(
      String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: primaryPurple),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              Text(content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'in progress':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }

  Widget _priorityChip(String priority) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(priority,
          style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12)),
    );
  }
}