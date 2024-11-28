import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _subjects = [];
  Map<String, String> _attendanceStatus = {};
  String? _currentSemester;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSemesterAndSubjects();
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

        // Fetch subjects and attendance
        final subjects = List<Map<String, dynamic>>.from(
            semesterDoc.data()['subjects'] ?? []);
        final attendanceRef = _firestore
            .collection('user_info')
            .doc(user.uid)
            .collection('attendance')
            .doc(_currentSemester);

        final today = DateTime.now();
        final dateKey =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        final attendanceDoc = await attendanceRef.get();
        final attendanceData = attendanceDoc.exists ? attendanceDoc.data() : {};

        setState(() {
          _subjects = subjects;
          _attendanceStatus = Map.fromIterable(
            subjects,
            key: (subject) => subject['subjectCode'],
            value: (subject) {
              final code = subject['subjectCode'];
              if (attendanceData != null &&
                  attendanceData.containsKey(code) &&
                  attendanceData[code][dateKey] != null) {
                // If attendance already exists for today, return 'submitted'
                return 'submitted';
              }
              return 'none'; // Otherwise, initialize as 'none'
            },
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _markAttendance(String subjectCode, String status,
      [String? reason]) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester == null) return;

    final attendanceRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('attendance')
        .doc(_currentSemester);

    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day
        .toString().padLeft(2, '0')}";

    await attendanceRef.set({
      subjectCode: {
        dateKey: {
          'status': status,
          'reason': reason ?? '',
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> _submitAttendance() async {
    for (var entry in _attendanceStatus.entries) {
      if (entry.value != 'none') {
        if (entry.value == 'absent' || entry.value == 'OD') {
          // Ask for reason if absent/OD
          String? reason = await _showReasonDialog(entry.key);
          if (reason != null) {
            await _markAttendance(entry.key, entry.value, reason);
          }
        } else {
          await _markAttendance(entry.key, entry.value);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance submitted successfully!")),
    );

    setState(() {
      for (var subject in _subjects) {
        _attendanceStatus[subject['subjectCode']] = 'submitted';
      }
    });
  }



  Future<String?> _showReasonDialog(String subjectCode) async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              'Reason for ${_getSubjectName(subjectCode)}',
              style: TextStyle(color: Colors.green.shade700),
            ),
            content: TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: "Enter reason",
                labelStyle: TextStyle(color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade700),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, reasonController.text.trim()),
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  String _getSubjectName(String subjectCode) {
    return _subjects
        .firstWhere((subject) => subject['subjectCode'] == subjectCode,
        orElse: () => {'subjectName': 'Unknown'})['subjectName'] ??
        'Unknown';
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage < 75) return Colors.red;
    if (percentage < 85) return Colors.orange;
    return Colors.green;
  }

  Future<List<Map<String, dynamic>>> _fetchAttendanceHistory(
      String subjectCode) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester == null) return [];

    final attendanceRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('attendance')
        .doc(_currentSemester);

    final attendanceDoc = await attendanceRef.get();
    if (attendanceDoc.exists && attendanceDoc.data()![subjectCode] != null) {
      final attendanceData = attendanceDoc.data()![subjectCode] as Map<
          String,
          dynamic>;
      return attendanceData.entries.map((entry) {
        return {
          'date': entry.key,
          'status': entry.value['status'],
          'reason': entry.value['reason'] ?? '',
        };
      }).toList();
    }
    return [];
  }

  Future<void> _editAttendance(String subjectCode, String date, String status,
      [String? reason]) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester == null) return;

    final attendanceRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('attendance')
        .doc(_currentSemester);

    await attendanceRef.set({
      subjectCode: {
        date: {
          'status': status,
          'reason': reason ?? '',
        }
      }
    }, SetOptions(merge: true));
  }

  Future<double> _calculateAttendancePercentage(String subjectCode) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester == null) return 0;

    final attendanceRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('attendance')
        .doc(_currentSemester);

    final attendanceDoc = await attendanceRef.get();
    if (attendanceDoc.exists && attendanceDoc.data()![subjectCode] != null) {
      final attendanceData = attendanceDoc.data()![subjectCode] as Map<
          String,
          dynamic>;
      final total = attendanceData.length;
      final presentOrOD = attendanceData.values
          .where((entry) =>
      entry['status'] == 'present' || entry['status'] == 'OD')
          .length;
      return total > 0 ? (presentOrOD / total) * 100 : 0;
    }
    return 0;
  }



  Widget _buildAttendanceCard(Map<String, dynamic> subject) {
    final subjectCode = subject['subjectCode'];

    return FutureBuilder<double>(
      future: _calculateAttendancePercentage(subjectCode),
      builder: (context, snapshot) {
        final percentage = snapshot.data ?? 0.0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  subject['subjectName'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                subtitle: Text(
                  "Attendance: ${percentage.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontSize: 14,
                    color: _getAttendanceColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: _attendanceStatus[subjectCode] == 'none'
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green.shade700),
                      onPressed: () {
                        setState(() {
                          _attendanceStatus[subjectCode] = 'present';
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        final reason = await _showReasonDialog(subjectCode);
                        if (reason != null) {
                          setState(() {
                            _attendanceStatus[subjectCode] = 'absent';
                          });
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () async {
                        final reason = await _showReasonDialog(subjectCode);
                        if (reason != null) {
                          setState(() {
                            _attendanceStatus[subjectCode] = 'OD';
                          });
                        }
                      },
                      child: const Text(
                        "OD",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                )
                    : null,
              ),
              const Divider(),
              ExpansionTile(
                title: const Text(
                  "View Attendance History",
                  style: TextStyle(fontSize: 14),
                ),
                children: [
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchAttendanceHistory(subjectCode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final attendanceHistory = snapshot.data ?? [];
                      if (attendanceHistory.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("No attendance records available."),
                        );
                      }

                      return Column(
                        children: attendanceHistory.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final record = entry.value;
                          final statusIcon = record['status'] == 'present' ||
                              record['status'] == 'OD'
                              ? const Icon(Icons.check, color: Colors.green, size: 16)
                              : const Icon(Icons.close, color: Colors.red, size: 16);

                          return ListTile(
                            leading: Text(
                              "$index",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  "${record['date'].split('-').reversed.join('-')}  ${record['status']}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                statusIcon,
                              ],
                            ),
                            subtitle: Text(
                              record['reason'].isNotEmpty
                                  ? "Reason: ${record['reason']}"
                                  : "Reason: None",
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final newStatus = await _showEditAttendanceDialog(
                                  context,
                                  subjectCode,
                                  record['date'],
                                  record['status'],
                                  record['reason'],
                                );
                                if (newStatus != null) {
                                  await _editAttendance(
                                    subjectCode,
                                    record['date'],
                                    newStatus['status']!,
                                    newStatus['reason'],
                                  );
                                  setState(() {});
                                }
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Mark Attendance for ${_currentSemester ?? "No Semester"}",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _subjects.length,
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  return _buildAttendanceCard(subject);
                },
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  for (var subject in _subjects) {
                    _attendanceStatus[subject['subjectCode']] = 'absent';
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Mark All Absent",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  for (var subject in _subjects) {
                    _attendanceStatus[subject['subjectCode']] = 'present';
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Mark All Present",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Submit Attendance",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, String>?> _showEditAttendanceDialog(
    BuildContext dialogContext, // Accept context here
    String subjectCode,
    String date,
    String currentStatus,
    String currentReason) async {
  String? newStatus = currentStatus;
  final reasonController = TextEditingController(text: currentReason);

  return showDialog<Map<String, String>>(
    context: dialogContext, // Use the passed context
    builder: (BuildContext context) => AlertDialog(
      title: Text(
        "Edit Attendance for $date",
        style: TextStyle(color: Colors.green.shade700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: newStatus,
            decoration: InputDecoration(
              labelText: "Attendance Status",
              labelStyle: TextStyle(color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'present', child: Text("Present")),
              DropdownMenuItem(value: 'absent', child: Text("Absent")),
              DropdownMenuItem(value: 'OD', child: Text("OD")),
            ],
            onChanged: (value) => newStatus = value,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: "Reason (if applicable)",
              labelStyle: TextStyle(color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext), // Use dialogContext
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            dialogContext, // Use dialogContext
            {'status': newStatus!, 'reason': reasonController.text.trim()},
          ),
          child: const Text("Save"),
        ),
      ],
    ),
  );
}
