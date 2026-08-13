import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';

class DepartmentScheduleManagementScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const DepartmentScheduleManagementScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<DepartmentScheduleManagementScreen> createState() =>
      _DepartmentScheduleManagementScreenState();
}

class _DepartmentScheduleManagementScreenState
    extends State<DepartmentScheduleManagementScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _facultyController =
      TextEditingController(); // Add faculty controller
  final TextEditingController _classController = TextEditingController();
  String? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late ScheduleProvider _scheduleProvider;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _scheduleProvider.loadSchedulesBySemester(widget.semester);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _facultyController.dispose(); // Dispose faculty controller
    _classController.dispose();
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

  Future<void> _addSchedule() async {
    if (_selectedDay == null ||
        _startTime == null ||
        _endTime == null ||
        _subjectController.text.trim().isEmpty ||
        _classController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      // Find the day index (1 = Monday, 7 = Sunday)
      final dayIndex = _daysOfWeek.indexOf(_selectedDay!) + 1;

      final schedule = Schedule(
        semester: widget.semester,
        className:
            '${widget.departmentName} - Class ${_classController.text.trim()}',
        dayOfWeek: dayIndex,
        startTime:
            '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
        subject: _subjectController.text.trim(),
        faculty:
            _facultyController.text
                .trim()
                .isNotEmpty // Add faculty
            ? _facultyController.text.trim()
            : null,
      );

      await _scheduleProvider.addSchedule(schedule);

      // Clear form
      setState(() {
        _subjectController.clear();
        _facultyController.clear(); // Clear faculty controller
        _classController.clear();
        _selectedDay = null;
        _startTime = null;
        _endTime = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} - Schedule Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Form for adding new schedules
          Card(
            margin: const EdgeInsets.all(16.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Add New Schedule',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Subject field
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                      hintText: 'Enter subject name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Faculty field
                  TextField(
                    controller: _facultyController,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      border: OutlineInputBorder(),
                      hintText: 'Enter faculty name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Class field
                  TextField(
                    controller: _classController,
                    decoration: const InputDecoration(
                      labelText: 'Class (e.g., A, B, 1, 2)',
                      border: OutlineInputBorder(),
                      hintText: 'Enter class identifier',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Day selection
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
                  ),
                  const SizedBox(height: 16),
                  // Time selection
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
                            child: Text(
                              _startTime == null
                                  ? 'Select Time'
                                  : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
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
                            child: Text(
                              _endTime == null
                                  ? 'Select Time'
                                  : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
          // Display existing schedules
          Expanded(
            child: Consumer<ScheduleProvider>(
              builder: (context, scheduleProvider, child) {
                // Filter schedules for this department
                final schedules = scheduleProvider.schedules
                    .where(
                      (schedule) =>
                          schedule.semester == widget.semester &&
                          schedule.className.startsWith(widget.departmentName),
                    )
                    .toList();

                if (schedules.isEmpty) {
                  return const Center(
                    child: Text(
                      'No schedules found for this department',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final dayName = _daysOfWeek[schedule.dayOfWeek - 1];
                    // Extract class name from the full class name
                    final className = schedule.className.replaceFirst(
                      '${widget.departmentName} - Class ',
                      '',
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          schedule.subject,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            if (schedule.faculty != null &&
                                schedule
                                    .faculty!
                                    .isNotEmpty) // Show faculty if available
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Faculty: ${schedule.faculty}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.class_,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Class: $className',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${schedule.startTime} - ${schedule.endTime}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteSchedule(
                            schedule.id!,
                            schedule.subject,
                          ),
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
    );
  }
}
