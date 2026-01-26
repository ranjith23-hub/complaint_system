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

  @override
  void initState() {
    super.initState();
    printAllAssignedTo();
  }

  Future<void> printAllAssignedTo() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('complaints').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        print("🆔 Doc ID: ${doc.id}");
        print("👤 Assigned To: ${data['assignedTo']}");
        print("-----------------------------------------");
      }
    } catch (e) {
      print("❌ Error fetching assignedTo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Session expired. Please login again."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Complaints'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        actions: [
          // 👤 Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          // 🚪 Logout Button
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

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No active complaints assigned.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final complaint = Complaint.fromWorkerFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    complaint.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Category: ${complaint.category} • Status: ${complaint.status}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobDetailScreen(task: complaint),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
