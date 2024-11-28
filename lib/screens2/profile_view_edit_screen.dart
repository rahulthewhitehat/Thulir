import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewEditProfileScreen extends StatefulWidget {
  const ViewEditProfileScreen({super.key});

  @override
  State<ViewEditProfileScreen> createState() => _ViewEditProfileScreenState();
}

class _ViewEditProfileScreenState extends State<ViewEditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _websiteController = TextEditingController();
  String? _selectedGender;
  String? _selectedDegree;
  String? _selectedDuration;
  String? _selectedYear;
  bool _isLoading = true;

  final List<String> _genders = ["Male", "Female", "Other"];
  final List<String> _degrees = ["B. Tech/B.E.", "B.Sc/B.A.", "Others"];
  final List<String> _durations = ["1 Year", "2 Years", "3 Years", "4 Years"];
  final List<String> _years = ["1st Year", "2nd Year", "3rd Year", "4th Year"];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
      await FirebaseFirestore.instance.collection('user_info')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _linkedinController.text = data['linkedin'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _selectedGender = data['gender'];
          _selectedDegree = data['degree'];
          _selectedDuration = data['duration'];
          _selectedYear = data['currentYear'];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('user_info')
            .doc(user.uid)
            .update({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
          'website': _websiteController.text.trim(),
          'gender': _selectedGender,
          'degree': _selectedDegree,
          'duration': _selectedDuration,
          'currentYear': _selectedYear,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'View/Edit Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.person, size: 50, color: Colors.green),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Personal Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildStyledTextField(_nameController, "Full Name"),
            const SizedBox(height: 15),
            _buildStyledDropdownField(
              "Gender",
              _genders,
              _selectedGender,
                  (value) => setState(() => _selectedGender = value),
            ),
            const SizedBox(height: 20),
            Text(
              "Professional Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildStyledTextField(_bioController, "Bio"),
            const SizedBox(height: 15),
            _buildStyledTextField(_linkedinController, "LinkedIn Profile"),
            const SizedBox(height: 15),
            _buildStyledTextField(_websiteController, "Website"),
            const SizedBox(height: 20),
            Text(
              "Educational Details",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 10),
            _buildStyledDropdownField(
              "Degree",
              _degrees,
              _selectedDegree,
                  (value) => setState(() => _selectedDegree = value),
            ),
            const SizedBox(height: 15),
            _buildStyledDropdownField(
              "Duration",
              _durations,
              _selectedDuration,
                  (value) => setState(() => _selectedDuration = value),
            ),
            const SizedBox(height: 15),
            _buildStyledDropdownField(
              "Current Year",
              _years,
              _selectedYear,
                  (value) => setState(() => _selectedYear = value),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 15),
                ),
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label) {
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
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.green.shade700),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStyledDropdownField(String label,
      List<String> items,
      String? value,
      ValueChanged<String?> onChanged,) {
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
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 15, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}