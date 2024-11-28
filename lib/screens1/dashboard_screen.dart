import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_avatar/random_avatar.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  Future<String?> _fetchUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('user_info').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['name'];
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications feature coming soon!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _fetchUserName(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userName = snapshot.data ?? "User";

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RandomAvatar(userName, height: 60, width: 60),
                    const SizedBox(width: 16),
                    Text(
                      "Welcome, $userName!",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardButton(
                        context,
                        title: "Configure Semester",
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.pushNamed(context, '/configureSemester');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "Attendance Tracking",
                        icon: Icons.check_circle,
                        onTap: () {
                          Navigator.pushNamed(context, '/attendance');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "Assignment Tracking",
                        icon: Icons.assignment,
                        onTap: () {
                          Navigator.pushNamed(context, '/assignments');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "View Timetable",
                        icon: Icons.schedule,
                        onTap: () {
                          Navigator.pushNamed(context, '/timetable');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "Event Management",
                        icon: Icons.event,
                        onTap: () {
                          Navigator.pushNamed(context, '/events');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "View Marks/Grades",
                        icon: Icons.school,
                        onTap: () {
                          Navigator.pushNamed(context, '/examGrades');
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: "Certifications/Documents",
                        icon: Icons.folder,
                        onTap: () {
                          Navigator.pushNamed(context, '/certifications');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardButton(
      BuildContext context, {
        required String title,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green.shade700),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
