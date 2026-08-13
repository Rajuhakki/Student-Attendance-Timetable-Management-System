import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/database_helper.dart';

class AttendanceProvider with ChangeNotifier {
  List<Attendance> _attendances = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Attendance> get attendances => _attendances;

  Future<void> addAttendance(Attendance attendance) async {
    final id = await _dbHelper.insertClassAttendance(attendance);
    final newAttendance = Attendance(
      id: id,
      classroom: attendance.classroom,
      studentCount: attendance.studentCount,
      timestamp: attendance.timestamp,
      facultyName: attendance.facultyName,
    );
    _attendances.add(newAttendance);
    notifyListeners();
  }

  Future<void> loadAllAttendances() async {
    _attendances = await _dbHelper.getAllClassAttendance();
    notifyListeners();
  }

  Future<void> loadAttendancesByClassroom(String classroom) async {
    _attendances = await _dbHelper.getClassAttendanceByClassroom(classroom);
    notifyListeners();
  }

  Future<void> loadAttendancesByDate(DateTime date) async {
    // Convert DateTime to String in YYYY-MM-DD format
    final dateString = date.toIso8601String().split('T')[0];
    _attendances = await _dbHelper.getClassAttendanceByDate(dateString);
    notifyListeners();
  }

  Future<void> loadAttendancesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Convert DateTime to String in YYYY-MM-DD format
    final startDateString = startDate.toIso8601String().split('T')[0];
    final endDateString = endDate.toIso8601String().split('T')[0];
    _attendances = await _dbHelper.getClassAttendanceByDateRange(
      startDateString,
      endDateString,
    );
    notifyListeners();
  }

  // Add method to get latest attendance for a specific classroom
  Future<Attendance?> getLatestAttendanceForClass(String classroom) async {
    return await _dbHelper.getLatestAttendanceForClass(classroom);
  }
}
