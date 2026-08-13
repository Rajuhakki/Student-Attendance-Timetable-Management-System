import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../providers/attendance_provider.dart';
import 'package:provider/provider.dart';

class RecordAttendanceScreen extends StatefulWidget {
  const RecordAttendanceScreen({super.key});

  @override
  State<RecordAttendanceScreen> createState() => _RecordAttendanceScreenState();
}

class _RecordAttendanceScreenState extends State<RecordAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classroomController = TextEditingController();
  final _studentCountController = TextEditingController();
  final _facultyNameController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();

  @override
  void dispose() {
    _classroomController.dispose();
    _studentCountController.dispose();
    _facultyNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (!context.mounted) return;

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (!context.mounted) return;

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Proceed with attendance recording
      final attendance = Attendance(
        classroom: _classroomController.text,
        studentCount: int.parse(_studentCountController.text),
        timestamp: _selectedDateTime,
        facultyName: _facultyNameController.text,
      );

      Provider.of<AttendanceProvider>(
        context,
        listen: false,
      ).addAttendance(attendance);

      // Clear form
      _classroomController.clear();
      _studentCountController.clear();
      _facultyNameController.clear();
      setState(() {
        _selectedDateTime = DateTime.now();
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance recorded successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Attendance'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _classroomController,
                          decoration: const InputDecoration(
                            labelText: 'Classroom',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the classroom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _studentCountController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Students Present',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the number of students';
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) < 0) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _facultyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Faculty Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the faculty name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          child: ListTile(
                            title: const Text('Date & Time'),
                            subtitle: Text(
                              DateFormat(
                                'yyyy-MM-dd HH:mm',
                              ).format(_selectedDateTime),
                            ),
                            leading: const Icon(
                              Icons.calendar_today,
                              color: Colors.indigo,
                            ),
                            trailing: const Icon(
                              Icons.edit,
                              color: Colors.indigo,
                            ),
                            onTap: () => _selectDateTime(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Record Attendance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
