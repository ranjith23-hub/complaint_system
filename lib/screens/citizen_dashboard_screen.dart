import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/add_complaint_screen.dart';
import 'package:complaint_system/complaint_card.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/ProfileScreen.dart';
import 'package:complaint_system/screens/track_complaint_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Function to handle logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // Function to handle menu selections
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'Profile':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen())
        );
        break;
      case 'My Complaints':
      // Already on this screen
        break;
      case 'Complaint Status':
      case 'Complaint Status':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrackComplaintScreen())
        );
        break;
        break;
      case 'Help':
      // TODO: Navigate to Help/Support Screen
        break;
      case 'Logout':
        _logout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicConnect'),
        backgroundColor: const Color(0xFF0D47A1), // Consistent Blue branding
        foregroundColor: Colors.white,
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

          // --- 3-DOT MENU BUTTON ---
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'Profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'My Complaints',
                child: ListTile(
                  leading: Icon(Icons.list_alt),
                  title: Text('My Complaints'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'Complaint Status',
                child: ListTile(
                  leading: Icon(Icons.track_changes),
                  title: Text('Complaint Status'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'Help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'Logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
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

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No complaints filed yet.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final List<Complaint> complaints = snapshot.data!.docs.map((doc) {
            return Complaint.fromFirestore(doc.data() as Map<String, dynamic>);
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
        backgroundColor: const Color(0xFF4CAF50), // Consistent Green branding
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddComplaintScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Complaint', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}