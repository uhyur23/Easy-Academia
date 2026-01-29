import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/school_data_service.dart';
import 'package:provider/provider.dart';
import 'user_role.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserRole? _activeRole;
  String? _schoolId;
  String? _schoolName;
  String? _badgeUrl;
  List<String> _linkedStudentIds = [];
  String? _userName;
  List<String> _staffSubjects = [];
  bool _isFormMaster = false;
  bool _isInitialized = false;
  String? _authError;
  String? _userId;

  UserRole? get activeRole => _activeRole;
  String? get userId => _userId;
  String? get userName => _userName;
  // Backward compatibility: returns first subject or null
  String? get staffSubject =>
      _staffSubjects.isNotEmpty ? _staffSubjects.first : null;
  List<String> get staffSubjects => List.unmodifiable(_staffSubjects);
  String? get schoolId => _schoolId;
  String? get schoolName => _schoolName;
  String? get badgeUrl => _badgeUrl;
  List<String> get linkedStudentIds => List.unmodifiable(_linkedStudentIds);
  bool get isFormMaster => _isFormMaster;
  bool get isInitialized => _isInitialized;
  String? get authError => _authError;

  AppState() {
    // We'll let the UI initialize this or do it manually if needed,
    // but AppState usually needs a reference to SchoolDataService.
    // However, AppState is often a sibling to SchoolDataService.
    // Let's assume SchoolDataService is injected or accessible.
    _init();
  }

  void syncDataService(BuildContext context) {
    if (_schoolId != null) {
      context.read<SchoolDataService>().startListening(_schoolId!);
    }
  }

  Future<void> _init() async {
    // MANDATORY SPLASH DELAY: Ensure the splash screen is seen for at least 2.5 seconds
    final splashDelay = Future.delayed(const Duration(milliseconds: 2500));

    // Sync with Firebase Auth state
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _resetState();
      } else {
        // Fetch user profile from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _activeRole = UserRole.values.firstWhere(
            (e) => e.name == data['role'],
            orElse: () => UserRole.admin,
          );
          _schoolId = data['schoolId']?.toString().toUpperCase();
          _userName = data['name'];
          _linkedStudentIds = List<String>.from(data['linkedStudents'] ?? []);

          // Fetch School Profile
          if (_schoolId != null) {
            await _fetchSchoolProfile();
          }
        }
      }

      // Wait for the mandatory splash delay if it hasn't finished yet
      await splashDelay;

      _isInitialized = true;
      notifyListeners();
    });
  }

  void _resetState() {
    _activeRole = null;
    _schoolId = null;
    _schoolName = null;
    _userName = null;
    _staffSubjects = [];
    _badgeUrl = null;
    _linkedStudentIds = [];
    _isFormMaster = false;
  }

  Future<void> _fetchSchoolProfile() async {
    if (_schoolId == null) return;
    try {
      final schoolDoc = await _firestore
          .collection('schools')
          .doc(_schoolId)
          .get();
      if (schoolDoc.exists) {
        final data = schoolDoc.data()!;
        _schoolName = data['name'];
        _badgeUrl = data['badgeUrl'];
        debugPrint('Fetched School Profile: name=$_schoolName, id=$_schoolId');
      }
    } catch (e) {
      debugPrint('Error fetching school profile: $e');
    }
  }

  Future<bool> login(
    String identifier, // Email for Admin/Parent, Username for Staff
    String secret, // Password for Admin/Parent, PIN for Staff
    String schoolCode,
  ) async {
    _authError = null;
    try {
      // 1. Try Firebase Auth first (for Admin/Parent)
      // 1. Try Firebase Auth first (for Admin/Parent) only if it looks like an email
      try {
        if (identifier.contains('@')) {
          final credentials = await _auth.signInWithEmailAndPassword(
            email: identifier.trim(),
            password: secret.trim(),
          );

          if (credentials.user != null) {
            final doc = await _firestore
                .collection('users')
                .doc(credentials.user!.uid)
                .get();
            if (doc.exists) {
              final data = doc.data()!;
              if (data['schoolId'].toString().toUpperCase() ==
                  schoolCode.toUpperCase()) {
                _schoolId = data['schoolId'];

                // Explicitly set role
                _activeRole = UserRole.values.firstWhere(
                  (e) => e.name == data['role'],
                  orElse: () => UserRole.admin,
                );

                // Fetch School Profile IMMEDIATELY
                await _fetchSchoolProfile();

                _linkedStudentIds = List<String>.from(
                  data['linkedStudents'] ?? [],
                );
                _isInitialized = true;
                notifyListeners();
                return true;
              }
            }
          }
          await _auth.signOut();
        }
      } catch (e) {
        // Only log if it's not a poorly formatted email (which we expect for staff)
        if (identifier.contains('@')) {
          debugPrint('Firebase Auth Login (non-staff) failed: $e');
        }
      }

      // 2. Try Staff Login (Username/PIN)
      final staffQuery = await _firestore
          .collection('staff')
          .where('schoolId', isEqualTo: schoolCode.toUpperCase())
          .where('username', isEqualTo: identifier)
          .where('pin', isEqualTo: secret)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        // Authenticate anonymously to provide a Firestore context
        try {
          await _auth.signInAnonymously();
        } catch (e) {
          debugPrint('Anonymous Auth failed: $e');
          if (e.toString().contains('admin-restricted-operation')) {
            throw 'Staff login requiring grading access requires "Anonymous" authentication to be enabled in Firebase Console.';
          }
        }

        final staffData = staffQuery.docs.first.data();
        _activeRole = UserRole.staff;
        _userId = staffQuery.docs.first.id;
        _schoolId = staffData['schoolId'].toString().toUpperCase();
        _userName = staffData['name'];

        // Handle subjects (new list or old single string)
        if (staffData['subjects'] != null) {
          _staffSubjects = List<String>.from(staffData['subjects']);
        } else if (staffData['subject'] != null) {
          _staffSubjects = [staffData['subject']];
        } else {
          _staffSubjects = [];
        }

        _isFormMaster = staffData['isFormMaster'] ?? false;
        await _fetchSchoolProfile();
        _isInitialized = true;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('General Login Error: $e');
      _authError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? schoolName,
    UserRole role = UserRole.admin,
    String? existingSchoolId,
  }) async {
    try {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credentials.user != null) {
        String schoolId;

        if (role == UserRole.admin) {
          // Generate a new School ID for new schools
          schoolId =
              'SCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

          // Create School Profile
          await _firestore.collection('schools').doc(schoolId).set({
            'name': schoolName ?? 'New School',
            'createdAt': FieldValue.serverTimestamp(),
            'adminEmail': email,
          });
        } else {
          // For parents, use the provided School ID
          if (existingSchoolId == null || existingSchoolId.isEmpty) {
            return 'School ID is required for parent registration';
          }
          schoolId = existingSchoolId.toUpperCase();

          // Verify school exists
          final schoolDoc = await _firestore
              .collection('schools')
              .doc(schoolId)
              .get();
          if (!schoolDoc.exists) {
            return 'Invalid School ID. Please check with your school.';
          }
        }

        // Create User Profile
        await _firestore.collection('users').doc(credentials.user!.uid).set({
          'role': role.name,
          'schoolId': schoolId,
          'email': email,
          'name': role == UserRole.admin ? 'Administrator' : 'Parent',
          'linkedStudents': [],
        });

        // Update local state for immediate feedback
        _schoolId = schoolId;
        if (role == UserRole.admin) {
          _schoolName = schoolName;
        } else {
          await _fetchSchoolProfile();
        }

        return null; // Success
      }
      return 'User creation failed';
    } catch (e) {
      debugPrint('Signup Error: $e');
      return e.toString();
    }
  }

  Future<void> linkStudent(String studentId) async {
    if (!_linkedStudentIds.contains(studentId)) {
      _linkedStudentIds.add(studentId);
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'linkedStudents': _linkedStudentIds},
        );
      }
      notifyListeners();
    }
  }

  Future<void> updateSchoolProfile({String? name, String? badgeUrl}) async {
    if (_schoolId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (badgeUrl != null) updates['badgeUrl'] = badgeUrl;

    if (updates.isEmpty) return;

    await _firestore
        .collection('schools')
        .doc(_schoolId)
        .set(updates, SetOptions(merge: true));

    // Update local state
    if (name != null) _schoolName = name;
    if (badgeUrl != null) _badgeUrl = badgeUrl;
    notifyListeners();
  }

  Future<String?> uploadSchoolBadge(XFile imageFile) async {
    if (_schoolId == null) return 'No school ID found';

    try {
      // 1. Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // 2. Limit size if needed (e.g., if > 500KB, warn or compress)
      if (bytes.length > 1024 * 512) {
        return 'Image is too large. Please use a smaller logo (under 500KB).';
      }

      // 3. Convert to Base64 string
      final String base64Image = base64Encode(bytes);
      final String dataUrl = 'data:image/png;base64,$base64Image';

      // 4. Update profile in Firestore directly
      await updateSchoolProfile(badgeUrl: dataUrl);

      return null; // Success
    } catch (e) {
      debugPrint('Base64 Upload Error: $e');
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _resetState();
    notifyListeners();
  }
}
