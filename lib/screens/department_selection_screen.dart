import 'package:flutter/material.dart';
import 'admin_class_selection_screen.dart'; // Import the admin class selection screen
import 'faculty_department_view_screen.dart'; // Import the faculty department view screen

class DepartmentSelectionScreen extends StatefulWidget {
  final int semester;
  final bool isAdminView; // Add parameter to distinguish admin from faculty

  const DepartmentSelectionScreen({
    super.key,
    required this.semester,
    this.isAdminView = false, // Default to faculty view
  });

  @override
  State<DepartmentSelectionScreen> createState() =>
      _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen>
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
    final List<Map<String, dynamic>> departments = _getDepartments();
    _cardControllers = List.generate(departments.length, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 100)),
        vsync: this,
      );
    });

    _cardAnimations = _cardControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    }).toList();

    // Initialize icon animations
    _iconControllers = List.generate(departments.length, (index) {
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
          begin: widget.isAdminView
              ? Colors.deepPurple.shade50
              : Colors.indigo.shade50,
          end: widget.isAdminView ? Colors.purple.shade50 : Colors.blue.shade50,
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

  List<Map<String, dynamic>> _getDepartments() {
    return [
      {
        'name': 'Computer Science and Engineering',
        'icon': Icons.computer_outlined,
        'color': Colors.blue,
        'gradient': [Colors.blue.shade400, Colors.lightBlue.shade300],
      },
      {
        'name': 'Mechanical Engineering',
        'icon': Icons.settings_applications_outlined,
        'color': Colors.orange,
        'gradient': [Colors.orange.shade400, Colors.amber.shade300],
      },
      {
        'name': 'Civil Engineering',
        'icon': Icons.apartment_outlined,
        'color': Colors.green,
        'gradient': [Colors.green.shade400, Colors.lightGreen.shade300],
      },
      {
        'name': 'Artificial Intelligence',
        'icon': Icons.auto_mode_outlined,
        'color': Colors.purple,
        'gradient': [Colors.purple.shade400, Colors.pink.shade300],
      },
      {
        'name': 'Electronics and Communication Engineering',
        'icon': Icons.electrical_services_outlined,
        'color': Colors.red,
        'gradient': [Colors.red.shade400, Colors.pink.shade300],
      },
      {
        'name': 'Textile Engineering',
        'icon': Icons.checkroom_outlined,
        'color': Colors.indigo,
        'gradient': [Colors.indigo.shade400, Colors.blue.shade300],
      },
    ];
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
    final departments = _getDepartments();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdminView
              ? 'Departments - Semester ${widget.semester} (Admin)'
              : 'Departments - Semester ${widget.semester} (Faculty)',
        ),
        backgroundColor: widget.isAdminView ? Colors.deepPurple : Colors.indigo,
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
                colors: widget.isAdminView
                    ? [
                        _backgroundColorAnimation.value!,
                        Colors.purple.shade50,
                        Colors.pink.shade50,
                      ]
                    : [
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
                        widget.isAdminView
                            ? 'Please select a department to manage timetable for Semester ${widget.semester}'
                            : 'Please select a department to view current classes and record attendance for Semester ${widget.semester}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isAdminView
                              ? Colors.deepPurple
                              : Colors.indigo,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                1, // Single column for better readability
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                                3, // Wider cards for department names
                          ),
                      itemCount: departments.length,
                      itemBuilder: (context, index) {
                        final department = departments[index];
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
                              shadowColor: Colors.black.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: department['color'].withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (widget.isAdminView) {
                                    // For admin, navigate to class selection for timetable entry
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AdminClassSelectionScreen(
                                              semester: widget.semester,
                                              departmentName:
                                                  department['name'],
                                            ),
                                      ),
                                    );
                                  } else {
                                    // For faculty, navigate to department view to see current classes
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FacultyDepartmentViewScreen(
                                              semester: widget.semester,
                                              departmentName:
                                                  department['name'],
                                            ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                splashColor: department['color'].withValues(
                                  alpha: 0.2,
                                ),
                                highlightColor: department['color'].withValues(
                                  alpha: 0.1,
                                ),
                                hoverColor: department['color'].withValues(
                                  alpha: 0.05,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: department['gradient'],
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 20),
                                      ScaleTransition(
                                        scale: _iconAnimations[index],
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                          child: Icon(
                                            department['icon'],
                                            size: 36,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          department['name'],
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_outlined,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
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
