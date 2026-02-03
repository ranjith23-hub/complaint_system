import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/JobDetailsScreen.dart';
import 'package:complaint_system/screens/ProfileScreen.dart';

class OfficialDashboardScreen extends StatefulWidget {
  const OfficialDashboardScreen({super.key});

  @override
  State<OfficialDashboardScreen> createState() =>
      _OfficialDashboardScreenState();
}

class _OfficialDashboardScreenState extends State<OfficialDashboardScreen> {
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Session expired. Please login again.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      // 🔹 APP BAR
      appBar: AppBar(
        title: const Text(
          'Assigned Complaints',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF5B2D91),
        foregroundColor: Colors.white,
        actions: [
          // 🔍 SEARCH
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                OfficialComplaintSearchDelegate(currentUser.email!),
              );
            },
          ),

          // ⋮ THREE DOT MENU
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              } else if (value == 'find') {
                showSearch(
                  context: context,
                  delegate:
                  OfficialComplaintSearchDelegate(currentUser.email!),
                );
              } else if (value == 'help') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Help"),
                    content: const Text(
                      "For assistance, please contact the system administrator.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 10),
                    Text("My Profile"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'find',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 10),
                    Text("Find Complaint"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 10),
                    Text("Help"),
                  ],
                ),
              ),
            ],
          ),

          // 🚪 LOGOUT
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

      // 🔹 BODY
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('assignedTo', isEqualTo: currentUser.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No complaints assigned"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final complaint = Complaint.fromWorkerFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(task: complaint),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                complaint.category,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                              const Color(0xFF0D47A1),
                            ),
                            Chip(
                              label: Text(
                                complaint.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor:
                              _statusColor(complaint.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////
// 🔍 SEARCH DELEGATE (same file)
//////////////////////////////////////////////////////////////////////////////

class OfficialComplaintSearchDelegate extends SearchDelegate {
  final String officialEmail;

  OfficialComplaintSearchDelegate(this.officialEmail);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('assignedTo', isEqualTo: officialEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs
            .map((doc) => Complaint.fromWorkerFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        ))
            .where((c) =>
        c.title.toLowerCase().contains(query.toLowerCase()) ||
            c.category.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (results.isEmpty) {
          return const Center(child: Text("No matching complaints"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final c = results[index];
            return ListTile(
              title: Text(c.title),
              subtitle: Text(c.category),
              trailing: Text(c.status),
              onTap: () {
                close(context, null);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailScreen(task: c),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
