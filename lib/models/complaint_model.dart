import 'package:flutter/material.dart';

enum ComplaintStatus { Submitted, InProgress, Resolved }

class Complaint {
  final String id;
  final String title;
  final String description;
  final String department;
  final ComplaintStatus status;
  final String priority;
  final DateTime submittedDate;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.status,
    required this.priority,
    required this.submittedDate,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  // 👇 ADD THIS FACTORY CONSTRUCTOR TO DECODE JSON
  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      department: json['department'],
      // Convert the status string from JSON back to an enum
      status: ComplaintStatus.values.firstWhere(
            (e) => e.toString() == 'ComplaintStatus.${json['status']}',
        orElse: () => ComplaintStatus.Submitted, // Default value
      ),
      priority: json['priority'],
      // Convert the date string from JSON back to a DateTime object
      submittedDate: DateTime.parse(json['submittedDate']),
      imageUrl: json['imageUrl'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  // 👇 ADD THIS METHOD TO ENCODE TO JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'department': department,
      // Convert the enum to a string for JSON
      'status': status.toString().split('.').last,
      'priority': priority,
      // Convert DateTime to a standardized string format
      'submittedDate': submittedDate.toIso8601String(),
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Helper to get color based on status
  Color get statusColor {
    switch (status) {
      case ComplaintStatus.Submitted:
        return Colors.blue;
      case ComplaintStatus.InProgress:
        return Colors.orange;
      case ComplaintStatus.Resolved:
        return Colors.green;
    }
  }

  // Helper to get icon based on department
  IconData get departmentIcon {
    switch (department) {
      case 'Plumbing':
        return Icons.water_damage;
      case 'Electrical':
        return Icons.flash_on;
      case 'Waste Disposal':
        return Icons.delete;
      case 'Roads & Infrastructure':
        return Icons.edit_road;
      default:
        return Icons.report_problem;
    }
  }
}