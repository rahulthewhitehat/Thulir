import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  final String appDescription =
      'Thulir App\n\nVersion 1.0.0\n\nThulir is an all-in-one academic and non-academic companion app for college students. It provides a seamless platform to track attendance, assignments, exams, and events, while also allowing students to view their GPA progression and other relevant details. '
      'Built with Flutter and Firebase, Thulir addresses the needs of college students to stay organized and informed in one convenient app.';

  final String developerDescription =
      'I am a Computer Science and Business Systems student at REC, Chennai, with a deep passion for technology and aspirations to become an ethical hacker. '
      'I have continuously challenged myself in cybersecurity, networking, and programming, reflecting my dedication in multiple achievements and certifications. '
      'As an avid learner and a committed cybersecurity enthusiast, I aim to make a meaningful impact in the technology world.';

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // About App
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About Thulir',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appDescription,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              ),
            ),
            const SizedBox(height: 30),

            // About Developer Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About the Developer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Developer Profile Photo
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/dev.jpg'), // Adjust path
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 15),

            // Developer Name
            Text(
              'Rahul Babu M P',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // About Developer
            Text(
              developerDescription,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Contact Information
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Contact Details with Icons
            Row(
              children: [
                const Icon(Icons.email, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  'rahulbabuoffl@gmail.com',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 10),
                Text(
                  '+91 9514803391',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.web, color: Colors.green),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _launchURL('https://rahulthewhitehat.github.io'),
                  child: Text(
                    'rahulthewhitehat.github.io',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.web, color: Colors.green),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _launchURL('https://linktr.ee/rahulthewhitehat'),
                  child: Text(
                    'linktr.ee/rahulthewhitehat',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
