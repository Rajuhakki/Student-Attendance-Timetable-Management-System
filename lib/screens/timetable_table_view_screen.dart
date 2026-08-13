import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/attendance.dart';

class TimetableTableViewScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const TimetableTableViewScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<TimetableTableViewScreen> createState() =>
      _TimetableTableViewScreenState();
}

class _TimetableTableViewScreenState extends State<TimetableTableViewScreen> {
  late ScheduleProvider _scheduleProvider;
  bool _isLoading = true;
  List<Schedule> _schedules = [];

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

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
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);
      _schedules = _scheduleProvider.schedules
          .where(
            (schedule) =>
                schedule.className == widget.departmentName ||
                schedule.className.startsWith(widget.departmentName),
          )
          .toList();
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

  // Organize schedules into a 2D structure: [day][timeSlot] -> Schedule
  Map<int, Map<String, Schedule>> _organizeSchedules() {
    final organized = <int, Map<String, Schedule>>{};

    // Initialize the structure
    for (int dayIndex = 1; dayIndex <= 7; dayIndex++) {
      organized[dayIndex] = {};
    }

    // Fill with schedules
    for (final schedule in _schedules) {
      organized[schedule.dayOfWeek]?[schedule.startTime] = schedule;
    }

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    final organizedSchedules = _organizeSchedules();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} - Timetable'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Timetable',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Semester ${widget.semester}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_schedules.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No timetable data found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please add schedule data to view the timetable.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSchedules,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 16,
                      headingRowColor: WidgetStatePropertyAll(
                        Colors.indigo.withValues(alpha: 0.1),
                      ),
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 14,
                      ),
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.08);
                        }
                        return null;
                      }),
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columns: [
                        DataColumn(
                          label: Container(
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(minWidth: 80),
                            child: const Text('Time'),
                          ),
                        ),
                        ..._dayNames.map(
                          (day) => DataColumn(
                            label: Container(
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(minWidth: 120),
                              child: Text(day, textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                      ],
                      rows: _timeSlots.map((timeSlot) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Container(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  '$timeSlot-${_getNextHour(timeSlot)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            ..._daysOfWeek.asMap().entries.map((entry) {
                              final dayIndex =
                                  entry.key + 1; // 1-based indexing
                              final dayName = entry.value;
                              final schedule =
                                  organizedSchedules[dayIndex]?[timeSlot];

                              return DataCell(
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(
                                    minWidth: 120,
                                  ),
                                  child: schedule != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              schedule.subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (schedule.faculty != null &&
                                                schedule.faculty!.isNotEmpty)
                                              Text(
                                                schedule.faculty!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getNextHour(String time) {
    try {
      final hour = int.parse(time.split(':')[0]);
      final nextHour = (hour + 1) % 24;
      return '${nextHour.toString().padLeft(2, '0')}:00';
    } catch (e) {
      return '??';
    }
  }
}
