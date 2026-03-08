import 'package:flutter/material.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:intl/intl.dart';
import 'feedback_page.dart';
import 'package:complaint_system/services/app_localizations.dart';

class ComplaintDetailsPage extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailsPage({super.key, required this.complaint});

  static const primaryPurple = Color(0xFF5B2D91);
  static const bgColor = Color(0xFFF6F7FB);

  @override
  Widget build(BuildContext context) {

    if ((complaint.status.toLowerCase() == "resolved" ||
        complaint.status.toLowerCase() == "closed" ||
        complaint.status.toLowerCase() == "task_completed") &&
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
        title: Text(
          AppLocalizations.of(context)?.translate('complaint_details') ??
              "Complaint Details",
        ),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _topBanner(context),
            _trackingTimeline(context),
            _mainCard(context),

            _infoSection(
              AppLocalizations.of(context)?.translate('description') ??
                  "Description",
              complaint.description,
              Icons.notes,
            ),

            _infoSection(
              AppLocalizations.of(context)?.translate('location') ??
                  "Location",
              "Lat: ${complaint.latitude?.toStringAsFixed(2) ?? '0.0'}, "
                  "Lon: ${complaint.longitude?.toStringAsFixed(2) ?? '0.0'}",
              Icons.location_on,
            ),

            if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty)
              _imageSection(),

            if (complaint.rating != null) _feedbackSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _topBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            AppLocalizations.of(context)?.translate('title') ??
                "Complaint Title",
            style: const TextStyle(color: Colors.white70),
          ),

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

  // ================= TRACKING =================

  Widget _trackingTimeline(BuildContext context) {

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            AppLocalizations.of(context)?.translate('track_complaint') ??
                "Complaint Progress",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    String normalized = status.toLowerCase();

    if (normalized.contains("submitted")) return 0;
    if (normalized.contains("assigned")) return 1;
    if (normalized.contains("progress")) return 2;

    if (normalized.contains("resolved") ||
        normalized.contains("closed") ||
        normalized.contains("completed")) return 3;

    return 0;
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
      children: [
        Column(
          children: [

            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent ? color : Colors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
            ),

            if (!isLast)
              Container(width: 2, height: 45, color: Colors.grey.shade300)
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: TextStyle(
                fontWeight:
                isCurrent ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ],
    );
  }

  // ================= MAIN CARD =================

  Widget _mainCard(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [

              _detailRow(
                Icons.category,
                AppLocalizations.of(context)?.translate('category') ??
                    "Category",
                complaint.category,
              ),

              const SizedBox(height: 12),

              _detailRow(
                Icons.calendar_month,
                "Submitted On",
                DateFormat('MMM d, yyyy').format(complaint.date),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= INFO SECTION =================

  Widget _infoSection(String title, String content, IconData icon) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Icon(icon, color: primaryPurple),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
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

  // ================= DETAIL ROW =================

  Widget _detailRow(IconData icon, String label, String value) {

    return Row(
      children: [

        Icon(icon),

        const SizedBox(width: 10),

        Text(label),

        const Spacer(),

        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ================= IMAGE =================

  Widget _imageSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Image.network(complaint.imageUrl!),
    );
  }

  // ================= FEEDBACK =================

  Widget _feedbackSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text("Rating: ${complaint.rating} ⭐"),
    );
  }

  // ================= STATUS CHIP =================

  Widget _statusChip(String status) {

    String formatted = formatStatus(status);

    String normalized = status.toLowerCase();

    Color chipColor;

    if (normalized.contains("submitted")) {
      chipColor = Colors.blue;
    }
    else if (normalized.contains("assigned")) {
      chipColor = Colors.orange;
    }
    else if (normalized.contains("progress")) {
      chipColor = Colors.purple;
    }
    else if (normalized.contains("resolved") ||
        normalized.contains("completed") ||
        normalized.contains("closed")) {
      chipColor = Colors.green;
    }
    else {
      chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        formatted,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  // ================= PRIORITY CHIP =================

  Widget _priorityChip(String priority) {

    Color chipColor;

    switch (priority.toLowerCase()) {

      case "high":
        chipColor = Colors.red;
        break;

      case "medium":
        chipColor = Colors.orange;
        break;

      case "low":
        chipColor = Colors.green;
        break;

      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        priority.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  // ================= STATUS FORMAT =================

  String formatStatus(String status) {

    return status
        .replaceAll("_", " ")
        .split(" ")
        .map((word) =>
    word[0].toUpperCase() + word.substring(1))
        .join(" ");
  }
}