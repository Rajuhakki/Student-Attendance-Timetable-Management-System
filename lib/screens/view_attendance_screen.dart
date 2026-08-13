import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen>
    with TickerProviderStateMixin {
  late AttendanceProvider _attendanceProvider;
  String _filterOption = 'all';
  final TextEditingController _classroomFilterController =
      TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late AnimationController _filterController;
  late Animation<double> _filterAnimation;
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;
  late AnimationController _listController;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _attendanceProvider = Provider.of<AttendanceProvider>(
      context,
      listen: false,
    );
    _attendanceProvider.loadAllAttendances();

    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    );

    // Filter animation
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.easeInOut,
    );

    // List animation
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _listAnimation = CurvedAnimation(
      parent: _listController,
      curve: Curves.easeInOut,
    );

    // Background color animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _backgroundColorAnimation =
        ColorTween(
          begin: Colors.deepPurple.shade50,
          end: Colors.purple.shade50,
        ).animate(
          CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
        );

    // Start animations
    _headerController.forward();
    _filterController.forward();
    _listController.forward();
  }

  void _refreshData() {
    switch (_filterOption) {
      case 'all':
        _attendanceProvider.loadAllAttendances();
        break;
      case 'classroom':
        if (_classroomFilterController.text.isNotEmpty) {
          _attendanceProvider.loadAttendancesByClassroom(
            _classroomFilterController.text,
          );
        }
        break;
      case 'today':
        _attendanceProvider.loadAttendancesByDate(DateTime.now());
        break;
      case 'date_range':
        if (_startDate != null && _endDate != null) {
          _attendanceProvider.loadAttendancesByDateRange(
            _startDate!,
            _endDate!,
          );
        }
        break;
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
      });
      _refreshData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
      });
      _refreshData();
    }
  }

  @override
  void dispose() {
    _classroomFilterController.dispose();
    _headerController.dispose();
    _filterController.dispose();
    _listController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColorAnimation.value!,
                  Colors.purple.shade50,
                  Colors.pink.shade50,
                ],
              ),
            ),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _headerAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.3),
                      end: Offset.zero,
                    ).animate(_headerController),
                    child: Card(
                      margin: const EdgeInsets.all(16.0),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.deepPurple.shade200,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _filterOption,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.view_list,
                                              size: 20,
                                              color: Colors.deepPurple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('All Records'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'classroom',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.meeting_room_outlined,
                                              size: 20,
                                              color: Colors.deepPurple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('By Classroom'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'today',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.today_outlined,
                                              size: 20,
                                              color: Colors.deepPurple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Today\'s Records'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'date_range',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.date_range_outlined,
                                              size: 20,
                                              color: Colors.deepPurple,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Date Range'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _filterOption = value!;
                                        _refreshData();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Filter Options',
                                      labelStyle: const TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.deepPurple,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh_outlined,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: _refreshData,
                                  style:
                                      IconButton.styleFrom(
                                        backgroundColor: Colors.deepPurple
                                            .withValues(alpha: 0.1),
                                        padding: const EdgeInsets.all(14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ).copyWith(
                                        overlayColor:
                                            WidgetStateProperty.resolveWith<
                                              Color?
                                            >((Set<WidgetState> states) {
                                              if (states.contains(
                                                WidgetState.hovered,
                                              )) {
                                                return Colors.deepPurple
                                                    .withValues(alpha: 0.1);
                                              }
                                              if (states.contains(
                                                    WidgetState.focused,
                                                  ) ||
                                                  states.contains(
                                                    WidgetState.pressed,
                                                  )) {
                                                return Colors.deepPurple
                                                    .withValues(alpha: 0.2);
                                              }
                                              return null;
                                            }),
                                      ),
                                ),
                              ],
                            ),
                            if (_filterOption == 'classroom')
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: TextField(
                                  controller: _classroomFilterController,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Enter classroom (e.g., Sem 1 - Class A)',
                                    labelStyle: const TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.deepPurple.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.deepPurple.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.deepPurple,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.meeting_room_outlined,
                                      color: Colors.deepPurple.shade400,
                                    ),
                                  ),
                                  onSubmitted: (_) => _refreshData(),
                                ),
                              ),
                            if (_filterOption == 'date_range')
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectStartDate,
                                        borderRadius: BorderRadius.circular(16),
                                        splashColor: Colors.deepPurple
                                            .withValues(alpha: 0.1),
                                        highlightColor: Colors.deepPurple
                                            .withValues(alpha: 0.05),
                                        hoverColor: Colors.deepPurple
                                            .withValues(alpha: 0.05),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'Start Date',
                                            labelStyle: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.deepPurple.shade200,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.deepPurple.shade200,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.deepPurple,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.calendar_today_outlined,
                                              color: Colors.deepPurple.shade400,
                                            ),
                                          ),
                                          child: Text(
                                            _startDate == null
                                                ? 'Select start date'
                                                : DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(_startDate!),
                                            style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _selectEndDate,
                                        borderRadius: BorderRadius.circular(16),
                                        splashColor: Colors.deepPurple
                                            .withValues(alpha: 0.1),
                                        highlightColor: Colors.deepPurple
                                            .withValues(alpha: 0.05),
                                        hoverColor: Colors.deepPurple
                                            .withValues(alpha: 0.05),
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText: 'End Date',
                                            labelStyle: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.deepPurple.shade200,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color:
                                                    Colors.deepPurple.shade200,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide(
                                                color: Colors.deepPurple,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.calendar_today_outlined,
                                              color: Colors.deepPurple.shade400,
                                            ),
                                          ),
                                          child: Text(
                                            _endDate == null
                                                ? 'Select end date'
                                                : DateFormat(
                                                    'MMM dd, yyyy',
                                                  ).format(_endDate!),
                                            style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(thickness: 1, color: Colors.deepPurple),
                Expanded(
                  child: Consumer<AttendanceProvider>(
                    builder: (context, attendanceProvider, child) {
                      final attendances = attendanceProvider.attendances;

                      if (attendances.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.deepPurple.shade100,
                                ),
                                child: Icon(
                                  Icons.info_outlined,
                                  size: 60,
                                  color: Colors.deepPurple.shade400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No attendance records found',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Faculty attendance records will appear here once submitted',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return FadeTransition(
                        opacity: _listAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_listController),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: attendances.length,
                            itemBuilder: (context, index) {
                              final attendance = attendances[index];

                              // Different colors for different attendance cards
                              final colors = [
                                Colors.blue,
                                Colors.teal,
                                Colors.green,
                                Colors.orange,
                                Colors.purple,
                                Colors.pink,
                              ];
                              final color = colors[index % colors.length];

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.only(bottom: 20.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: color.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.meeting_room_outlined,
                                                color: color.shade700,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                attendance.classroom,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: color.shade800,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: color.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                '${attendance.studentCount} students',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: color.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 20,
                                              color: color.shade500,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              attendance.facultyName,
                                              style: TextStyle(
                                                color: color.shade700,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 20,
                                              color: color.shade500,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(attendance.timestamp),
                                              style: TextStyle(
                                                color: color.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
