import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/JobDetailsScreen.dart';

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
    printAllAssignedTo();   // 👈 DEBUG: Fetch all assignedTo values
  }

  Future<void> printAllAssignedTo() async {
    try {
      print("📥 Fetching all assignedTo values from Firestore...");

      final snapshot =
      await FirebaseFirestore.instance.collection('complaints').get();

      print("📊 Total complaints: ${snapshot.docs.length}");

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

    print("🔍 Current User UID: ${currentUser?.uid}");
    print("🔍 Current User Email: ${currentUser?.email}");

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Session expired. Please login again."),
        ),
      );
    }

    print("🔥 Listening to complaints assigned to: sakthi@gmail.com");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              print("🚪 Logging out user: ${currentUser.email}");
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
            .where('assignedTo', isEqualTo: 'sakthi@gmail.com')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print("📡 Snapshot Connection State: ${snapshot.connectionState}");
          print("📦 Snapshot hasData: ${snapshot.hasData}");
          print("📄 Snapshot docs count: ${snapshot.data?.docs.length}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("❌ Firestore Error: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("⚠️ No complaints assigned to sakthi@gmail.com");
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

              print("🧾 Raw Firestore Data: ${doc.data()}");
              print("🆔 Document ID: ${doc.id}");

              final complaint = Complaint.fromWorkerFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              print("✅ Complaint Loaded:");
              print("   ID: ${complaint.complaintId}");
              print("   Title: ${complaint.title}");
              print("   Assigned To: ${complaint.assignedTo}");
              print("   Status: ${complaint.status}");

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
                    print("➡️ Opening job detail for: ${complaint.complaintId}");
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
