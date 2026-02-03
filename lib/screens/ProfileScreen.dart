import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Helper function to count complaints by status
  Future<int> getComplaintCount(String uid, String status) async {
    try {
      var snapshot;
      if(status=='Resolved') {
        snapshot = await FirebaseFirestore.instance
            .collection('complaints')
            .where('userId', isEqualTo: uid)
            .where('status', isEqualTo: status)
            .get();
      }
      else{
        snapshot = await FirebaseFirestore.instance
            .collection('complaints')
            .where('userId', isEqualTo: uid)
            .where('status', isNotEqualTo: "Resolved")
            .get();
      }
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Navigate back to login or root
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor:   const Color(0xFF5B2D91), // Civic Blue
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Error loading profile"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String uid = user?.uid ?? "";

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- Header Section ---
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color:   const Color(0xFF5B2D91),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        backgroundImage: userData['url'] != null
                            ? NetworkImage(userData['url'])
                            : null,
                        child: userData['url'] == null
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userData['name'] ?? 'Guest User',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        userData['email'] ?? '',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Complaint Statistics Section ---
                      const Text(
                        "Complaint Overview",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(height: 15),

                      Row(
                        children: [
                          _buildStatCard("Pending", uid, Colors.orange),
                          const SizedBox(width: 12),
                          _buildStatCard("Resolved", uid, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // --- Personal Details ---
                      const Text(
                        "Personal Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                      ),
                      const SizedBox(height: 10),
                      _buildProfileTile(Icons.phone_outlined, "Phone Number", userData['phone']),
                      _buildProfileTile(Icons.home_outlined, "Home Address", userData['address']),

                      // Show Hard-Fact Coordinates if they exist
                      if (userData['latitude'] != null)
                        _buildProfileTile(
                            Icons.gps_fixed,
                            "Registered GPS Location",
                            "Lat: ${userData['latitude'].toStringAsFixed(4)}, Lng: ${userData['longitude'].toStringAsFixed(4)}"
                        ),

                      const SizedBox(height: 30),

                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {}, // Future Edit Logic
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D47A1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget for the Stat Cards (Pending/Resolved)
  Widget _buildStatCard(String status, String uid, Color color) {
    return Expanded(
      child: FutureBuilder<int>(
        future: getComplaintCount(uid, status),
        builder: (context, snapshot) {
          int count = snapshot.data ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  status,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget for Info Tiles
  Widget _buildProfileTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
        ),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(
          value ?? "Not set",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ),
    );
  }
}