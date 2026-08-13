import 'package:flutter/material.dart';
import 'record_attendance_form_screen.dart';

class FacultyClassSelectionScreen extends StatefulWidget {
  final int semester;

  const FacultyClassSelectionScreen({super.key, required this.semester});

  @override
  State<FacultyClassSelectionScreen> createState() =>
      _FacultyClassSelectionScreenState();
}

class _FacultyClassSelectionScreenState
    extends State<FacultyClassSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _classController = TextEditingController();

  @override
  void dispose() {
    _classController.dispose();
    super.dispose();
  }

  void _proceedToAttendance() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordAttendanceFormScreen(
            semester: widget.semester,
            className: _classController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Class - Semester ${widget.semester}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter the class name for attendance recording',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                        controller: _classController,
                        decoration: const InputDecoration(
                          labelText: 'Class Name',
                          border: OutlineInputBorder(),
                          hintText: 'Enter class name (e.g., A, B, 1, 2)',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a class name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _proceedToAttendance,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text(
                            'Proceed to Attendance',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
