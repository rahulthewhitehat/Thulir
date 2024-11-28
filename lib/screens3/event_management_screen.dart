import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final eventsSnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('events')
        .get();

    setState(() {
      _events = eventsSnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();
      _isLoading = false;
    });
  }

  void _showAddOrEditEventDialog({Map<String, dynamic>? existingEvent}) {
    String eventName = existingEvent?['eventName'] ?? "";
    String eventCollege = existingEvent?['eventCollege'] ?? "";
    DateTime? eventDate = existingEvent != null
        ? (existingEvent['eventDate'] as Timestamp).toDate()
        : null;
    DateTime? registrationDeadline = existingEvent != null
        ? (existingEvent['registrationDeadline'] as Timestamp).toDate()
        : null;
    String importance = existingEvent?['importance']?.toString() ?? "1";
    String eventLink1 = existingEvent?['eventLink1'] ?? "";
    String eventLink2 = existingEvent?['eventLink2'] ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existingEvent == null ? "Add Event" : "Edit Event",
                style: TextStyle(color: Colors.green.shade700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: TextEditingController(text: eventName),
                      decoration: InputDecoration(
                        labelText: "Event Name",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        eventName = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: eventCollege),
                      decoration: InputDecoration(
                        labelText: "Event College",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        eventCollege = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        eventDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        setState(() {});
                      },
                      child: Text(
                        eventDate == null
                            ? "Select Event Date"
                            : "Event Date: ${DateFormat('dd/MM/yyyy').format(eventDate!)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        registrationDeadline = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        setState(() {});
                      },
                      child: Text(
                        registrationDeadline == null
                            ? "Select Registration Deadline"
                            : "Registration Deadline: ${DateFormat('dd/MM/yyyy').format(registrationDeadline!)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: importance,
                      decoration: InputDecoration(
                        labelText: "Importance (1 to 5)",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      items: ['1', '2', '3', '4', '5']
                          .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ))
                          .toList(),
                      onChanged: (value) {
                        importance = value ?? "1";
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: eventLink1),
                      decoration: InputDecoration(
                        labelText: "Event Link 1 (Optional)",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        eventLink1 = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: eventLink2),
                      decoration: InputDecoration(
                        labelText: "Event Link 2 (Optional)",
                        labelStyle: TextStyle(color: Colors.green.shade700),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        eventLink2 = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (eventName.isNotEmpty &&
                        eventCollege.isNotEmpty &&
                        eventDate != null &&
                        registrationDeadline != null) {
                      await _addOrUpdateEvent(
                          existingEvent?['id'],
                          eventName,
                          eventCollege,
                          eventDate!,
                          registrationDeadline!,
                          int.parse(importance),
                          eventLink1,
                          eventLink2);
                      Navigator.pop(context);
                      await _loadEvents();
                    }
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

  Future<void> _addOrUpdateEvent(
      String? eventId,
      String eventName,
      String eventCollege,
      DateTime eventDate,
      DateTime registrationDeadline,
      int importance,
      String eventLink1,
      String eventLink2,
      ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      'eventName': eventName,
      'eventCollege': eventCollege,
      'eventDate': eventDate,
      'registrationDeadline': registrationDeadline,
      'importance': importance,
      'eventLink1': eventLink1,
      'eventLink2': eventLink2,
    };

    final eventsRef = _firestore.collection('user_info').doc(user.uid).collection('events');
    if (eventId != null) {
      await eventsRef.doc(eventId).update(data);
    } else {
      await eventsRef.add(data);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('events')
        .doc(eventId)
        .delete();

    await _loadEvents();
  }

  Widget _buildEventCard(Map<String, dynamic> event, int index) {
    final eventDate = (event['eventDate'] as Timestamp).toDate();
    final registrationDeadline = (event['registrationDeadline'] as Timestamp).toDate();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${index + 1}. ${event['eventName']} - ${event['eventCollege']}",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Text(
              "Event Date: ${DateFormat('dd/MM/yyyy').format(eventDate)}",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              "Registration Deadline: ${DateFormat('dd/MM/yyyy').format(registrationDeadline)}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Importance: ${event['importance']}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            if (event['eventLink1'].isNotEmpty)
              Text(
                "Event Link 1: ${event['eventLink1']}",
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            if (event['eventLink2'].isNotEmpty)
              Text(
                "Event Link 2: ${event['eventLink2']}",
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showAddOrEditEventDialog(existingEvent: event),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _deleteEvent(event['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Event Management",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: _showAddOrEditEventDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: _events.isEmpty
            ? const Center(child: Text("No events added."))
            : ListView.builder(
          itemCount: _events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(_events[index], index);
          },
        ),
      ),
    );
  }
}
