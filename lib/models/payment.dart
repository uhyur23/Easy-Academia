import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String? studentId;
  final String? studentName;
  final String category; // 'School Fees', 'Donation', 'Sales', 'Other'
  final String description;
  final double amount;
  final DateTime timestamp;
  final String schoolId;
  final String status; // 'completed', 'pending'

  Payment({
    required this.id,
    this.studentId,
    this.studentName,
    required this.category,
    this.description = '',
    required this.amount,
    required this.timestamp,
    required this.schoolId,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'category': category,
      'description': description,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'schoolId': schoolId,
      'status': status,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      studentId: map['studentId'],
      studentName: map['studentName'],
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      schoolId: map['schoolId'] ?? '',
      status: map['status'] ?? 'completed',
    );
  }
}
