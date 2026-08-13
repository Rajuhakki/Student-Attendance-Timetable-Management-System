import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';

class ScheduleManagementScreen extends StatefulWidget {
  final int semester;
  final String? departmentName; // Add departmentName parameter

  const ScheduleManagementScreen({
    super.key,
    required this.semester,
    this.departmentName,
  });

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _facultyController =
      TextEditingController(); // Add faculty controller
  final List<String> _classes = ['A', 'B'];
  String? _selectedClass;
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late ScheduleProvider _scheduleProvider;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _scheduleProvider.loadSchedulesBySemester(widget.semester);
  }

  @override
  void dispose() {
    _subjectController.dispose(); // Dispose subject controller
    _facultyController.dispose(); // Dispose faculty controller
    super.dispose();
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  void _addSchedule() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClass == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a class'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a day'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both start and end times'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert TimeOfDay to String format HH:MM
      final startTimeStr =
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

      // Validate that end time is after start time
      final startDateTime = DateFormat.Hm().parse(startTimeStr);
      final endDateTime = DateFormat.Hm().parse(endTimeStr);

      if (endDateTime.isBefore(startDateTime) ||
          endDateTime.isAtSameMomentAs(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Find the day index (1 = Monday, 7 = Sunday)
      final dayIndex = _daysOfWeek.indexOf(_selectedDay!) + 1;

      // Create className with department name if provided, otherwise just class letter
      final className = widget.departmentName != null
          ? '${widget.departmentName} - Class ${_selectedClass!}'
          : _selectedClass!;

      final schedule = Schedule(
        semester: widget.semester,
        className: className,
        dayOfWeek: dayIndex,
        startTime: startTimeStr,
        endTime: endTimeStr,
        subject: _subjectController.text,
        faculty: _facultyController.text.isNotEmpty
            ? _facultyController.text
            : null, // Add faculty
      );

      _scheduleProvider.addSchedule(schedule);

      // Reset form
      setState(() {
        _subjectController.clear();
        _facultyController.clear(); // Clear faculty controller
        _selectedClass = null;
        _selectedDay = null;
        _startTime = null;
        _endTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteSchedule(int id) {
    _scheduleProvider.deleteSchedule(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _confirmDeleteSchedule(int id, String subject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: Text(
            'Are you sure you want to delete the schedule for "$subject"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteSchedule(id);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAllSchedules() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Schedules'),
          content: const Text(
            'Are you sure you want to delete ALL schedules for this semester? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scheduleProvider.clearAllSchedulesForSemester(widget.semester);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All schedules cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Schedules - Semester ${widget.semester}'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add schedule form
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Add faculty field
                      TextFormField(
                        controller: _facultyController,
                        decoration: const InputDecoration(
                          labelText: 'Faculty (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.class_),
                        ),
                        items: _classes.map((String className) {
                          return DropdownMenuItem<String>(
                            value: className,
                            child: Text(className),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedClass = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a class';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Add day selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDay,
                        hint: const Text('Select Day'),
                        items: _daysOfWeek.map((day) {
                          return DropdownMenuItem(value: day, child: Text(day));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDay = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Day of Week',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a day';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectStartTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startTime == null
                                          ? 'Select Time'
                                          : _startTime!.format(context),
                                    ),
                                    const Icon(Icons.access_time),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectEndTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endTime == null
                                          ? 'Select Time'
                                          : _endTime!.format(context),
                                    ),
                                    const Icon(Icons.access_time),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addSchedule,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.indigo,
                          ),
                          child: const Text(
                            'Add Schedule',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Display existing schedules
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Existing Schedules',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _confirmClearAllSchedules,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ScheduleProvider>(
                builder: (context, scheduleProvider, child) {
                  // Filter schedules for this semester
                  final schedules = scheduleProvider.schedules
                      .where((schedule) => schedule.semester == widget.semester)
                      .toList();

                  if (schedules.isEmpty) {
                    return const Center(
                      child: Text(
                        'No schedules found',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: schedules.length,
                    itemBuilder: (context, index) {
                      final schedule = schedules[index];
                      final subject = schedule.subject;
                      final className = schedule.className;
                      final dayName = _daysOfWeek[schedule.dayOfWeek - 1];
                      final startTime = schedule.startTime;
                      final endTime = schedule.endTime;
                      final faculty = schedule.faculty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class: $className | Day: $dayName'),
                              Text(
                                '${DateFormat('jm').format(DateFormat('HH:mm').parse(startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(endTime))}',
                              ),
                              if (faculty != null && faculty.isNotEmpty)
                                Text(
                                  'Faculty: $faculty',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.indigo,
                                  ),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDeleteSchedule(schedule.id!, subject),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
