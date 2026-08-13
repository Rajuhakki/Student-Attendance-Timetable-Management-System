import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart'; // Add this import for WidgetsBinding
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';

class TimetableEntryScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const TimetableEntryScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<TimetableEntryScreen> createState() => _TimetableEntryScreenState();
}

class _TimetableEntryScreenState extends State<TimetableEntryScreen> {
  late ScheduleProvider _scheduleProvider;
  bool _isLoading = false;

  // Manual entry data
  final List<String> _timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00', // Break time
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
  ];

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  // Controllers for each cell in the timetable
  late List<List<TextEditingController>> _subjectControllers;
  late List<List<TextEditingController>> _facultyControllers;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _initializeControllers();
    // Load existing timetable data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingTimetable();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load timetable data once when the widget is first built
    // This prevents multiple reloads when dependencies change
  }

  void _initializeControllers() {
    _subjectControllers = List.generate(
      _daysOfWeek.length,
      (dayIndex) => List.generate(
        _timeSlots.length,
        (slotIndex) => TextEditingController(),
      ),
    );

    _facultyControllers = List.generate(
      _daysOfWeek.length,
      (dayIndex) => List.generate(
        _timeSlots.length,
        (slotIndex) => TextEditingController(),
      ),
    );
  }

  // Load existing timetable data when the screen initializes
  Future<void> _loadExistingTimetable() async {
    try {
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);
      
      // Get existing schedules for this department and semester
      final existingSchedules = _scheduleProvider.schedules
          .where(
            (schedule) =>
                schedule.className == widget.departmentName &&
                schedule.semester == widget.semester,
          )
          .toList();

      // Populate the controllers with existing data
      for (var schedule in existingSchedules) {
        // Find the matching day index (Monday = 1, so subtract 1 for zero-based index)
        final dayIndex = schedule.dayOfWeek - 1;
        
        // Skip if day index is out of bounds
        if (dayIndex < 0 || dayIndex >= _daysOfWeek.length) continue;
        
        // Find the matching time slot index
        for (int slotIndex = 0; slotIndex < _timeSlots.length; slotIndex++) {
          final timeSlot = _timeSlots[slotIndex];
          final timeParts = timeSlot.split(' - ');
          
          // Check if this time slot matches the schedule
          if (timeParts.length == 2 && 
              timeParts[0] == schedule.startTime && 
              timeParts[1] == schedule.endTime) {
            
            // Populate the controllers
            if (dayIndex < _subjectControllers.length && 
                slotIndex < _subjectControllers[dayIndex].length) {
              _subjectControllers[dayIndex][slotIndex].text = schedule.subject;
            }
            
            if (dayIndex < _facultyControllers.length && 
                slotIndex < _facultyControllers[dayIndex].length && 
                schedule.faculty != null) {
              _facultyControllers[dayIndex][slotIndex].text = schedule.faculty!;
            }
            
            break; // Found the matching time slot, move to next schedule
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading existing timetable: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var dayControllers in _subjectControllers) {
      for (var controller in dayControllers) {
        controller.dispose();
      }
    }

    for (var dayControllers in _facultyControllers) {
      for (var controller in dayControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _saveManualEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing schedules for this department and semester
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);
      final existingSchedules = _scheduleProvider.schedules
          .where(
            (schedule) =>
                schedule.className == widget.departmentName &&
                schedule.semester == widget.semester,
          )
          .toList();

      // Create a map of existing schedules for quick lookup
      final existingScheduleMap = <String, Schedule>{};
      for (var schedule in existingSchedules) {
        final key = '${schedule.dayOfWeek}_${schedule.startTime}_${schedule.endTime}';
        existingScheduleMap[key] = schedule;
      }

      // Process each time slot
      for (int dayIndex = 0; dayIndex < _daysOfWeek.length; dayIndex++) {
        final day = _daysOfWeek[dayIndex];

        for (int slotIndex = 0; slotIndex < _timeSlots.length; slotIndex++) {
          // Skip break time slots (12:00 - 13:00)
          if (slotIndex == 3) {
            continue;
          }

          final subject = _subjectControllers[dayIndex][slotIndex].text.trim();
          final faculty = _facultyControllers[dayIndex][slotIndex].text.trim();

          // Parse start and end times from time slot
          final timeParts = _timeSlots[slotIndex].split(' - ');
          final startTime = timeParts[0];
          final endTime = timeParts[1];

          // Create a key to identify this time slot
          final scheduleKey = '${dayIndex + 1}_${startTime}_${endTime}';

          if (subject.isNotEmpty) {
            // Create or update schedule
            final schedule = Schedule(
              id: existingScheduleMap.containsKey(scheduleKey) 
                  ? existingScheduleMap[scheduleKey]!.id 
                  : null, // Keep existing ID if it exists
              semester: widget.semester,
              className: widget.departmentName,
              dayOfWeek: dayIndex + 1, // Monday = 1, Sunday = 7
              startTime: startTime,
              endTime: endTime,
              subject: subject,
              faculty: faculty.isNotEmpty ? faculty : null,
            );

            if (schedule.id != null) {
              // Update existing schedule
              await _scheduleProvider.updateSchedule(schedule);
            } else {
              // Add new schedule
              await _scheduleProvider.addSchedule(schedule);
            }
          } else if (existingScheduleMap.containsKey(scheduleKey)) {
            // If subject is empty but schedule existed before, delete it
            await _scheduleProvider.deleteSchedule(existingScheduleMap[scheduleKey]!.id!);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to set break time across all days for a specific time slot
  void _setBreakTime(int slotIndex) {
    for (int dayIndex = 0; dayIndex < _daysOfWeek.length; dayIndex++) {
      _subjectControllers[dayIndex][slotIndex].text = 'BREAK TIME';
      _facultyControllers[dayIndex][slotIndex].text = '';
    }
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Break time set for all days in this time slot'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Function to clear break time
  void _clearBreakTime(int slotIndex) {
    for (int dayIndex = 0; dayIndex < _daysOfWeek.length; dayIndex++) {
      _subjectControllers[dayIndex][slotIndex].clear();
      _facultyControllers[dayIndex][slotIndex].clear();
    }
    // Show a snackbar to inform the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Break time cleared for all days in this time slot'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildTimetableTable() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timetable Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Instructions for the admin
            const Text(
              'Instructions: Fill in subjects and faculty for each time slot. For break times, tap the "Break" button.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Improved table layout with better formatting
            LayoutBuilder(
              builder: (context, constraints) {
                // For better responsiveness on different screen sizes
                final cellWidth = constraints.maxWidth > 600 ? 150.0 : 120.0;
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: Table(
                      defaultColumnWidth: FixedColumnWidth(cellWidth),
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      children: [
                        // Header row
                        TableRow(
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                          ),
                          children: [
                            const TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'Day / Time',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            ..._timeSlots.asMap().entries.map(
                              (entry) {
                                final slotIndex = entry.key;
                                final slot = entry.value;
                                return TableCell(
                                  verticalAlignment: TableCellVerticalAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          slot,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        // Add break time button for the lunch break slot (12:00 - 13:00)
                                        if (slotIndex == 3) ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _setBreakTime(slotIndex),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  backgroundColor: Colors.orange,
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text(
                                                  'Set Break',
                                                  style: TextStyle(fontSize: 10),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              ElevatedButton(
                                                onPressed: () => _clearBreakTime(slotIndex),
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  backgroundColor: Colors.grey,
                                                  minimumSize: Size.zero,
                                                ),
                                                child: const Text(
                                                  'Clear',
                                                  style: TextStyle(fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ] else ...[
                                          const Text(
                                            '(Subject / Faculty)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ).toList(),
                          ],
                        ),
                        // Data rows
                        for (int dayIndex = 0; dayIndex < _daysOfWeek.length; dayIndex++)
                          TableRow(
                            children: [
                              TableCell(
                                verticalAlignment: TableCellVerticalAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    _daysOfWeek[dayIndex],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              ..._timeSlots.asMap().entries.map(
                                (entry) {
                                  final slotIndex = entry.key;
                                  return TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // For break time slot, show a special UI
                                          if (slotIndex == 3) ...[
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange,
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Text(
                                                'BREAK TIME',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ] else ...[
                                            // Subject input
                                            TextField(
                                              controller: _subjectControllers[dayIndex][slotIndex],
                                              decoration: const InputDecoration(
                                                hintText: 'Subject',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Faculty input
                                            TextField(
                                              controller: _facultyControllers[dayIndex][slotIndex],
                                              decoration: const InputDecoration(
                                                hintText: 'Faculty',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveManualEntries,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.indigo,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 10),
                          Text('Saving...'),
                        ],
                      )
                    : const Text(
                        'Save Timetable',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
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
        title: Text('${widget.departmentName} - Timetable Entry'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual entry section
                  _buildTimetableTable(),
                ],
              ),
            ),
    );
  }
}