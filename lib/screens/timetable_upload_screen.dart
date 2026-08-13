import 'package:flutter/material.dart';
import 'unified_timetable_screen.dart';

class TimetableUploadScreen extends StatelessWidget {
  final int semester;
  final String departmentName;
  final VoidCallback? onTimetableAnalyzed;

  const TimetableUploadScreen({
    super.key,
    required this.semester,
    required this.departmentName,
    this.onTimetableAnalyzed,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedTimetableScreen(
      semester: semester,
      departmentName: departmentName,
    );
  }
}