# Thulir - Your College Companion App

**Thulir** is a college companion app designed specifically for students to manage, track, and visualize both academic and non-academic activities effectively. Thulir aims to streamline the complexities of college life by providing one integrated platform to store and access all essential student information.

## Introduction

Thulir, meaning "sprout" in Tamil, signifies growth, much like a student’s journey through college. Our app empowers students to keep track of every aspect of their education, from academic performance and attendance tracking to extracurricular activities and period tracking, in a streamlined and user-friendly manner.

Thulir is a unified platform built using **Flutter** and **Firebase**, providing a feature-rich, secure, and personalized experience for college students.

---

## Features Overview

### 1. **User Profile Management**
   - Secure user authentication for a personalized experience.
   - Add and store personal information like name, contact details, and other relevant data.
   - Update details whenever necessary through a profile management screen.

### 2. **Semester Configuration**
   - Configure the current semester's subjects, timetable, and faculty.
   - Add subject details like subject code, name, and type (Theory, Lab, Theory+Lab).
   - Manage semester-wise data easily in one place.

### 3. **Attendance Tracking**
   - Track attendance for each subject in real-time.
   - Mark daily attendance for individual subjects, with options like Present, Absent, and On-Duty (OD).
   - View subject-wise attendance percentages and visualize overall attendance trends.
   - Alerts to warn students if attendance drops below a critical percentage (e.g., below 75%).

### 4. **Assignment Management**
   - Add, edit, and view assignments for the current semester.
   - Include assignment details like subject code, type (WrittenWork, SystemWork, etc.), submission type (GCR, Hardcopy, etc.), and deadlines.
   - Set reminders for upcoming assignment deadlines.
   - View assignment status and mark assignments as completed.

### 5. **Timetable Management**
   - View and edit your semester timetable with subject names and timings.
   - Configure both regular class schedules and exam timetables.

### 6. **Event Management**
   - Track and manage events like hackathons, symposiums, inter-college competitions, and club activities.
   - Add event details such as event name, college name, event date, registration deadline, and links for event registration.
   - Rate events based on importance to help prioritize participation.

### 7. **Exam and Grade Tracking**
   - View and manage marks for CAT exams (CAT1, CAT2, CAT3) and End Semester Exams.
   - Track GPA for each semester and view cumulative CGPA.
   - Visualize GPA progression over time with graphs to assess academic growth.

### 8. **Visualizations and Data Insights**
   - **Overall Attendance Progress**: Line chart showing attendance percentages for each subject over time.
   - **Subject-wise Attendance Percentage**: Pie chart visualizing the attendance distribution across subjects.
   - **GPA Progression**: Line chart showing the progression of GPA across semesters to visualize performance trends.
   - **Period Tracking (Female students only)**: Predict the date of the next cycle based on past data and visualize period history.

### 9. **Period Tracking (Female Users)**
   - Track menstrual cycles, including start and end dates.
   - Predict the next period based on average cycle length.
   - Record symptoms experienced during the cycle and visualize the average cycle trend.
   - Privacy-focused: this feature is only visible to female users.

### 10. **Dashboard and Visualization**
   - Overview of attendance percentage, CGPA, and other key metrics.
   - Quick access to important features like attendance, assignments, events, etc.
   - Visualize academic data to assess strengths, identify areas for improvement, and optimize performance.

### 11. **Settings and Customization**
   - Edit profile information, including contact and academic details.
   - Toggle notification preferences.
   - A settings screen for logout, about, and access to personalization options.
   - "About" section for more information about the app and developer.

---

## Technical Stack

- **Frontend**: Flutter for creating cross-platform user interfaces.
- **Backend**: Firebase Firestore for data storage, Firebase Authentication for user login and management.
- **Data Visualizations**: Syncfusion Charts to create graphs and data visualizations.
- **State Management**: State is managed using `Stateful Widgets` and `setState` for dynamic content updates.

---

## Firebase Configuration

To use Thulir's backend features, you need to set up **Firebase**:

1. **Create a Project**: Start by creating a new project in the [Firebase Console](https://console.firebase.google.com/).
2. **Configure Firebase**:
   - **Android**: Download and add the `google-services.json` file to the Android project directory.
   - **iOS**: Download and add the `GoogleService-Info.plist` file to the iOS project directory.
   - Follow the Firebase setup guide to integrate Firebase SDK into your Flutter project.
3. **Add Firestore and Authentication**:
   - Enable **Firestore** for storing app data.
   - Enable **Firebase Authentication** for managing user sign-up, login, and account security.

---

## Usage

### Example Screens

Below are some example screenshots of the **Thulir** app, giving you an idea of the user interface and functionality:

1. **Dashboard Screen**  
   ![Dashboard Screenshot](https://example.com/dashboard-screenshot.png)

2. **Attendance Tracking**  
   ![Attendance Screenshot](https://example.com/attendance-screenshot.png)

3. **Assignment Management**  
   ![Assignment Screenshot](https://example.com/assignment-screenshot.png)

4. **Event Management**  
   ![Event Screenshot](https://example.com/event-screenshot.png)

5. **Timetable Management**  
   ![Timetable Screenshot](https://example.com/timetable-screenshot.png)

6. **Period Tracking**  
   ![Period Tracking Screenshot](https://example.com/period-tracking-screenshot.png)

7. **GPA Progression Visualization**  
   ![GPA Progression Screenshot](https://example.com/gpa-progression-screenshot.png)

8. **Subject-wise Attendance Pie Chart**  
   ![Attendance Pie Chart Screenshot](https://example.com/attendance-pie-chart.png)

9. **Add Assignment Dialog**  
   ![Add Assignment Dialog Screenshot](https://example.com/add-assignment-dialog-screenshot.png)

10. **Settings Screen**  
    ![Settings Screenshot](https://example.com/settings-screenshot.png)

---

## Key Goals of Thulir

1. **Centralized Platform**: Provide a one-stop solution for students to manage academics and extracurricular activities efficiently.
2. **Data Privacy**: Securely manage user data, ensuring that sensitive information like period tracking is visible only to authorized users.
3. **Personalized User Experience**: Tailored content and visualizations help each student optimize their academic and non-academic performance.
4. **Accessible Anywhere**: Built cross-platform using Flutter, ensuring seamless usage on both Android and iOS devices.

---

## Upcoming Features

1. **Group Projects & Collaboration**: Features that enable students to collaborate on group projects with peers.
2. **Chat Functionality**: Integrated chat feature to facilitate communication between students.
3. **Document Upload**: Ability to securely upload and store important academic documents, such as certificates.
4. **Reminders & Notifications**: Google Calendar integration for reminders about assignments, exams, and events.

---

## Contributing

**Thulir** is an open-source project, and contributions are always welcome to enhance and expand its features. If you’d like to contribute:

1. **Fork the Repository**: Click on the "Fork" button at the top of this page.
2. **Create a Branch**: Create a branch specific to the contribution you intend to make.
3. **Make Changes**: Implement your changes or improvements in the new branch.
4. **Create a Pull Request**: Submit your changes for review by creating a pull request.

> Please make sure to follow the project's guidelines and maintain consistency across the app when contributing.

---

## License

**Thulir** is licensed under the [MIT License](https://choosealicense.com/licenses/mit/). Feel free to use and modify it to fit your needs.

---

## Contact & Support

For more information or support, please reach out via:

- **Email**: [rahulbabuoffl@gmail.com](mailto:rahulbabuoffl@gmail.com)
- **Website**: [Thulir Official Website]
- **GitHub Repository**: [GitHub](https://github.com/rahulthewhitehat/thulir)

We believe that **Thulir** can make a significant impact on a student's academic journey, enabling them to focus on what matters most—**learning and growing**.

**Thulir - A Companion for College Students** 🌱


