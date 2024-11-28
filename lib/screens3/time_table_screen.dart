import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _currentSemester = "";
  List<Map<String, dynamic>> _classSchedule = [];
  List<Map<String, dynamic>> _examSchedule = [];
  List<Map<String, dynamic>> _subjects = [];
  List<String> _classroomNumbers = [];
  bool _isLoading = true;
  String _currentDay = "";

  // Variables to store form data
  String _selectedClassDay = "";
  String _selectedClassSubject = "";
  String _classroom = "";
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _selectedExamSubject = "";
  DateTime? _selectedExamDate;
  String _selectedExamDay = "";
  String _examSession = "";
  String _examType = "";

  @override
  void initState() {
    super.initState();
    _fetchCurrentSemester();
  }

  Future<void> _fetchCurrentSemester() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

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

    _currentDay = DateFormat('EEEE').format(DateTime.now());
    await _loadSubjects();
    await _loadTimetables();
    await _loadClassroomNumbers();
  }

  Future<void> _loadSubjects() async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    final semesterDoc = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('semesters')
        .doc(_currentSemester)
        .get();

    setState(() {
      _subjects = List<Map<String, dynamic>>.from(semesterDoc.data()?['subjects'] ?? []);
    });
  }

  Future<void> _loadTimetables() async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    final classScheduleSnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('class_schedule')
        .collection(_currentSemester)
        .get();

    final examScheduleSnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('exam_schedule')
        .collection(_currentSemester)
        .get();

    setState(() {
      _classSchedule = classScheduleSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      _examSchedule = examScheduleSnapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      _isLoading = false;
    });
  }


  DateTime _extractTimeComponents(String timeString) {
    final startTimeString = timeString.split(' - ')[0];
    final format = DateFormat.jm(); // Format for parsing "9:50 AM", "10:50 AM", etc.

    try {
      return format.parse(startTimeString);
    } catch (e) {
      // If there's an error while parsing, return a default value.
      return DateTime(0);
    }
  }



  Future<void> _loadClassroomNumbers() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final classroomSnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('classroom_numbers')
        .get();

    setState(() {
      _classroomNumbers = List<String>.from(classroomSnapshot.data()?['rooms'] ?? []);
    });
  }

  Future<void> _addClassSchedule() async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    if (_selectedClassDay.isEmpty ||
        _selectedClassSubject.isEmpty ||
        _classroom.isEmpty ||
        _startTime == null ||
        _endTime == null) {
      // Show error or validation message
      return;
    }

    final subject = _subjects.firstWhere(
          (sub) => sub['subjectCode'] == _selectedClassSubject,
      orElse: () => {'subjectName': 'Unknown', 'subjectType': '', 'staff': 'Unknown'},
    );

    final time = "${_startTime!.format(context)} - ${_endTime!.format(context)}";

    final data = {
      'day': _selectedClassDay,
      'subjectCode': _selectedClassSubject,
      'subjectName': subject['subjectName'],
      'classType': subject['subjectType'],
      'subStaff': subject['staff'],
      'classroomNo': _classroom,
      'time': time,
    };

    // Create a document ID based on the day and the start time for natural sorting
    final documentId = "${_selectedClassDay}_${_startTime!.hour.toString().padLeft(2, '0')}_${_startTime!.minute.toString().padLeft(2, '0')}";

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('class_schedule')
        .collection(_currentSemester)
        .doc(documentId)  // Use the formatted ID based on start time
        .set(data);

    // Update startTime to endTime for the next subject
    _startTime = _endTime;
    _endTime = null;
    _selectedClassSubject = "";
    _classroom = "";

    await _loadTimetables();
  }


  Future<void> _addExamSchedule() async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    if (_selectedExamSubject.isEmpty ||
        _selectedExamDate == null ||
        _selectedExamDay.isEmpty ||
        _examSession.isEmpty ||
        _examType.isEmpty) {
      // Show error or validation message
      return;
    }

    final subject = _subjects.firstWhere(
          (sub) => sub['subjectCode'] == _selectedExamSubject,
      orElse: () => {'subjectName': 'Unknown'},
    );

    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedExamDate!);

    final data = {
      'examType': _examType,
      'subjectCode': _selectedExamSubject,
      'subjectName': subject['subjectName'],
      'date': dateStr,
      'day': _selectedExamDay,
      'session': _examSession,
    };

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('exam_schedule')
        .collection(_currentSemester)
        .add(data);

    _selectedExamSubject = "";
    _selectedExamDate = null;
    _selectedExamDay = "";
    _examSession = "";
    _examType = "";

    await _loadTimetables();
  }

  Future<void> _addClassroomNumber() async {
    final user = _auth.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        String newRoomNumber = "";
        return AlertDialog(
          title: Text(
            "Add Classroom Number",
            style: TextStyle(color: Colors.green.shade700),
          ),
          content: TextField(
            decoration: _inputDecoration("Classroom Number"),
            onChanged: (value) {
              newRoomNumber = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (newRoomNumber.isNotEmpty) {
                  if (!_classroomNumbers.contains(newRoomNumber)) {
                    _classroomNumbers.add(newRoomNumber);
                    await _firestore
                        .collection('user_info')
                        .doc(user.uid)
                        .collection('timetables')
                        .doc('classroom_numbers')
                        .set({'rooms': _classroomNumbers});
                  }
                }
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showAddTimetableDialog(String type) {
    // Reset form data if required
    if (type == 'exam') {
      _selectedExamSubject = "";
      _selectedExamDate = null;
      _selectedExamDay = "";
      _examSession = "";
      _examType = "";
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                type == 'class' ? 'Add Class Schedule' : 'Add Exam Schedule',
                style: TextStyle(color: Colors.green.shade700),
              ),
              content: SingleChildScrollView(
                child: type == 'class'
                    ? _buildClassScheduleForm(setState)
                    : _buildExamScheduleForm(setState),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (type == 'class') {
                      await _addClassSchedule();
                    } else {
                      await _addExamSchedule();
                    }
                    setState(() {});
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

  Widget _buildClassScheduleForm(void Function(void Function()) setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedClassDay.isNotEmpty ? _selectedClassDay : null,
          decoration: _inputDecoration("Select Day"),
          items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
              .map((day) => DropdownMenuItem(
            value: day,
            child: Text(day),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassDay = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedClassSubject.isNotEmpty ? _selectedClassSubject : null,
          decoration: _inputDecoration("Select Subject"),
          items: _subjects.map((subject) {
            return DropdownMenuItem<String>(
              value: subject['subjectCode'],
              child: Text(subject['subjectCode']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassSubject = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _classroom.isNotEmpty ? _classroom : null,
          decoration: _inputDecoration("Select Classroom Number"),
          items: _classroomNumbers.map((room) {
            return DropdownMenuItem<String>(
              value: room,
              child: Text(room),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _classroom = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  _startTime = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  setState(() {});
                },
                child: Text(
                  _startTime == null
                      ? "Start Time"
                      : "Start: ${_startTime!.format(context)}",
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  _endTime = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  setState(() {});
                },
                child: Text(
                  _endTime == null
                      ? "End Time"
                      : "End: ${_endTime!.format(context)}",
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [40, 50, 60, 80].map((duration) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_startTime != null) {
                      final now = DateTime.now();
                      final startDateTime = DateTime(
                          now.year, now.month, now.day,
                          _startTime!.hour, _startTime!.minute);
                      final endDateTime = startDateTime.add(Duration(minutes: duration));
                      _endTime = TimeOfDay.fromDateTime(endDateTime);
                      setState(() {});
                    }
                  },
                  child: Text("$duration min"),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }



  Widget _buildExamScheduleForm(void Function(void Function()) setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _examType.isNotEmpty ? _examType : null,
          decoration: _inputDecoration("Select Exam Type"),
          items: ['CAT1', 'CAT2', 'CAT3', 'End Sem']
              .map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _examType = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedExamSubject.isNotEmpty ? _selectedExamSubject : null,
          decoration: _inputDecoration("Select Subject"),
          items: _subjects.map((subject) {
            return DropdownMenuItem<String>(
              value: subject['subjectCode'],
              child: Text(subject['subjectCode']),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedExamSubject = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            _selectedExamDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            setState(() {});
          },
          child: Text(
            _selectedExamDate == null
                ? "Select Exam Date"
                : "Date: ${DateFormat('dd/MM/yyyy').format(_selectedExamDate!)}",
            style: TextStyle(color: Colors.green.shade700),
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedExamDay.isNotEmpty ? _selectedExamDay : null,
          decoration: _inputDecoration("Select Day"),
          items: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
              .map((day) => DropdownMenuItem(
            value: day,
            child: Text(day),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedExamDay = value ?? "";
            });
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _examSession.isNotEmpty ? _examSession : null,
          decoration: _inputDecoration("Select Session"),
          items: ['FN', 'AN']
              .map((s) => DropdownMenuItem(
            value: s,
            child: Text(s),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _examSession = value ?? "";
            });
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.green.shade700),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green.shade700),
      ),
    );
  }

  Widget _buildClassScheduleList() {
    // Filter today's class schedules
    final todaySchedules = _classSchedule.where((entry) {
      return entry['day'] == _currentDay;
    }).toList();

    return todaySchedules.isEmpty
        ? const Text("No classes scheduled for today.")
        : Column(
      children: todaySchedules.map((entry) {
        final times = entry['time'].split(' - ');
        final startTime = times[0];
        final endTime = times[1];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$startTime - $endTime - ${entry['subjectCode']}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  entry['subjectName'],
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text(
                  "Type: ${entry['classType']}",
                  style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Staff: ${entry['subStaff']}",
                  style: const TextStyle(fontSize: 14, color: Colors.purple, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  "Room: ${entry['classroomNo']}",
                  style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editClassSchedule(entry['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteClassSchedule(entry['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExamScheduleList() {
    if (_examSchedule.isEmpty) {
      return const Text("No exam schedules available.");
    }

    _examSchedule.sort((a, b) {
      final dateA = DateFormat('dd/MM/yyyy').parse(a['date']);
      final dateB = DateFormat('dd/MM/yyyy').parse(b['date']);
      return dateA.compareTo(dateB);
    });

    final examGroups = _groupExamByType(_examSchedule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: examGroups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ExamType: ${entry.key}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            Column(
              children: entry.value.asMap().entries.map((examEntry) {
                final index = examEntry.key + 1;
                final exam = examEntry.value;
                return Card(
                  child: ListTile(
                    title: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                            "$index. ${exam['date']} ${exam['day']} ${exam['subjectCode']} ",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 14),
                          ),
                          TextSpan(
                            text: "${exam['subjectName']} ",
                            style: const TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: exam['session'],
                            style: const TextStyle(
                                color: Colors.purple,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editExamSchedule(exam['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteExamSchedule(exam['id']),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupExamByType(
      List<Map<String, dynamic>> exams) {
    final Map<String, List<Map<String, dynamic>>> groupedExams = {};
    for (final exam in exams) {
      final examType = exam['examType'];
      if (!groupedExams.containsKey(examType)) {
        groupedExams[examType] = [];
      }
      groupedExams[examType]!.add(exam);
    }
    return groupedExams;
  }

  Future<void> _editClassSchedule(String scheduleId) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    final doc = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('class_schedule')
        .collection(_currentSemester)
        .doc(scheduleId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _selectedClassDay = data['day'];
      _selectedClassSubject = data['subjectCode'];
      _classroom = data['classroomNo'];
      final times = data['time'].split(' - ');
      _startTime = _parseTime(times[0]);
      _endTime = _parseTime(times[1]);

      _showAddTimetableDialog('class');
    }
  }


  Future<void> _deleteClassSchedule(String scheduleId) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('class_schedule')
        .collection(_currentSemester)
        .doc(scheduleId)
        .delete();

    await _loadTimetables();
  }

  Future<void> _editExamSchedule(String scheduleId) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    final doc = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('exam_schedule')
        .collection(_currentSemester)
        .doc(scheduleId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _selectedExamSubject = data['subjectCode'];
      _examType = data['examType'];
      _selectedExamDate = DateFormat('dd/MM/yyyy').parse(data['date']);
      _selectedExamDay = data['day'];
      _examSession = data['session'];

      _showAddTimetableDialog('exam');
    }
  }

  Future<void> _deleteExamSchedule(String scheduleId) async {
    final user = _auth.currentUser;
    if (user == null || _currentSemester.isEmpty) return;

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('timetables')
        .doc('exam_schedule')
        .collection(_currentSemester)
        .doc(scheduleId)
        .delete();

    await _loadTimetables();
  }

  TimeOfDay _parseTime(String timeStr) {
    final format = DateFormat.jm();
    try {
      final parsedDate = format.parse(timeStr);
      return TimeOfDay.fromDateTime(parsedDate);
    } catch (e) {
      return TimeOfDay(hour: 0, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Timetable",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'class') {
                _showAddTimetableDialog('class');
              } else if (value == 'exam') {
                _showAddTimetableDialog('exam');
              } else if (value == 'room') {
                _addClassroomNumber();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'class',
                child: Text('Add Class Schedule'),
              ),
              const PopupMenuItem(
                value: 'exam',
                child: Text('Add Exam Schedule'),
              ),
              const PopupMenuItem(
                value: 'room',
                child: Text('Add Room Numbers'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Today's Classes (${_currentDay})",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildClassScheduleList(),
            const SizedBox(height: 20),
            Text(
              "Exam Schedule",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildExamScheduleList(),
          ],
        ),
      ),
    );
  }
  DateTime _timeOfDayToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

}
