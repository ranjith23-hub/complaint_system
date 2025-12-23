import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime date;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.date,
  });

  // Factory constructor to easily create a Complaint from a Firestore Document
  factory Complaint.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Complaint(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? 'No Description',
      status: data['status'] ?? 'Pending',
      // Firestore stores time as 'Timestamp', we need to convert it to DateTime
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}