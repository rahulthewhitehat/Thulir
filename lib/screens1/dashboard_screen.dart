import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_avatar/random_avatar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  Future<double> _fetchOverallAttendance(String userId) async {
    try {
      // Get current semester
      final currentSemesterSnapshot = await FirebaseFirestore.instance
          .collection('user_info')
          .doc(userId)
          .collection('semesters')
          .where('current', isEqualTo: true)
          .limit(1)
          .get();

      if (currentSemesterSnapshot.docs.isNotEmpty) {
        final currentSemester = currentSemesterSnapshot.docs.first.id;

        // Get attendance data
        final attendanceSnapshot = await FirebaseFirestore.instance
            .collection('user_info')
            .doc(userId)
            .collection('attendance')
            .doc(currentSemester)
            .get();

        if (attendanceSnapshot.exists) {
          final attendanceData = attendanceSnapshot.data() ?? {};
          double totalPercentage = 0.0;
          int subjectCount = 0;

          // Calculate attendance percentage for each subject
          attendanceData.forEach((subjectCode, attendanceDetails) {
            int totalSessions = attendanceDetails.length;
            int presentSessions = attendanceDetails.values
                .where((details) =>
            details['status'] == 'present' || details['status'] == 'OD')
                .length;

            if (totalSessions > 0) {
              double subjectAttendance = (presentSessions / totalSessions) * 100;
              totalPercentage += subjectAttendance;
              subjectCount++;
            }
          });

          return subjectCount > 0 ? (totalPercentage / subjectCount) : 0.0;
        }
      }
    } catch (e) {
      print("Error fetching overall attendance: $e");
    }
    return 0.0;
  }

  Future<double> _fetchCurrentCGPA(String userId) async {
    try {
      // Get all semesters
      final semesterSnapshot = await FirebaseFirestore.instance
          .collection('user_info')
          .doc(userId)
          .collection('marks')
          .get();

      if (semesterSnapshot.docs.isEmpty) return 0.0;

      double totalGpa = 0.0;
      int semesterCount = 0;

      // Calculate the average GPA across all semesters
      for (var doc in semesterSnapshot.docs) {
        double? gpa = (doc.data()['gpa'] as double?) ?? 0.0;
        if (gpa > 0) {
          totalGpa += gpa;
          semesterCount++;
        }
      }
      return semesterCount > 0 ? (totalGpa / semesterCount) : 0.0;
    } catch (e) {
      print("Error fetching CGPA: $e");
    }
    return 0.0;
  }

  void _refreshDashboard() {
    setState(() {});
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshDashboard,
          ),
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

          return FutureBuilder<List<double>>(
            future: Future.wait([
              _fetchOverallAttendance(user.uid),
              _fetchCurrentCGPA(user.uid),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final overallAttendance = snapshot.data?[0] ?? 0.0;
              final currentCgpa = snapshot.data?[1] ?? 0.0;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RandomAvatar(userName, height: 60, width: 60),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Welcome, $userName!",
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: "Average Attendance",
                            value: "${overallAttendance.toStringAsFixed(2)}%",
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoCard(
                            title: "Current CGPA",
                            value: currentCgpa.toStringAsFixed(2),
                            icon: Icons.school,
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
                            title: "Visualize Data",
                            icon: Icons.graphic_eq_outlined,
                            onTap: () {
                              Navigator.pushNamed(context, '/visualize');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String value, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
