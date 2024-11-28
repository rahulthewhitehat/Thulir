import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _currentSemester = "";
  List<String> _semesters = [];
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic> _marksData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    final user = _auth.currentUser;
    if (user != null) {
      final semestersSnapshot = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .get();

      final currentSemesterDoc = await _firestore
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .where('current', isEqualTo: true)
          .limit(1)
          .get();

      if (currentSemesterDoc.docs.isNotEmpty) {
        setState(() {
          _currentSemester = currentSemesterDoc.docs.first.id;
        });
      }

      setState(() {
        _semesters = semestersSnapshot.docs.map((doc) => doc.id).toList();
        _isLoading = false;
      });

      if (_currentSemester.isNotEmpty) {
        await _loadSubjectsAndMarks(_currentSemester);
      }
    }
  }

  Future<void> _loadSubjectsAndMarks(String semester) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final semesterDoc = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('semesters')
        .doc(semester)
        .get();

    final marksDoc = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(semester)
        .get();

    setState(() {
      _subjects = List<Map<String, dynamic>>.from(semesterDoc.data()?['subjects'] ?? []);
      _marksData = marksDoc.exists ? marksDoc.data() ?? {} : {};
    });
  }

  Widget _buildMarksCard(String examType) {
    final filteredMarks = _marksData.entries
        .where((entry) =>
    entry.value is Map &&
        entry.value.containsKey(examType) &&
        entry.value[examType] != null)
        .toList();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                examType,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: () => _showAddEditMarksDialog(examType),
            ),
          ],
        ),
        children: [
          if (filteredMarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("No marks data available."),
            ),
          if (filteredMarks.isNotEmpty)
            Column(
              children: filteredMarks.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final subjectCode = entry.value.key;
                final data = entry.value.value[examType];
                final subject = _subjects.firstWhere(
                      (sub) => sub['subjectCode'] == subjectCode,
                  orElse: () => {'subjectName': 'Unknown'},
                );

                final percentage = (data['obtained'] / data['total']) * 100;

                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$index. ${subject['subjectCode']} - ${subject['subjectName']}",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2, // Display up to 2 lines
                        softWrap: true, // Enable wrapping
                        overflow: TextOverflow.ellipsis, // Prevent overflow into pixels
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${data['obtained']}/${data['total']} (${percentage.toStringAsFixed(1)}%)",
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showAddEditMarksDialog(examType, subjectCode, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteSubjectMarks(subjectCode, examType),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEndSemCard() {
    final endSemMarks = _marksData.entries
        .where((entry) =>
    entry.value is Map &&
        entry.value.containsKey('endSem') &&
        entry.value['endSem'] != null)
        .toList();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "End Semester Exam",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.green),
              onPressed: _showAddEndSemDialog,
            ),
          ],
        ),
        children: [
          if (endSemMarks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("No marks data available."),
            ),
          if (endSemMarks.isNotEmpty)
            Column(
              children: endSemMarks.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final subjectCode = entry.value.key;
                final grade = entry.value.value['endSem']['grade'];
                final subject = _subjects.firstWhere(
                      (sub) => sub['subjectCode'] == subjectCode,
                  orElse: () => {'subjectName': 'Unknown'},
                );

                return ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$index. ${subject['subjectCode']} - ${subject['subjectName']}",
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2, // Display up to 2 lines
                        softWrap: true, // Enable wrapping
                        overflow: TextOverflow.ellipsis, // Prevent overflow into pixels
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Grade: $grade",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showEditEndSemDialog(subjectCode, grade),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEndSemSubject(subjectCode),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (_marksData.containsKey('gpa'))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "GPA: ${_marksData['gpa']}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          TextButton(
            onPressed: _showGpaDialog,
            child: const Text("View/Edit GPA"),
          ),
        ],
      ),
    );
  }

  void _showAddEndSemDialog() {
    String selectedSubject = "";
    String selectedGrade = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Add End Semester Marks",
            style: TextStyle(color: Colors.green.shade700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown for selecting subject
                DropdownButtonFormField<String>(
                  value: selectedSubject.isNotEmpty ? selectedSubject : null,
                  decoration: InputDecoration(
                    labelText: "Select Subject Code",
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['subjectCode'],
                      child: Text(subject['subjectCode']), // Show only subject code
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedSubject = value ?? "";
                  },
                ),
                const SizedBox(height: 10),

                // Dropdown for selecting grade
                DropdownButtonFormField<String>(
                  value: selectedGrade.isNotEmpty ? selectedGrade : null,
                  decoration: InputDecoration(
                    labelText: "Grade",
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  items: ['O', 'A+', 'A', 'B+', 'B', 'C+', 'C', 'Arrear']
                      .map((grade) => DropdownMenuItem(
                    value: grade,
                    child: Text(grade),
                  ))
                      .toList(),
                  onChanged: (value) {
                    selectedGrade = value ?? "";
                  },
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
                if (selectedSubject.isNotEmpty && selectedGrade.isNotEmpty) {
                  await _saveEndSemData(selectedSubject, selectedGrade);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showEditEndSemDialog(String subjectCode, String currentGrade) {
    String selectedGrade = currentGrade;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Edit End Semester Marks",
            style: TextStyle(color: Colors.green.shade700),
          ),
          content: DropdownButtonFormField<String>(
            value: selectedGrade.isNotEmpty ? selectedGrade : null,
            decoration: InputDecoration(
              labelText: "Grade",
              labelStyle: TextStyle(color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
            ),
            items: ['O', 'A+', 'A', 'B+', 'B', 'C+', 'C', 'Arrear']
                .map((grade) => DropdownMenuItem(
              value: grade,
              child: Text(grade),
            ))
                .toList(),
            onChanged: (value) {
              selectedGrade = value ?? "";
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (selectedGrade.isNotEmpty) {
                  await _saveEndSemData(subjectCode, selectedGrade);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEndSemData(String subjectCode, String grade) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty || subjectCode.isEmpty) return;

    final marksRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(_currentSemester);

    await marksRef.set({
      subjectCode: {
        'endSem': {'grade': grade},
      },
    }, SetOptions(merge: true));

    await _loadSubjectsAndMarks(_currentSemester);
  }

  Future<void> _deleteEndSemSubject(String subjectCode) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty || subjectCode.isEmpty) return;

    final marksRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(_currentSemester);

    await marksRef.update({
      '$subjectCode.endSem': FieldValue.delete(),
    });

    await _loadSubjectsAndMarks(_currentSemester);
  }



  void _showGpaDialog() {
    String gpa = _marksData['gpa']?.toString() ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Add/Edit GPA",
            style: TextStyle(color: Colors.green.shade700),
          ),
          content: TextField(
            controller: TextEditingController(text: gpa),
            decoration: InputDecoration(
              labelText: "GPA",
              labelStyle: TextStyle(color: Colors.green.shade700),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.green.shade700),
              ),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => gpa = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _saveGpaData(double.tryParse(gpa) ?? 0.0);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveGpaData(double gpa) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    final marksRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(_currentSemester);

    await marksRef.set({'gpa': gpa}, SetOptions(merge: true));

    await _loadSubjectsAndMarks(_currentSemester);
  }



  void _showAddEditMarksDialog(String examType, [String? subjectCode, Map<String, dynamic>? existingData]) {
    String selectedSubject = subjectCode ?? "";
    String obtainedMarks = existingData?['obtained']?.toString() ?? "";
    String totalMarks = existingData?['total']?.toString() ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            subjectCode == null ? "Add Marks" : "Edit Marks",
            style: TextStyle(color: Colors.green.shade700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown for selecting subject
                DropdownButtonFormField<String>(
                  value: selectedSubject.isNotEmpty ? selectedSubject : null,
                  decoration: InputDecoration(
                    labelText: "Select Subject Code",
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  items: _subjects.map((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['subjectCode'],
                      child: Text(subject['subjectCode']), // Show only subject code
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedSubject = value ?? "";
                  },
                ),
                const SizedBox(height: 10),

                // Input for obtained marks
                TextField(
                  controller: TextEditingController(text: obtainedMarks),
                  decoration: InputDecoration(
                    labelText: "Obtained Marks",
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => obtainedMarks = value,
                ),
                const SizedBox(height: 10),

                // Dropdown for total marks
                DropdownButtonFormField<String>(
                  value: totalMarks.isNotEmpty ? totalMarks : null,
                  decoration: InputDecoration(
                    labelText: "Total Marks",
                    labelStyle: TextStyle(color: Colors.green.shade700),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green.shade700),
                    ),
                  ),
                  items: ['30', '60', '75', '100']
                      .map((marks) => DropdownMenuItem(
                    value: marks,
                    child: Text(marks),
                  ))
                      .toList(),
                  onChanged: (value) => totalMarks = value ?? "",
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
                await _saveMarksData(examType, selectedSubject, obtainedMarks, totalMarks, "");
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }





  Future<void> _saveMarksData(String examType, String subjectCode, String obtainedMarks, String totalMarks, String grade) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty || subjectCode.isEmpty) return;

    final marksRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(_currentSemester);

    if (examType != 'End Semester Exam') {
      await marksRef.set({
        subjectCode: {
          examType: {
            'obtained': int.tryParse(obtainedMarks) ?? 0,
            'total': int.tryParse(totalMarks) ?? 0,
          },
        },
      }, SetOptions(merge: true));
    } else {
      await marksRef.set({
        subjectCode: {
          'endSem': {'grade': grade},
        },
      }, SetOptions(merge: true));
    }

    await _loadSubjectsAndMarks(_currentSemester);
  }

  Future<void> _deleteSubjectMarks(String subjectCode, String examType) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty || subjectCode.isEmpty) return;

    final marksRef = _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('marks')
        .doc(_currentSemester);

    await marksRef.update({
      '$subjectCode.$examType': FieldValue.delete(),
    });

    await _loadSubjectsAndMarks(_currentSemester);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "View/Add Marks",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _currentSemester.isNotEmpty ? _currentSemester : null,
              decoration: InputDecoration(
                labelText: "Select Semester",
                labelStyle: TextStyle(color: Colors.green.shade700),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.shade700),
                ),
              ),
              items: _semesters.map((semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _currentSemester = value ?? "";
                });
                if (_currentSemester.isNotEmpty) {
                  _loadSubjectsAndMarks(_currentSemester);
                }
              },
            ),
            const SizedBox(height: 20),
            _buildMarksCard('CAT1'),
            _buildMarksCard('CAT2'),
            _buildMarksCard('CAT3'),
            _buildEndSemCard(),
          ],
        ),
      ),
    );
  }
}