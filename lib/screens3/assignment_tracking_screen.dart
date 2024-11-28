import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AssignmentTrackingScreen extends StatefulWidget {
  const AssignmentTrackingScreen({super.key});

  @override
  State<AssignmentTrackingScreen> createState() => _AssignmentTrackingScreenState();
}

class _AssignmentTrackingScreenState extends State<AssignmentTrackingScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _currentSemester = "";
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSemesterAndSubjects().then((_) => _loadAssignments());
  }

  Future<void> _loadCurrentSemesterAndSubjects() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Fetch current semester
      final semestersSnapshot = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .where('current', isEqualTo: true)
          .limit(1)
          .get();

      if (semestersSnapshot.docs.isNotEmpty) {
        final semesterDoc = semestersSnapshot.docs.first;
        _currentSemester = semesterDoc.id;

        // Fetch subjects for the current semester
        setState(() {
          _subjects = List<Map<String, dynamic>>.from(semesterDoc.data()['subjects'] ?? []);
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final assignmentSnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('assignments')
        .get();

    setState(() {
      _assignments = assignmentSnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();
      _isLoading = false;
    });
  }

  void _showAddOrEditAssignmentDialog({Map<String, dynamic>? existingAssignment}) {
    String selectedSubject = existingAssignment?['subjectCode'] ?? "";
    String assignmentType = existingAssignment?['assignmentType'] ?? "WrittenWork";
    String submissionType = existingAssignment?['submissionType'] ?? "GCR";
    String assignmentDesc = existingAssignment?['assignmentDesc'] ?? "";
    DateTime? deadlineDate = existingAssignment != null
        ? (existingAssignment['deadline'] as Timestamp).toDate()
        : null;
    TimeOfDay? deadlineTime = existingAssignment != null
        ? TimeOfDay.fromDateTime((existingAssignment['deadline'] as Timestamp).toDate())
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existingAssignment == null ? "Add Assignment" : "Edit Assignment",
                style: TextStyle(color: Colors.green.shade700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSubject.isNotEmpty ? selectedSubject : null,
                      decoration: InputDecoration(
                        labelText: "Select Subject",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      items: _subjects.map((subject) {
                        return DropdownMenuItem<String>(
                          value: subject['subjectCode'],
                          child: Text(subject['subjectCode']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value ?? "";
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: assignmentType,
                      decoration: InputDecoration(
                        labelText: "Assignment Type",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      items: ['WrittenWork', 'SystemWork', 'Both', 'QuickTask']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          assignmentType = value ?? "WrittenWork";
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: assignmentDesc),
                      decoration: InputDecoration(
                        labelText: "Assignment Description",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        assignmentDesc = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: submissionType,
                      decoration: InputDecoration(
                        labelText: "Submission Type",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      items: ['GCR', 'Hardcopy', 'Both', 'Other']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          submissionType = value ?? "GCR";
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        deadlineDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        setState(() {});
                      },
                      child: Text(
                        deadlineDate == null
                            ? "Select Deadline Date"
                            : "Date: ${DateFormat('dd/MM/yyyy').format(deadlineDate!)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        deadlineTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        setState(() {});
                      },
                      child: Text(
                        deadlineTime == null
                            ? "Select Deadline Time"
                            : "Time: ${deadlineTime!.format(context)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedSubject.isNotEmpty &&
                        assignmentDesc.isNotEmpty &&
                        deadlineDate != null) {
                      await _addOrUpdateAssignment(
                          existingAssignment?['id'],
                          selectedSubject,
                          assignmentType,
                          assignmentDesc,
                          submissionType,
                          deadlineDate!,
                          deadlineTime);
                      Navigator.pop(context);
                      await _loadAssignments();
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addOrUpdateAssignment(
      String? assignmentId,
      String subjectCode,
      String assignmentType,
      String assignmentDesc,
      String submissionType,
      DateTime deadlineDate,
      TimeOfDay? deadlineTime,
      ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final deadline = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
      deadlineTime?.hour ?? 0,
      deadlineTime?.minute ?? 0,
    );

    final data = {
      'subjectCode': subjectCode,
      'assignmentType': assignmentType,
      'assignmentDesc': assignmentDesc,
      'submissionType': submissionType,
      'deadline': deadline,
    };

    final assignmentsRef = _firestore.collection('user_info').doc(user.uid).collection('assignments');
    if (assignmentId != null) {
      await assignmentsRef.doc(assignmentId).update(data);
    } else {
      await assignmentsRef.add(data);
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('assignments')
        .doc(assignmentId)
        .delete();

    await _loadAssignments();
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment, int index) {
    final deadline = (assignment['deadline'] as Timestamp).toDate();
    final subject = _subjects.firstWhere(
            (subject) => subject['subjectCode'] == assignment['subjectCode'],
        orElse: () => {'subjectName': 'Unknown'});

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${index + 1}. ${assignment['subjectCode']} - ${subject['subjectName']}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Text(
              "Assignment Desc: ${assignment['assignmentDesc']}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              "Assignment Type: ${assignment['assignmentType']}  Submission Type: ${assignment['submissionType']}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Deadline: ${DateFormat('dd/MM/yyyy').format(deadline)} ${deadlineTimeFormat(deadline)}",
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddOrEditAssignmentDialog(existingAssignment: assignment),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _deleteAssignment(assignment['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String deadlineTimeFormat(DateTime deadline) {
    return deadline.hour != 0 || deadline.minute != 0
        ? DateFormat('h:mm a').format(deadline)
        : "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assignment Tracking",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: _showAddOrEditAssignmentDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _assignments.isEmpty
            ? const Center(child: Text("No assignments added."))
            : ListView.builder(
          itemCount: _assignments.length,
          itemBuilder: (context, index) {
            return _buildAssignmentCard(_assignments[index], index);
          },
        ),
      ),
    );
  }
}
