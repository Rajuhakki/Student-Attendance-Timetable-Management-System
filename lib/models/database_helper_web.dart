import 'dart:async';
import 'package:flutter/foundation.dart';
import 'attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<int> insertStudent(Student student) async {
    return -1;
  }

  Future<List<Student>> getStudentsByClass(int semester, String className) async {
    return [];
  }

  Future<void> deleteAllStudents() async {}

  Future<int> insertAttendance(Attendance attendance) async {
    return -1;
  }

  Future<List<Attendance>> getAttendanceByStudent(int studentId) async {
    return [];
  }

  Future<List<Attendance>> getAllAttendance() async {
    return [];
  }

  Future<List<Attendance>> getAttendanceByClassroom(String classroom) async {
    return [];
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    return [];
  }

  Future<List<Attendance>> getAttendanceByClassAndDate(int semester, String className, String date) async {
    return [];
  }

  Future<void> deleteAllAttendance() async {}

  Future<int> insertClassAttendance(Attendance attendance) async {
    return -1;
  }

  Future<List<Attendance>> getAllClassAttendance() async {
    return [];
  }

  Future<List<Attendance>> getClassAttendanceByClassroom(String classroom) async {
    return [];
  }

  Future<List<Attendance>> getClassAttendanceByDate(String date) async {
    return [];
  }

  Future<List<Attendance>> getClassAttendanceByDateRange(String startDate, String endDate) async {
    return [];
  }

  Future<Attendance?> getLatestAttendanceForClass(String classroom) async {
    return null;
  }

  Future<void> deleteAllClassAttendance() async {}

  Future<int> insertSchedule(Schedule schedule) async {
    return -1;
  }

  Future<List<Schedule>> getSchedulesBySemester(int semester) async {
    return [];
  }

  Future<void> updateSchedule(Schedule schedule) async {}

  Future<void> deleteSchedule(int id) async {}

  Future<void> deleteAllSchedulesForSemester(int semester) async {}

  Future<int> insertTimetablePhoto(TimetablePhoto timetablePhoto) async {
    return -1;
  }

  Future<List<TimetablePhoto>> getTimetablePhotosByDepartment(String departmentName, int semester) async {
    return [];
  }

  Future<List<TimetablePhoto>> getAllTimetablePhotos() async {
    return [];
  }

  Future<void> updateTimetablePhoto(TimetablePhoto timetablePhoto) async {}

  Future<void> deleteTimetablePhoto(int id) async {}

  bool _isWeb() {
    return kIsWeb;
  }
}
