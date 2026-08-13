import 'package:flutter/material.dart';
import 'schedule_management_screen.dart'; // Import schedule management screen
import 'department_selection_screen.dart'; // Import department selection screen
import 'record_attendance_form_screen.dart'; // Import record attendance form screen

class SemesterSelectionScreen extends StatefulWidget {
  final bool isForScheduling;
  final bool
  isAdminView; // Add parameter to distinguish admin view from faculty recording

  const SemesterSelectionScreen({
    super.key,
    this.isForScheduling = false,
    this.isAdminView = false,
  });

  @override
  State<SemesterSelectionScreen> createState() =>
      _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;
  late List<AnimationController> _iconControllers;
  late List<Animation<double>> _iconAnimations;

  @override
  void initState() {
    super.initState();

    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeInOut,
    );

    // Initialize card animations
    final List<int> semesters = List.generate(8, (index) => index + 1);
    _cardControllers = List.generate(semesters.length, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      );
    });

    _cardAnimations = _cardControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    }).toList();

    // Initialize icon animations
    _iconControllers = List.generate(semesters.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
    });

    _iconAnimations = _iconControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    }).toList();

    // Background color animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _backgroundColorAnimation =
        ColorTween(
          begin: Colors.indigo.shade50,
          end: Colors.blue.shade50,
        ).animate(
          CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
        );

    // Start animations
    _headerController.forward();
    for (var controller in _cardControllers) {
      controller.forward();
    }

    // Stagger icon animations
    for (int i = 0; i < _iconControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _iconControllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> semesters = List.generate(8, (index) => index + 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isForScheduling
              ? (widget.isAdminView
                    ? 'Select Semester for Department Schedule Management'
                    : 'Select Semester for Scheduling')
              : widget.isAdminView
              ? 'Select Semester for Department View'
              : 'Select Semester for Viewing Current Classes and Recording Attendance',
        ),
        backgroundColor: Colors.indigo,
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
                  Colors.blue.shade50,
                  Colors.cyan.shade50,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _headerAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(_headerController),
                      child: Text(
                        widget.isForScheduling
                            ? (widget.isAdminView
                                  ? 'Please select a semester to manage department schedules'
                                  : 'Please select a semester to manage schedules')
                            : widget.isAdminView
                            ? 'Please select a semester to view departments'
                            : 'Please select a semester',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio:
                            1.2, // Reduced from 1.5 to give more vertical space
                      ),
                      itemCount: semesters.length,
                      itemBuilder: (context, index) {
                        final semester = semesters[index];
                        // Different colors for different semesters
                        final colors = [
                          Colors.indigo,
                          Colors.blue,
                          Colors.teal,
                          Colors.green,
                          Colors.orange,
                          Colors.deepOrange,
                          Colors.purple,
                          Colors.pink,
                        ];
                        final color = colors[index % colors.length];

                        // Different icons for different semesters
                        final icons = [
                          Icons.looks_one,
                          Icons.looks_two,
                          Icons.looks_3,
                          Icons.looks_4,
                          Icons.looks_5,
                          Icons.looks_6,
                          Icons.filter_7,
                          Icons.filter_8,
                        ];
                        final icon = icons[index % icons.length];

                        return ScaleTransition(
                          scale: _cardAnimations[index],
                          child: GestureDetector(
                            onTap: () {
                              // Add a little bounce effect when tapped
                              _cardControllers[index].reverse().then((_) {
                                _cardControllers[index].forward();
                              });
                            },
                            child: Card(
                              elevation: 8,
                              shadowColor: Colors.black.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: color.withValues(alpha: 0.1),
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (widget.isForScheduling &&
                                      widget.isAdminView) {
                                    // Navigate to department selection screen for schedule management
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DepartmentSelectionScreen(
                                              semester: semester,
                                              isAdminView: true, // Admin view
                                            ),
                                      ),
                                    );
                                  } else if (widget.isForScheduling) {
                                    // Navigate to schedule management screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ScheduleManagementScreen(
                                              semester: semester,
                                              departmentName:
                                                  'Computer Science', // Add department name
                                            ),
                                      ),
                                    );
                                  } else if (widget.isAdminView) {
                                    // Navigate to department selection screen for admin attendance viewing
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DepartmentSelectionScreen(
                                              semester: semester,
                                              isAdminView: true, // Admin view
                                            ),
                                      ),
                                    );
                                  } else {
                                    // For faculty recording attendance, go to faculty department view
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DepartmentSelectionScreen(
                                              semester: semester,
                                              isAdminView:
                                                  false, // Faculty view
                                            ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                splashColor: color.withValues(alpha: 0.2),
                                highlightColor: color.withValues(alpha: 0.1),
                                hoverColor: color.withValues(alpha: 0.05),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ScaleTransition(
                                        scale: _iconAnimations[index],
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color.withValues(alpha: 0.1),
                                          ),
                                          child: Icon(
                                            icon,
                                            size: 40,
                                            color: color.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Semester $semester',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: color.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Click to select',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: color.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
