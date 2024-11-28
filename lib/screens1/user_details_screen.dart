import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedDegree;
  String? _selectedDuration;
  String? _selectedYear;

  final List<String> _genders = ["Male", "Female", "Other"];
  final List<String> _degrees = ["B. Tech/B.E.", "B.Sc/B.A.", "Others"];
  final List<String> _durations = ["1 Year", "2 Years", "3 Years", "4 Years"];
  final List<String> _years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile", style: TextStyle(color:Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(_nameController, "Full Name"),
            const SizedBox(height: 15),
            _buildDropdownField(
              title: "Gender",
              items: _genders,
              value: _selectedGender,
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 15),
            _buildDatePickerField(
              title: "Date of Birth",
              selectedDate: _selectedDob,
              onSelectDate: (date) => setState(() => _selectedDob = date),
            ),
            const SizedBox(height: 15),
            _buildTextField(_bioController, "Bio", maxLines: 3),
            const SizedBox(height: 15),
            _buildTextField(_linkedinController, "LinkedIn Profile (Optional)"),
            const SizedBox(height: 15),
            _buildTextField(_websiteController, "Website (Optional)"),
            const SizedBox(height: 15),
            _buildDropdownField(
              title: "Degree",
              items: _degrees,
              value: _selectedDegree,
              onChanged: (value) => setState(() => _selectedDegree = value),
            ),
            const SizedBox(height: 15),
            _buildDropdownField(
              title: "Degree Duration",
              items: _durations,
              value: _selectedDuration,
              onChanged: (value) => setState(() => _selectedDuration = value),
            ),
            const SizedBox(height: 15),
            _buildDropdownField(
              title: "Current Year of Study",
              items: _years,
              value: _selectedYear,
              onChanged: (value) => setState(() => _selectedYear = value),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                ),
                child: const Text("Save Details", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green.shade700),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String title,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.green.shade700)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String title,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onSelectDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          onSelectDate(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        child: Text(
          selectedDate == null
              ? "Select Date"
              : "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _saveDetails() async {
    if (_nameController.text.isEmpty || _selectedGender == null || _selectedDegree == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('user_info').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'gender': _selectedGender,
          'dob': _selectedDob != null
              ? "${_selectedDob!.day}-${_selectedDob!.month}-${_selectedDob!.year}"
              : null,
          'bio': _bioController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
          'website': _websiteController.text.trim(),
          'degree': _selectedDegree,
          'duration': _selectedDuration,
          'currentYear': _selectedYear,
          'email': user.email,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details saved successfully!")),
        );

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving details: $e")),
      );
    }
  }
}
