import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = StringBuffer();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final firestore = FirebaseFirestore.instance;
    final schoolId = 'SCH-880096';

    results.writeln('--- [DATA INSPECTOR] ---');

    // 1. Check Students
    final studentsQ = await firestore
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    results.writeln('\nSTUDENTS (${studentsQ.docs.length}):');
    for (var doc in studentsQ.docs) {
      final d = doc.data();
      results.writeln(
        '  - Name: "${d['name']}", Grade: "${d['grade']}", ID: ${d['id']}',
      );
    }

    // 2. Check ALL Grades (Unfiltered)
    final gradesQ = await firestore
        .collection('grades')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    results.writeln('\nGRADE RECORDS (${gradesQ.docs.length}):');
    for (var doc in gradesQ.docs) {
      final d = doc.data();
      results.writeln('  - StudentId: "${d['studentId']}"');
      results.writeln('    ClassLevel: "${d['classLevel']}"');
      results.writeln('    Term:       "${d['term']}"');
      results.writeln('    Session:    "${d['session']}"');
      results.writeln('    Subject:    "${d['subject']}"');
      results.writeln('    ---');
    }

    results.writeln('\n--- [INSPECTION COMPLETE] ---');

    final file = File('inspection_results.txt');
    await file.writeAsString(results.toString());
    print('Results written to inspection_results.txt');
  } catch (e) {
    print('ERROR: $e');
  }
}
