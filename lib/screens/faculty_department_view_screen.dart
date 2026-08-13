import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';
import 'current_schedule_screen.dart';
import 'record_attendance_form_screen.dart';

class FacultyDepartmentViewScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const FacultyDepartmentViewScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<FacultyDepartmentViewScreen> createState() =>
      _FacultyDepartmentViewScreenState();
}

class _FacultyDepartmentViewScreenState
    extends State<FacultyDepartmentViewScreen> {
  late ScheduleProvider _scheduleProvider;
  bool _isLoading = true;
  List<Schedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load schedules for this semester
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);

      // Filter schedules for this department
      // The department name format is "Department Name - Class X"
      _schedules = _scheduleProvider.schedules
          .where(
            (schedule) =>
                schedule.semester == widget.semester &&
                schedule.className.startsWith(widget.departmentName),
          )
          .toList();

      // Sort by class name and then by day/time
      _schedules.sort((a, b) {
        // First sort by class name
        int classComparison = a.className.compareTo(b.className);
        if (classComparison != 0) return classComparison;

        // Then sort by day of week
        int dayComparison = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayComparison != 0) return dayComparison;

        // Finally sort by start time
        return a.startTime.compareTo(b.startTime);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading schedules: $e'),
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

  // Function to get current class for a specific class name
  Schedule? _getCurrentClass(String className) {
    // Get today's day of week (1 = Monday, 7 = Sunday)
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    // Get current time in HH:MM format
    final currentTime = DateFormat('HH:mm').format(now);

    // Find schedules for this class and today
    final classSchedules = _schedules
        .where(
          (schedule) =>
              schedule.className == className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList();

    // Check if current time falls within any schedule
    for (final schedule in classSchedules) {
      if (_isTimeBetween(currentTime, schedule.startTime, schedule.endTime)) {
        return schedule;
      }
    }

    return null;
  }

  // Function to get all today's schedules for a specific class (excluding current)
  List<Schedule> _getTodaySchedulesExceptCurrent(String className) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    // Get current time in HH:MM format
    final currentTime = DateFormat('HH:mm').format(now);

    // Get all schedules for this class and today
    final todaySchedules = _schedules
        .where(
          (schedule) =>
              schedule.className == className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList();

    // Filter out currently running classes
    return todaySchedules.where((schedule) {
      // Check if current time falls within this schedule
      final isCurrent = _isTimeBetween(
        currentTime,
        schedule.startTime,
        schedule.endTime,
      );
      // Return true if it's NOT the current class
      return !isCurrent;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
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

  // Function to get unique class names from schedules
  List<String> _getClassNames() {
    final classNames = <String>{};
    for (final schedule in _schedules) {
      classNames.add(schedule.className);
    }
    return classNames.toList()..sort();
  }

  // Function to get all today's schedules for a specific class
  List<Schedule> _getTodaySchedules(String className) {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    return _schedules
        .where(
          (schedule) =>
              schedule.className == className &&
              schedule.dayOfWeek == dayOfWeek,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Widget build(BuildContext context) {
    final classNames = _getClassNames();
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final dayOfWeek = DateFormat('EEEE').format(now);

    // Get all current classes across all class names
    final currentClasses = <String, Schedule>{};
    final otherTodayClassesAll = <Schedule>[];

    for (final className in classNames) {
      final currentClass = _getCurrentClass(className);
      if (currentClass != null) {
        currentClasses[className] = currentClass;
      }

      // Get today's schedules except current for this class
      final todaySchedulesExceptCurrent = _getTodaySchedulesExceptCurrent(
        className,
      );
      otherTodayClassesAll.addAll(todaySchedulesExceptCurrent);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} - Current Classes'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules, // Refresh data
            tooltip: 'Refresh schedules',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current time and day indicator
            Card(
              color: Colors.indigo.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Text(
                      '$dayOfWeek, $currentTime',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Current classes indicator
            if (currentClasses.isNotEmpty) ...[
              Card(
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currently in Session:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...currentClasses.entries.map((entry) {
                        final className = entry.key;
                        final schedule = entry.value;
                        final classDisplayName = className.contains(' - Class ')
                            ? className.split(' - Class ')[1]
                            : className;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Class $classDisplayName: ${schedule.subject}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${schedule.startTime} - ${schedule.endTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Other classes today indicator
            if (otherTodayClassesAll.isNotEmpty) ...[
              Card(
                color: Colors.grey.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other Classes Today:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...otherTodayClassesAll.map((schedule) {
                        final className = schedule.className;
                        final classDisplayName = className.contains(' - Class ')
                            ? className.split(' - Class ')[1]
                            : className;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Class $classDisplayName: ${schedule.subject}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${schedule.startTime} - ${schedule.endTime}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            Text(
              'Semester ${widget.semester} - Current Classes',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Click on a class to view current schedule or record attendance',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_schedules.isEmpty)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No schedules found', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      'Please contact admin to set up class schedules',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: classNames.length,
                  itemBuilder: (context, index) {
                    final className = classNames[index];
                    final currentClass = _getCurrentClass(className);
                    final todaySchedules = _getTodaySchedules(className);

                    // Extract just the class part (e.g., "Class A" from "Computer Science - Class A")
                    final classDisplayName = className.contains(' - Class ')
                        ? className.split(' - Class ')[1]
                        : className;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Class $classDisplayName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (currentClass != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NOW',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: currentClass != null
                            ? Text(
                                'Now: ${currentClass.subject}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const Text(
                                'No class in session',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Current class information
                                if (currentClass != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'CURRENT CLASS',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.subject,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                currentClass.subject,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${DateFormat('jm').format(DateFormat('HH:mm').parse(currentClass.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(currentClass.endTime))}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (currentClass.faculty != null &&
                                            currentClass
                                                .faculty!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Faculty: ${currentClass.faculty}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              // Navigate directly to record attendance form
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      // Import the record attendance form screen
                                                      RecordAttendanceFormScreen(
                                                        semester:
                                                            widget.semester,
                                                        className: className,
                                                        scheduledFaculty:
                                                            currentClass
                                                                .faculty,
                                                      ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.check_circle,
                                            ),
                                            label: const Text(
                                              'Record Attendance',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'No class in session right now',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Today's other schedules section
                                Builder(
                                  builder: (context) {
                                    final todaySchedulesExceptCurrent =
                                        _getTodaySchedulesExceptCurrent(
                                          className,
                                        );
                                    if (todaySchedulesExceptCurrent.isEmpty)
                                      return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Other Classes Today:',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: todaySchedulesExceptCurrent
                                              .length,
                                          itemBuilder: (context, index) {
                                            final schedule =
                                                todaySchedulesExceptCurrent[index];
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.event,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          schedule.subject,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        Text(
                                                          '${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.endTime))}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                        if (schedule.faculty !=
                                                                null &&
                                                            schedule
                                                                .faculty!
                                                                .isNotEmpty)
                                                          Text(
                                                            'Faculty: ${schedule.faculty}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  },
                                ),

                                // Today's schedule
                                const Text(
                                  'Today\'s Schedule:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (todaySchedules.isEmpty) ...[
                                  const Text(
                                    'No classes scheduled for today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ] else ...[
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: todaySchedules.length,
                                    itemBuilder: (context, index) {
                                      final schedule = todaySchedules[index];
                                      final isCurrent =
                                          schedule == currentClass;

                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.grey.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isCurrent
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    schedule.subject,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: isCurrent
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isCurrent
                                                          ? Colors.green
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.startTime))} - ${DateFormat('jm').format(DateFormat('HH:mm').parse(schedule.endTime))}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (schedule.faculty !=
                                                          null &&
                                                      schedule
                                                          .faculty!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Faculty: ${schedule.faculty}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (isCurrent)
                                              const Icon(
                                                Icons.play_arrow,
                                                color: Colors.green,
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CurrentScheduleScreen(
                                                    semester: widget.semester,
                                                    className: className,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.visibility),
                                        label: const Text('View Full Schedule'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed:
                                            _loadSchedules, // Refresh data
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Refresh'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
