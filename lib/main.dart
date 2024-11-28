import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thulir/screens1/dashboard_screen.dart';
import 'package:thulir/screens1/user_details_screen.dart';
import 'package:thulir/screens2/add_subject_screen.dart';
import 'package:thulir/screens2/attendance_screen.dart';
import 'package:thulir/screens2/configure_semester_screen.dart';
import 'package:thulir/screens2/marks_details_screen.dart';
import 'package:thulir/screens2/profile_view_edit_screen.dart';
import 'package:thulir/screens3/about_screen.dart';
import 'package:thulir/screens3/assignment_tracking_screen.dart';
import 'package:thulir/screens3/event_management_screen.dart';
import 'package:thulir/screens3/period_tracking_screen.dart';
import 'package:thulir/screens3/time_table_screen.dart';
import 'package:thulir/screens3/visualisation_screen.dart';
import 'screens1/login_screen.dart';
import 'screens1/signup_screen.dart';
import 'screens1/splash_screen.dart';
import 'screens1/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const ThulirApp());
}

class ThulirApp extends StatelessWidget {
  const ThulirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thulir',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/splashScreen',
      routes: {
        '/splashScreen': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/userDetails': (context) => const UserDetailsScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/viewEditProfile': (context) => const ViewEditProfileScreen(),
        '/configureSemester': (context) => const ConfigureSemesterScreen(),
        '/addSubject': (context) => const AddSubjectScreen(
        semester: 'placeholder', // Replace dynamically in MaterialPageRoute
    ),
        '/attendance': (context) => const AttendanceScreen(),
        '/examGrades': (context) => const MarksScreen(),
        '/timetable': (context) => const TimetableScreen(),
        '/assignments': (context) => const AssignmentTrackingScreen(),
        '/events': (context) => const EventManagementScreen(),
        '/visualize': (context) => const VisualizationScreen(),
        '/about': (context) => AboutScreen(),
        '/periodTracking': (context) => const PeriodTrackingScreen(),

      },
    );
  }
}
