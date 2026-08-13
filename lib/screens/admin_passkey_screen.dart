import 'package:flutter/material.dart';
import 'view_attendance_screen.dart';
import 'semester_selection_screen.dart';
import 'department_selection_screen.dart';

class AdminPasskeyScreen extends StatefulWidget {
  const AdminPasskeyScreen({super.key});

  @override
  State<AdminPasskeyScreen> createState() => _AdminPasskeyScreenState();
}

class _AdminPasskeyScreenState extends State<AdminPasskeyScreen>
    with TickerProviderStateMixin {
  final TextEditingController _passkeyController = TextEditingController();
  final String _correctPasskey = '123456';
  bool _isPasskeyVisible = false;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundColorAnimation;
  late AnimationController _floatingController;
  late Animation<Offset> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    // Card animation
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
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

    // Floating animation for the icon
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatingAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.05)).animate(
          CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
        );

    // Stagger the animations
    _iconController.forward();
    _textController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _passkeyController.dispose();
    _iconController.dispose();
    _textController.dispose();
    _cardController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _validatePasskey() {
    if (_passkeyController.text == _correctPasskey) {
      // Show options dialog with animation
      _showAdminOptions();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid passkey. Please try again.'),
          backgroundColor: Colors.deepOrangeAccent,
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAdminOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade50,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Admin Options',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Choose an option to proceed',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewAttendanceScreen(),
                      ),
                    );
                  },
                  style:
                      TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.deepPurple.withValues(alpha: 0.1);
                              }
                              return null;
                            }),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.deepPurple.withValues(alpha: 0.1);
                            }
                            if (states.contains(MaterialState.focused) ||
                                states.contains(MaterialState.pressed)) {
                              return Colors.deepPurple.withValues(alpha: 0.2);
                            }
                            return null;
                          },
                        ),
                      ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'View Attendance Records',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SemesterSelectionScreen(
                          isForScheduling: true,
                          isAdminView: true,
                        ),
                      ),
                    );
                  },
                  style:
                      TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.deepPurple.withValues(alpha: 0.1);
                              }
                              return null;
                            }),
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.hovered)) {
                              return Colors.deepPurple.withValues(alpha: 0.1);
                            }
                            if (states.contains(MaterialState.focused) ||
                                states.contains(MaterialState.pressed)) {
                              return Colors.deepPurple.withValues(alpha: 0.2);
                            }
                            return null;
                          },
                        ),
                      ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, color: Colors.deepPurple, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Manage Schedules',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Access'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Navigate back to home screen
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            tooltip: 'Logout',
            splashRadius: 24,
          ),
        ],
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SlideTransition(
                    position: _floatingAnimation,
                    child: ScaleTransition(
                      scale: _iconAnimation,
                      child: RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _iconController,
                            curve: const Interval(
                              0.0,
                              0.5,
                              curve: Curves.elasticOut,
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.deepPurple.shade100,
                            child: Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 60,
                              color: Colors.deepPurple.shade800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_textController),
                      child: const Text(
                        'Admin Access Required',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _textAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_textController),
                      child: const Text(
                        'Please enter the passkey to view attendance records',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _cardAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(_cardController),
                      child: Card(
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
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: _passkeyController,
                                obscureText: !_isPasskeyVisible,
                                decoration: InputDecoration(
                                  labelText: 'Passkey',
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
                                    Icons.key_outlined,
                                    color: Colors.deepPurple.shade400,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasskeyVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.deepPurple.shade400,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasskeyVisible = !_isPasskeyVisible;
                                      });
                                    },
                                    splashRadius: 20,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onSubmitted: (_) => _validatePasskey(),
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _validatePasskey,
                                  style:
                                      ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        backgroundColor: Colors.deepPurple,
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                      ).copyWith(
                                        overlayColor:
                                            MaterialStateProperty.resolveWith<
                                              Color?
                                            >((Set<MaterialState> states) {
                                              if (states.contains(
                                                MaterialState.hovered,
                                              )) {
                                                return Colors.white.withValues(
                                                  alpha: 0.1,
                                                );
                                              }
                                              if (states.contains(
                                                    MaterialState.focused,
                                                  ) ||
                                                  states.contains(
                                                    MaterialState.pressed,
                                                  )) {
                                                return Colors.white.withValues(
                                                  alpha: 0.2,
                                                );
                                              }
                                              return null;
                                            }),
                                      ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_open_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Access Records',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
