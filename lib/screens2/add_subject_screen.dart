import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddSubjectScreen extends StatefulWidget {
  final String? semester;

  const AddSubjectScreen({required this.semester, super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _staffController = TextEditingController();
  final _creditsController = TextEditingController(); // Added credits controller
  String? _subjectType;

  final List<String> _subjectTypes = [
    "Theory",
    "Lab",
    "Theory+Lab",
    "Project Based",
    "General"
  ];

  Future<void> _addSubject() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.semester != null) {
      final semesterRef = FirebaseFirestore.instance
          .collection('user_info')
          .doc(user.uid)
          .collection('semesters')
          .doc(widget.semester!.toLowerCase().replaceAll(' ', '_'));

      final newSubject = {
        'subjectName': _subjectNameController.text.trim(),
        'subjectCode': _subjectCodeController.text.trim(),
        'subjectType': _subjectType,
        'credits': int.tryParse(_creditsController.text.trim()), // Parse credits
        'staff': _staffController.text.trim(),
      };

      await semesterRef.set({
        'subjects': FieldValue.arrayUnion([newSubject]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject added successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Subject",
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
                "Add New Subject",
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
                  onPressed: _addSubject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Add Subject",
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

  Widget _buildStyledTextField(TextEditingController controller,
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
