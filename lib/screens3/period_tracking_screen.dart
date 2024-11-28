import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PeriodTrackingScreen extends StatefulWidget {
  const PeriodTrackingScreen({super.key});

  @override
  State<PeriodTrackingScreen> createState() => _PeriodTrackingScreenState();
}

class _PeriodTrackingScreenState extends State<PeriodTrackingScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _periodHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPeriodHistory();
  }

  Future<void> _loadPeriodHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    final periodHistorySnapshot = await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('period_history')
        .orderBy('startDate', descending: false) // Order in ascending order
        .get();

    setState(() {
      _periodHistory = periodHistorySnapshot.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _addPeriodEntry(DateTime startDate, DateTime endDate, List<String> symptoms) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final data = {
      'startDate': startDate,
      'endDate': endDate,
      'symptoms': symptoms,
    };

    await _firestore
        .collection('user_info')
        .doc(user.uid)
        .collection('period_history')
        .add(data);

    _loadPeriodHistory();
  }

  void _showAddPeriodDialog() {
    DateTime? startDate;
    DateTime? endDate;
    List<String> selectedSymptoms = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Add Period Entry",
                style: TextStyle(color: Colors.green.shade700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        startDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        setState(() {});
                      },
                      child: Text(
                        startDate == null
                            ? "Select Start Date"
                            : "Start Date: ${DateFormat('dd/MM/yyyy').format(startDate!)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        endDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        setState(() {});
                      },
                      child: Text(
                        endDate == null
                            ? "Select End Date"
                            : "End Date: ${DateFormat('dd/MM/yyyy').format(endDate!)}",
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Select Symptoms:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: [
                        _buildSymptomChip("Cramps", selectedSymptoms, setState),
                        _buildSymptomChip("Headache", selectedSymptoms, setState),
                        _buildSymptomChip("Mood Swings", selectedSymptoms, setState),
                        _buildSymptomChip("Fatigue", selectedSymptoms, setState),
                        _buildSymptomChip("Back Pain", selectedSymptoms, setState),
                      ],
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
                    if (startDate != null && endDate != null && endDate!.isAfter(startDate!)) {
                      await _addPeriodEntry(startDate!, endDate!, selectedSymptoms);
                      Navigator.pop(context);
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

  Widget _buildSymptomChip(String symptom, List<String> selectedSymptoms, void Function(void Function()) setState) {
    final isSelected = selectedSymptoms.contains(symptom);
    return FilterChip(
      label: Text(symptom),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedSymptoms.add(symptom);
          } else {
            selectedSymptoms.remove(symptom);
          }
        });
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildPeriodHistoryCard(Map<String, dynamic> periodData, int index) {
    final startDate = (periodData['startDate'] as Timestamp).toDate();
    final endDate = (periodData['endDate'] as Timestamp).toDate();
    final symptoms = List<String>.from(periodData['symptoms'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Period ${index + 1}: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Text(
              "Symptoms: ${symptoms.isEmpty ? 'None' : symptoms.join(', ')}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageCycleLength() {
    if (_periodHistory.length < 2) return 0.0;

    int totalCycleLength = 0;
    for (int i = 1; i < _periodHistory.length; i++) {
      final previousStartDate = (_periodHistory[i - 1]['startDate'] as Timestamp).toDate();
      final currentStartDate = (_periodHistory[i]['startDate'] as Timestamp).toDate();
      totalCycleLength += currentStartDate.difference(previousStartDate).inDays;
    }

    return (totalCycleLength / (_periodHistory.length - 1)).toDouble();
  }

  String _predictNextPeriodRange() {
    if (_periodHistory.isEmpty) return "No data available";

    final averageCycleLength = _calculateAverageCycleLength();
    final lastStartDate = (_periodHistory.last['startDate'] as Timestamp).toDate();
    final nextStartDate = lastStartDate.add(Duration(days: averageCycleLength.round()));

    final rangeStart = DateFormat('dd/MM/yyyy').format(nextStartDate.subtract(const Duration(days: 2)));
    final rangeEnd = DateFormat('dd/MM/yyyy').format(nextStartDate.add(const Duration(days: 2)));

    return "$rangeStart - $rangeEnd";
  }

  Widget _buildStatisticsChart() {
    List<Map<String, dynamic>> cycleLengths = [];
    for (int i = 1; i < _periodHistory.length; i++) {
      final previousStartDate = (_periodHistory[i - 1]['startDate'] as Timestamp).toDate();
      final currentStartDate = (_periodHistory[i]['startDate'] as Timestamp).toDate();
      int cycleLength = currentStartDate.difference(previousStartDate).inDays;
      cycleLengths.add({
        'startDate': DateFormat('dd/MM/yyyy').format(currentStartDate),
        'cycleLength': cycleLength,
      });
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      title: ChartTitle(text: 'Cycle Length Over Time'),
      series: <CartesianSeries>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: cycleLengths,
          xValueMapper: (Map<String, dynamic> data, _) => data['startDate'],
          yValueMapper: (Map<String, dynamic> data, _) => data['cycleLength'],
          dataLabelSettings: DataLabelSettings(isVisible: true),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final averageCycleLength = _calculateAverageCycleLength();
    final predictedRange = _predictNextPeriodRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Period Tracking",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddPeriodDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_periodHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Average Cycle Length: ${averageCycleLength.toStringAsFixed(1)} days",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Predicted Next Period: $predictedRange",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  _buildStatisticsChart(),
                  const SizedBox(height: 20),
                ],
              ),
            Expanded(
              child: _periodHistory.isEmpty
                  ? const Center(child: Text("No period history recorded."))
                  : ListView.builder(
                itemCount: _periodHistory.length,
                itemBuilder: (context, index) {
                  return _buildPeriodHistoryCard(_periodHistory[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
