import 'package:flutter/material.dart';
import 'timetable_entry_screen.dart'; // Import the timetable entry screen

class AdminClassSelectionScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const AdminClassSelectionScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<AdminClassSelectionScreen> createState() =>
      _AdminClassSelectionScreenState();
}

class _AdminClassSelectionScreenState extends State<AdminClassSelectionScreen> {
  // Track selected classes
  final Set<String> _selectedClasses = {};

  // Available classes (A to D)
  final List<String> _availableClasses = ['A', 'B', 'C', 'D'];

  void _proceedToTimetable() {
    if (_selectedClasses.isEmpty) return;

    // For now, we'll navigate to the timetable screen for the first selected class
    // In a real implementation, you might want to show timetables for all selected classes
    final firstSelectedClass = _selectedClasses.first;

    // Format the class name to match the expected format in the system
    final formattedClassName =
        '${widget.departmentName} - Class $firstSelectedClass';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimetableEntryScreen(
          semester: widget.semester,
          departmentName: formattedClassName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} - Class Selection'),
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
            Text(
              'Semester ${widget.semester} - Select Classes',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please select the classes you want to manage:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: _availableClasses.length,
                itemBuilder: (context, index) {
                  final className = _availableClasses[index];
                  final isSelected = _selectedClasses.contains(className);

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.indigo : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedClasses.remove(className);
                          } else {
                            _selectedClasses.add(className);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? Colors.indigo.withValues(alpha: 0.1)
                              : Colors.transparent,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 40,
                                color: isSelected ? Colors.indigo : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Class $className',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.indigo
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedClasses.isEmpty
                    ? null
                    : _proceedToTimetable,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
