import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_subject_screen.dart';
import 'edit_subject_screen.dart';

class ConfigureSemesterScreen extends StatefulWidget {
  const ConfigureSemesterScreen({super.key});

  @override
  State<ConfigureSemesterScreen> createState() => _ConfigureSemesterScreenState();
}

class _ConfigureSemesterScreenState extends State<ConfigureSemesterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _selectedSemester;
  List<String> _semesterOptions = [];
  Map<String, dynamic>? _semesterData;
  String? _duration;

  @override
  void initState() {
    super.initState();
    _fetchUserDurationAndSetCurrentSemester();
  }

  Future<void> _fetchUserDurationAndSetCurrentSemester() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Fetch user's duration to generate semester options
      final userDoc = await _firestore.collection('user_info').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _duration = userDoc.data()?['duration'];
          _generateSemesterOptions(_duration!);
        });
      }

      // Check for the current semester
      final semesters = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .where('current', isEqualTo: true)
          .limit(1)
          .get();

      if (semesters.docs.isNotEmpty) {
        final currentSemester = semesters.docs.first.id.replaceAll('_', ' ').capitalize();
        setState(() {
          _selectedSemester = currentSemester;
        });
        await _fetchSemesterData(currentSemester);
      }
    }
  }

  void _generateSemesterOptions(String duration) {
    int totalSemesters = int.parse(duration.split(' ')[0]) * 2;
    _semesterOptions = List.generate(totalSemesters, (index) => "Semester ${index + 1}");
  }

  Future<void> _fetchSemesterData(String semester) async {
    final user = _auth.currentUser;
    if (user != null) {
      final semesterDoc = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .doc(semester.toLowerCase().replaceAll(' ', '_'))
          .get();
      setState(() {
        _semesterData = semesterDoc.exists ? semesterDoc.data() : null;
      });
    }
  }

  void _addSubject() {
    if (_selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a semester first.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubjectScreen(
          semester: _selectedSemester!.toLowerCase().replaceAll(' ', '_'),
        ),
      ),
    ).then((_) {
      if (_selectedSemester != null) {
        _fetchSemesterData(_selectedSemester!);
      }
    });
  }

  Future<void> _setCurrentSemester() async {
    final user = _auth.currentUser;
    if (user != null && _selectedSemester != null) {
      final semestersRef = _firestore.collection('user_info').doc(user.uid).collection('semesters');
      final semesterDocs = await semestersRef.get();

      // Reset all current flags
      for (var doc in semesterDocs.docs) {
        await doc.reference.update({'current': false});
      }

      // Set selected semester as current
      await semestersRef
          .doc(_selectedSemester!.toLowerCase().replaceAll(' ', '_'))
          .set({'current': true}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current semester updated!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure Semester", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: _duration == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Semester Configuration",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedSemester,
                items: _semesterOptions.map((semester) {
                  return DropdownMenuItem(value: semester, child: Text(semester));
                }).toList(),
                decoration: InputDecoration(
                  labelText: "Select Semester",
                  labelStyle: TextStyle(color: Colors.green.shade700),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                    _semesterData = null;
                  });
                  _fetchSemesterData(value!);
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_semesterData != null) ...[
              Text(
                "Subjects",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 10),
              ...(_semesterData!['subjects'] ?? []).map<Widget>((subject) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    tileColor: Colors.green.shade50,
                    title: Text(
                      subject['subjectName'],
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800),
                    ),
                    subtitle: Text(
                      "Code: ${subject['subjectCode']}\nType: ${subject['subjectType']}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditSubjectScreen(
                                  semester: _selectedSemester!
                                      .toLowerCase()
                                      .replaceAll(' ', '_'),
                                  subjectData: subject,
                                ),
                              ),
                            ).then((_) {
                              _fetchSemesterData(_selectedSemester!);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _removeSubject(subject['subjectCode']);
                            _fetchSemesterData(_selectedSemester!);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ] else if (_selectedSemester != null) ...[
              Text(
                "Semester is not configured yet.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setCurrentSemester,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Set as Current Semester",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addSubject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Add Subjects",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeSubject(String subjectCode) async {
    final user = _auth.currentUser;
    if (user != null && _selectedSemester != null) {
      final semesterRef = _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .doc(_selectedSemester!.toLowerCase().replaceAll(' ', '_'));

      final semesterDoc = await semesterRef.get();
      if (semesterDoc.exists) {
        final subjects = List<Map<String, dynamic>>.from(semesterDoc.data()!['subjects']);
        subjects.removeWhere((subject) => subject['subjectCode'] == subjectCode);

        await semesterRef.update({'subjects': subjects});
      }
    }
  }
}

// Helper extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
