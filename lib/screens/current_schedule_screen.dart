import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';
import 'record_attendance_form_screen.dart';

class CurrentScheduleScreen extends StatefulWidget {
  final int semester;
  final String className;

  const CurrentScheduleScreen({
    super.key,
    required this.semester,
    required this.className,
  });

  @override
  State<CurrentScheduleScreen> createState() => _CurrentScheduleScreenState();
}

class _CurrentScheduleScreenState extends State<CurrentScheduleScreen> {
  late ScheduleProvider _scheduleProvider;
  Schedule? _currentSchedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _loadCurrentSchedule();
  }

  Future<void> _loadCurrentSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load schedules for this semester
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);

      // Get current schedule based on current time
      _currentSchedule = _scheduleProvider.getCurrentSchedule(
        widget.semester,
        widget.className,
        DateTime.now(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedule: $e'),
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

  // Helper method to check if a time is between start and end times
  bool _isTimeBetween(String currentTime, String startTime, String endTime) {
    // Convert times to comparable integers (HHMM format)
    final current = int.parse(currentTime.replaceAll(':', ''));
    final start = int.parse(startTime.replaceAll(':', ''));
    final end = int.parse(endTime.replaceAll(':', ''));

    // Handle case where end time is next day (e.g., 23:00 - 01:00)
    if (end < start) {
      return current >= start || current <= end;
    } else {
      return current >= start && current <= end;
    }
  }

  // Function to get upcoming classes that will start soon (within 30 minutes)
  Schedule? _getUpcomingClass() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    // Get current time in minutes since midnight
    final currentMinutes = now.hour * 60 + now.minute;
    final currentTime = DateFormat('HH:mm').format(now);
    
    // Get all schedules for this semester and class
    final classSchedules = _scheduleProvider.schedules
        .where(
          (schedule) =>
              schedule.semester == widget.semester &&
              schedule.className == widget.className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList();

    // Find upcoming classes
    final upcomingClasses = classSchedules
        .where((schedule) {
          // Skip currently running classes
          if (_isTimeBetween(currentTime, schedule.startTime, schedule.endTime)) {
            return false;
          }
          
          // Parse start time to minutes since midnight
          final startTimeParts = schedule.startTime.split(':');
          final startMinutes = int.parse(startTimeParts[0]) * 60 + int.parse(startTimeParts[1]);
          
          // Check if class starts within the next 30 minutes
          return startMinutes > currentMinutes && startMinutes <= currentMinutes + 30;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return upcomingClasses.isEmpty ? null : upcomingClasses.first;
  }

  // Function to get classes that are about to end soon (within 30 minutes)
  Schedule? _getExpiringClass() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    // Get current time in minutes since midnight
    final currentMinutes = now.hour * 60 + now.minute;
    final currentTime = DateFormat('HH:mm').format(now);
    
    // Get all schedules for this semester and class
    final classSchedules = _scheduleProvider.schedules
        .where(
          (schedule) =>
              schedule.semester == widget.semester &&
              schedule.className == widget.className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList();

    // Find expiring classes (currently running)
    final expiringClasses = classSchedules
        .where((schedule) {
          // Only consider currently running classes
          if (!_isTimeBetween(currentTime, schedule.startTime, schedule.endTime)) {
            return false;
          }
          
          // Parse end time to minutes since midnight
          final endTimeParts = schedule.endTime.split(':');
          final endMinutes = int.parse(endTimeParts[0]) * 60 + int.parse(endTimeParts[1]);
          
          // Check if class ends within the next 30 minutes
          return endMinutes > currentMinutes && endMinutes <= currentMinutes + 30;
        })
        .toList()
      ..sort((a, b) => a.endTime.compareTo(b.endTime));

    return expiringClasses.isEmpty ? null : expiringClasses.first;
  }

  // Function to get today's schedules except current class
  List<Schedule> _getTodaySchedulesExceptCurrent() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    
    // Get current time in HH:MM format
    final currentTime = DateFormat('HH:mm').format(now);
    
    // Get all schedules for this semester and class
    final classSchedules = _scheduleProvider.schedules
        .where(
          (schedule) =>
              schedule.semester == widget.semester &&
              schedule.className == widget.className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList();

    // Filter out currently running classes
    return classSchedules
        .where((schedule) {
          // Check if current time falls within this schedule
          final isCurrent = _isTimeBetween(currentTime, schedule.startTime, schedule.endTime);
          // Return true if it's NOT the current class
          return !isCurrent;
        })
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _proceedToAttendance() {
    if (_currentSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No schedule found for current time.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to attendance screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordAttendanceFormScreen(
          semester: widget.semester,
          className: widget.className,
          scheduledFaculty: _currentSchedule!.faculty, // Pass scheduled faculty
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Current Schedule - Sem ${widget.semester} Class ${widget.className}',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Go back to the faculty department view
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current schedule section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_currentSchedule != null)
                      Column(
                        children: [
                          ListTile(
                            title: Text(
                              _currentSchedule!.subject,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${DateFormat('jm').format(DateFormat('HH:mm').parse(_currentSchedule!.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(_currentSchedule!.endTime))}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                if (_currentSchedule!.faculty != null &&
                                    _currentSchedule!.faculty!.isNotEmpty)
                                  Text(
                                    'Faculty: ${_currentSchedule!.faculty}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                            leading: const Icon(
                              Icons.access_time,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _proceedToAttendance,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child: const Text('Record Attendance'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Icon(Icons.info, size: 60, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'No Scheduled Class',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'There is no class scheduled for this time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Upcoming class section
            Builder(
              builder: (context) {
                final upcomingClass = _getUpcomingClass();
                if (upcomingClass == null) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming Class',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              title: Text(
                                upcomingClass.subject,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormat('jm').format(DateFormat('HH:mm').parse(upcomingClass.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(upcomingClass.endTime))}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (upcomingClass.faculty != null &&
                                      upcomingClass.faculty!.isNotEmpty)
                                    Text(
                                      'Faculty: ${upcomingClass.faculty}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              leading: const Icon(
                                Icons.schedule,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Expiring class section
            Builder(
              builder: (context) {
                final expiringClass = _getExpiringClass();
                if (expiringClass == null) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.orange.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expiring Soon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              title: Text(
                                expiringClass.subject,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${DateFormat('jm').format(DateFormat('HH:mm').parse(expiringClass.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(expiringClass.endTime))}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  if (expiringClass.faculty != null &&
                                      expiringClass.faculty!.isNotEmpty)
                                    Text(
                                      'Faculty: ${expiringClass.faculty}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              leading: const Icon(
                                Icons.timer,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            // Other classes today section
            Builder(
              builder: (context) {
                final otherTodayClasses = _getTodaySchedulesExceptCurrent();
                if (otherTodayClasses.isEmpty) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Other Classes Today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: otherTodayClasses.length,
                              itemBuilder: (context, index) {
                                final schedule = otherTodayClasses[index];
                                return ListTile(
                                  title: Text(
                                    schedule.subject,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.endTime))}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (schedule.faculty != null &&
                                          schedule.faculty!.isNotEmpty)
                                        Text(
                                          'Faculty: ${schedule.faculty}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: const Icon(
                                    Icons.event,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
