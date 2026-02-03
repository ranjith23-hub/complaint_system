import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/add_complaint_screen.dart';
import 'package:complaint_system/complaint_card.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/ProfileScreen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() =>
      _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        backgroundColor: const Color(0xFF5B2D91),
        foregroundColor: Colors.white,
        actions: [
          // 🔍 Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ComplaintSearchDelegate(currentUser!.uid),
              );
            },
          ),

          // ⋮ Three Dot Menu
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
                  delegate: ComplaintSearchDelegate(currentUser!.uid),
                );
              } else if (value == 'help') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Help'),
                    content: const Text(
                      'Contact support for assistance.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('My Profile'),
              ),
              PopupMenuItem(
                value: 'find',
                child: Text('Find Complaint'),
              ),
              PopupMenuItem(
                value: 'help',
                child: Text('Help'),
              ),
            ],
          ),

          // 🚪 Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),

      // 📋 Complaint List
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No complaints found'),
            );
          }

          final complaints = snapshot.data!.docs.map((doc) {
            return Complaint.fromFirestore(
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return ComplaintCard(
                complaint: complaints[index],
              );
            },
          );
        },
      ),

      // ➕ New Complaint
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddComplaintScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////////////////////
// 🔍 SEARCH DELEGATE (INSIDE SAME FILE)
//////////////////////////////////////////////////////////////////////////////

class ComplaintSearchDelegate extends SearchDelegate {
  final String userId;

  ComplaintSearchDelegate(this.userId);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.map((doc) {
          return Complaint.fromFirestore(
            doc.data() as Map<String, dynamic>,
          );
        }).where((complaint) {
          return complaint.title
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              complaint.category
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No matching complaints'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return ComplaintCard(
              complaint: results[index],
            );
          },
        );
      },
    );
  }
}
