import 'package:complaint_system/screens/track_complaint_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_system/screens/nearby_complaints_screen.dart';
import 'package:complaint_system/models/complaint_model.dart';
import 'package:complaint_system/screens/add_complaint_screen.dart';
import 'package:complaint_system/complaint_card.dart';
import 'package:complaint_system/screens/login_screen.dart';
import 'package:complaint_system/screens/ProfileScreen.dart';
import '../services/app_localizations.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  // Current user from Firebase Auth
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Variables to hold Firestore data
  String? userName;
  bool _isLoadingName = true;

  static const primaryPurple = Color(0xFF5B2D91);
  static const bgColor = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
  }

  /// Fetches the user's name from the 'Users' collection in Firestore
  Future<void> _fetchUserData() async {
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users') // Ensure this matches your Firestore collection name exactly
          .doc(currentUser!.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          // Assuming your Firestore field is called 'name'
          userName = userDoc.data()?['name'] ?? currentUser?.displayName ?? "Citizen";
          _isLoadingName = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingName = false);
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) setState(() => _isLoadingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APPBAR =================
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.translate('my_complaints') ?? "My Complaints"),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'track') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackComplaintScreen()));
              } else if (value == 'find') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyComplaintsScreen()));
              } else if (value == 'help') {
                _showHelpDialog();
              }
            },
            itemBuilder: (context) => [
              _menuItem(Icons.person, AppLocalizations.of(context)?.translate('my_profile') ?? "My Profile", "profile"),
              _menuItem(Icons.search, AppLocalizations.of(context)?.translate('find_complaint') ?? "Find Complaint", "find"),
              _menuItem(Icons.track_changes, AppLocalizations.of(context)?.translate('track_complaint') ?? "Track Complaint", "track"),
              _menuItem(Icons.help_outline, AppLocalizations.of(context)?.translate('help') ?? "Help", "help"),
            ],
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

      // ================= BODY =================
      body: Column(
        children: [
          _headerSection(),
          Expanded(child: _complaintList()),
        ],
      ),

      // ================= FAB =================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddComplaintScreen()));
        },
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.translate('new_complaint') ?? "New Complaint"),
      ),
    );
  }

  // ================= HEADER =================
  Widget _headerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('welcome') ?? "Welcome",
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 6),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                var data = snapshot.data!.data() as Map<String, dynamic>?;
                String name = (data?['name'] ?? "Citizen").toString().toUpperCase();
                return Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                );
              }
              return const Text("Loading...");
            },
          ),
          const SizedBox(height: 14),
          const Text(
            "Track and manage your complaints easily",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= COMPLAINT LIST =================
  Widget _complaintList() {
    return StreamBuilder<QuerySnapshot>(
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
          debugPrint(snapshot.error.toString());
          return const Center(child: Text("Error loading complaints. Check Firestore Indexes."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)?.translate('no_complaints') ?? "No complaints yet",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text("Tap + to submit a complaint", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final complaints = snapshot.data!.docs.map((doc) {
          return Complaint.fromFirestore(doc.data() as Map<String, dynamic>);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 80),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            return ComplaintCard(complaint: complaints[index]);
          },
        );
      },
    );
  }

  // ================= HELPERS =================
  PopupMenuItem<String> _menuItem(IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Help'),
        content: Text('Contact support for assistance at support@complaintsystem.com'),
      ),
    );
  }
}