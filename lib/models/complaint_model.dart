import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String complaintId;
  final String title;
  final String description;
  final String category;
  String status;
  final String priority;
  final DateTime date;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String userId;
  String assignedTo;

  Complaint({
    required this.complaintId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.date,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.userId,
    this.assignedTo = 'sakthi@gmail.com',
  });

  factory Complaint.fromFirestore(Map<String, dynamic> data) {
    return Complaint(
      complaintId: data['complaintId'] ?? '',
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'Submitted',
      priority: data['priority'] ?? 'MEDIUM',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      userId: data['userId'] ?? '',
      assignedTo: data['assignedTo'] ?? 'sakthi@gmail.com', // 👈 fallback
    );
  }
  factory Complaint.fromWorkerFirestore(
      Map<String, dynamic> data,
      String docId,
      ) {
    return Complaint(
      complaintId: docId,
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      status: data['status'] ?? 'Submitted',
      priority: data['priority'] ?? 'MEDIUM',
      date: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      userId: data['userId'] ?? '',
      assignedTo: data['assignedTo'] ?? 'sakthi@gmail.com', // 👈 fallback
    );
  }

}