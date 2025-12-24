import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart'; // Ensure this exists
import 'package:complaint_system/screens/add_complaint_screen.dart';
import 'package:complaint_system/complaint_card.dart'; // Ensure this exists
import 'package:complaint_system/screens/login_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ComplaintSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // --- CHANGED: FutureBuilder -> StreamBuilder ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('userId', isEqualTo: currentUser?.uid) // Filter by logged-in user
            .orderBy('createdAt', descending: true)       // Sort by newest
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Handle Errors
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Handle Empty Data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have not filed any complaints yet.'));
          }

          // 4. Map Firestore Documents to your Complaint Model
          // We convert the List<QueryDocumentSnapshot> into List<Complaint>
          final List<Complaint> complaints = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Assuming your Complaint model has a factory or constructor like this:
            return Complaint(
              id: doc.id, // Firestore Document ID
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              status: data['status'] ?? 'Pending',
              date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList();

          return ListView.builder(
            itemCount: complaints.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              return ComplaintCard(complaint: complaints[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // No need to await or refresh manually! StreamBuilder handles it.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
    );
  }
}