import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/timetable_photo_provider.dart';
import '../models/attendance.dart';
import 'timetable_upload_screen.dart';
import 'analyzed_timetable_screen.dart';

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class DepartmentTimetableScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const DepartmentTimetableScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<DepartmentTimetableScreen> createState() =>
      _DepartmentTimetableScreenState();
}

class _DepartmentTimetableScreenState extends State<DepartmentTimetableScreen> {
  late ScheduleProvider _scheduleProvider;
  late TimetablePhotoProvider _timetablePhotoProvider;
  late _AppLifecycleObserver _lifecycleObserver;
  bool _isLoading = true;
  List<Schedule> _schedules = [];
  List<TimetablePhoto> _timetablePhotos = [];
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
    print(
      'Initializing DepartmentTimetableScreen for ${widget.departmentName}, semester ${widget.semester}',
    );
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _timetablePhotoProvider = Provider.of<TimetablePhotoProvider>(
      context,
      listen: false,
    );
    _lifecycleObserver = _AppLifecycleObserver(onResume: _loadData);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load schedules for this semester
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);

      // Filter schedules for this department (class name)
      _schedules = _scheduleProvider.schedules
          .where((schedule) => schedule.className == widget.departmentName)
          .toList();

      // Load timetable photos
      await _timetablePhotoProvider.loadTimetablePhotos(
        widget.departmentName,
        widget.semester,
      );
      _timetablePhotos = _timetablePhotoProvider.timetablePhotos;

      print('Loaded ${_timetablePhotos.length} timetable photos');
      for (var photo in _timetablePhotos) {
        print(
          'Photo ID: ${photo.id}, Analyzed: ${photo.analyzed}, Analysis Result: ${photo.analysisResult?.substring(0, 50)}...',
        );
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName),
        backgroundColor: _getDepartmentColor(widget.departmentName),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () async {
              // Navigate to upload screen with camera functionality
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimetableUploadScreen(
                    semester: widget.semester,
                    departmentName: widget.departmentName,
                    onTimetableAnalyzed: () {
                      // Refresh data when a new timetable is analyzed
                      _loadData();
                    },
                  ),
                ),
              );
              // Refresh data when returning from upload screen
              _loadData();
            },
            tooltip: 'Capture Timetable Photo',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimetableUploadScreen(
                    semester: widget.semester,
                    departmentName: widget.departmentName,
                    onTimetableAnalyzed: () {
                      // Refresh data when a new timetable is analyzed
                      _loadData();
                    },
                  ),
                ),
              );
              // Refresh data when returning from upload screen
              _loadData();
            },
            tooltip: 'Upload Timetable Photo',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Semester ${widget.semester}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timetable',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_schedules.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No schedules found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No timetable has been configured for this department in Semester ${widget.semester}.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildSchedulesList(),
                      const SizedBox(height: 30),
                      // Always show upload option in the content area
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TimetableUploadScreen(
                                  semester: widget.semester,
                                  departmentName: widget.departmentName,
                                  onTimetableAnalyzed: () {
                                    // Refresh data when a new timetable is analyzed
                                    _loadData();
                                  },
                                ),
                              ),
                            );
                            // Refresh data when returning from upload screen
                            _loadData();
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Timetable Photo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (_timetablePhotos.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No timetable photos uploaded',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload a timetable photo to get started',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildAnalyzedTimetable(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final dayName = schedule.dayOfWeek <= _daysOfWeek.length
            ? _daysOfWeek[schedule.dayOfWeek - 1]
            : 'Unknown';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.subject, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule.subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (schedule.faculty != null &&
                    schedule.faculty!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Faculty: ${schedule.faculty}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${schedule.startTime} - ${schedule.endTime}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyzedTimetable() {
    print(
      'Building analyzed timetable, total photos: ${_timetablePhotos.length}',
    );

    // Get the latest analyzed photo
    final analyzedPhotos = _timetablePhotos
        .where((photo) => photo.analyzed && photo.analysisResult != null)
        .toList();

    print('Found ${analyzedPhotos.length} analyzed photos');

    if (analyzedPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No analyzed timetable available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload and analyze a timetable photo to view the table',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimetableUploadScreen(
                      semester: widget.semester,
                      departmentName: widget.departmentName,
                    ),
                  ),
                );
                // Refresh data when returning from upload screen
                _loadData();
              },
              child: const Text('Upload/Analyze Timetable Photo'),
            ),
          ],
        ),
      );
    }

    // Sort by uploaded date to get the latest
    analyzedPhotos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final latestPhoto = analyzedPhotos.first;

    print(
      'Displaying latest analyzed photo with result: ${latestPhoto.analysisResult?.substring(0, 50)}...',
    );

    // Create a temporary AnalyzedTimetableScreen to reuse its table building logic
    final analyzedScreen = AnalyzedTimetableScreen(timetablePhoto: latestPhoto);

    // We'll extract the table building logic from AnalyzedTimetableScreen
    return _buildTimetableTableFromPhoto(latestPhoto);
  }

  Widget _buildTimetableTableFromPhoto(TimetablePhoto timetablePhoto) {
    // Parse the analysis result
    Map<String, dynamic> analysisData = {};
    if (timetablePhoto.analysisResult != null &&
        timetablePhoto.analysisResult!.isNotEmpty) {
      try {
        final cleanedResult = timetablePhoto.analysisResult!.trim();
        analysisData = json.decode(cleanedResult);
      } catch (e) {
        analysisData = {};
      }
    }

    final List<String> days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final List<String> dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (analysisData.isEmpty) {
      return const Center(
        child: Text(
          'No analysis data available for this timetable',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Find the maximum number of periods in a day to determine table rows
    int maxPeriods = 0;
    for (var day in days) {
      if (analysisData.containsKey(day) && analysisData[day] is List) {
        maxPeriods = maxPeriods > (analysisData[day] as List).length
            ? maxPeriods
            : (analysisData[day] as List).length;
      }
    }

    // If no periods found, show a message
    if (maxPeriods == 0) {
      return const Center(
        child: Text(
          'No timetable data found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analyzed Timetable',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowColor: WidgetStatePropertyAll(
              Colors.indigo.withValues(alpha: 0.1),
            ),
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
              fontSize: 16,
            ),
            dataRowColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08);
              }
              return null; // Use default value for other states
            }),
            border: TableBorder.all(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            columns: [
              DataColumn(
                label: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Text('Time'),
                ),
              ),
              ...dayNames.map(
                (day) => DataColumn(
                  label: Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(day),
                  ),
                ),
              ),
            ],
            rows: List.generate(maxPeriods, (periodIndex) {
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: _getTimeForPeriod(periodIndex),
                    ),
                  ),
                  ...days.map((day) {
                    if (analysisData.containsKey(day) &&
                        analysisData[day] is List &&
                        (analysisData[day] as List).length > periodIndex) {
                      final subject = (analysisData[day] as List)[periodIndex];
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(minWidth: 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject['subject'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (subject['faculty'] != null &&
                                  subject['faculty'].toString().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Faculty: ${subject['faculty']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${subject['startTime'] ?? ''} - ${subject['endTime'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: const Text('-'),
                        ),
                      );
                    }
                  }),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // Get time display for a period
  Widget _getTimeForPeriod(int periodIndex) {
    // This is a simplified time mapping
    // In a real app, you might want to extract actual times from the data
    final times = [
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
    ];

    if (periodIndex < times.length) {
      return Text(
        times[periodIndex],
        style: const TextStyle(fontWeight: FontWeight.w500),
      );
    }

    return Text('Period ${periodIndex + 1}');
  }

  Color _getDepartmentColor(String departmentName) {
    // Simple hash-based color generation for departments
    final hash = departmentName.codeUnits.reduce((a, b) => a + b);
    return Colors.primaries[hash % Colors.primaries.length];
  }
}
