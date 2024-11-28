import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditSubjectScreen extends StatefulWidget {
  final String semester;
  final Map<String, dynamic> subjectData;

  const EditSubjectScreen({
    required this.semester,
    required this.subjectData,
    super.key,
  });

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _staffController = TextEditingController();
  final _creditsController = TextEditingController(); // Added for credits
  String? _subjectType;

  final List<String> _subjectTypes = ["Theory", "Lab", "Theory+Lab", "Project Based", "General"];

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
  }

  void _loadSubjectData() {
    _subjectNameController.text = widget.subjectData['subjectName'];
    _subjectCodeController.text = widget.subjectData['subjectCode'];
    _staffController.text = widget.subjectData['staff'];
    _subjectType = widget.subjectData['subjectType'];
    _creditsController.text = widget.subjectData['credits']?.toString() ?? ''; // Convert to String
  }

  Future<void> _updateSubject() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final semesterRef = FirebaseFirestore.instance
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .doc(widget.semester);

      final semesterDoc = await semesterRef.get();
      if (semesterDoc.exists) {
        final subjects = List<Map<String, dynamic>>.from(semesterDoc.data()!['subjects']);
        final index = subjects.indexWhere((subject) => subject['subjectCode'] == widget.subjectData['subjectCode']);
        if (index != -1) {
          subjects[index] = {
            'subjectName': _subjectNameController.text.trim(),
            'subjectCode': _subjectCodeController.text.trim(),
            'subjectType': _subjectType,
            'credits': int.tryParse(_creditsController.text.trim()), // Parse back to integer
            'staff': _staffController.text.trim(),
          };
          await semesterRef.update({'subjects': subjects});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subject updated successfully!")),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Subject",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Subject Details",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 10),
              _buildStyledTextField(_subjectNameController, "Subject Name"),
              const SizedBox(height: 15),
              _buildStyledTextField(_subjectCodeController, "Subject Code"),
              const SizedBox(height: 15),
              _buildDropdownField(
                label: "Subject Type",
                items: _subjectTypes,
                value: _subjectType,
                onChanged: (value) => setState(() => _subjectType = value),
              ),
              const SizedBox(height: 15),
              _buildStyledTextField(
                _creditsController,
                "Credits",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              _buildStyledTextField(_staffController, "Staff Name"),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _updateSubject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Update Subject",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
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
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
