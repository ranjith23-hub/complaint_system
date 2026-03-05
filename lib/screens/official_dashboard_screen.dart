import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/JobDetailsScreen.dart';
import 'package:complaint_system/screens/ProfileScreen.dart';
import 'package:complaint_system/screens/leaderboard_screen.dart';
import 'package:complaint_system/screens/analytics_dashboard_screen.dart';
import '../services/app_localizations.dart';

class OfficialDashboardScreen extends StatefulWidget {
  const OfficialDashboardScreen({super.key});

  @override
  State<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState extends State<OfficialDashboardScreen> {
  static const primaryPurple = Color(0xFF5B2D91);
  static const bgColor = Color(0xFFF6F7FB);

  // ================= PRIORITY COLOR =================
  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      case 'classified':
        return Colors.deepOrange;
      case 'resolved':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Session expired. Please login again.")),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(""), // keep empty (header replaces title)
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          _officerHeader(user),
          Expanded(child: _complaintList(user.email!)),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _officerHeader(User user) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(user.uid).get(),
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          photoUrl = snapshot.data!['url'];
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: primaryPurple,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                backgroundImage:
                photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: primaryPurple)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)?.translate('welcome') ?? "Welcome",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 2),
                    Text(
                      user.email ?? "",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Manage assigned civic complaints",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= LIST =================
  Widget _complaintList(String email) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('assignedTo', isEqualTo: email)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)?.translate('no_complaints') ?? "No complaints assigned"));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final complaint = Complaint.fromWorkerFirestore(
              docs[index].data() as Map<String, dynamic>,
              docs[index].id,
            );

            final badgeColor =
            _priorityColor(complaint.priority ?? complaint.status);

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(task: complaint),
                  ),
                );
              },

              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEF3),
                  borderRadius: BorderRadius.circular(18),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, yyyy').format(complaint.date),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "ID: ${complaint.complaintId}",
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: complaint.complaintId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Complaint ID copied")),
                            );
                          },
                        )
                      ],
                    ),

                    Text(
                      complaint.description,
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor),
                        color: badgeColor.withValues(alpha: 0.08),
                      ),
                      child: Text(
                        complaint.priority ?? complaint.status,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
