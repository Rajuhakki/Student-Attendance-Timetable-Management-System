import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/attendance.dart';
import '../models/database_helper.dart';

class ScheduleProvider with ChangeNotifier {
  List<Schedule> _schedules = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _baseUrl = 'http://localhost:3002/api';

  List<Schedule> get schedules => _schedules;

  // Check if we're running on web
  bool get _isWeb => kIsWeb;

  Future<void> addSchedule(Schedule schedule) async {
    if (_isWeb) {
      // Use HTTP call for web platform
      try {
        print('Adding schedule via HTTP: ${schedule.toMap()}');
        final response = await http.post(
          Uri.parse('$_baseUrl/schedules'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(schedule.toMap()),
        );
        print('HTTP response status: ${response.statusCode}');
        print('HTTP response body: ${response.body}');

        if (response.statusCode == 201) {
          final jsonResponse = jsonDecode(response.body);
          // Handle the case where _id might be a string representation of ObjectId
          final idValue = jsonResponse['_id'] is String
              ? int.tryParse(jsonResponse['_id'])
              : jsonResponse['_id'] is int
              ? jsonResponse['_id']
              : null;

          final newSchedule = Schedule(
            id: idValue,
            semester: jsonResponse['semester'] ?? schedule.semester,
            className: jsonResponse['className'] ?? schedule.className,
            dayOfWeek: jsonResponse['dayOfWeek'] ?? schedule.dayOfWeek,
            startTime: jsonResponse['startTime'] ?? schedule.startTime,
            endTime: jsonResponse['endTime'] ?? schedule.endTime,
            subject: jsonResponse['subject'] ?? schedule.subject,
            faculty: jsonResponse['faculty'] ?? schedule.faculty,
          );
          _schedules.add(newSchedule);
          notifyListeners();
          print('Schedule added successfully: $newSchedule');
        } else {
          throw Exception('Failed to add schedule: ${response.statusCode}');
        }
      } catch (e) {
        print('Error adding schedule via HTTP: $e');
        rethrow;
      }
    } else {
      // Use database for non-web platforms
      final id = await _dbHelper.insertSchedule(schedule);
      final newSchedule = Schedule(
        id: id,
        semester: schedule.semester,
        className: schedule.className,
        dayOfWeek: schedule.dayOfWeek,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        subject: schedule.subject,
        faculty: schedule.faculty,
      );
      _schedules.add(newSchedule);
      notifyListeners();
    }
  }

  Future<void> loadSchedulesBySemester(int semester) async {
    if (_isWeb) {
      // Use HTTP call for web platform
      try {
        print('Loading schedules for semester: $semester');
        final response = await http.get(
          Uri.parse('$_baseUrl/schedules/semester/$semester'),
        );
        print('HTTP response status: ${response.statusCode}');
        print('HTTP response body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> jsonData = jsonDecode(response.body);
          _schedules = jsonData.map((data) {
            // Handle the case where _id might be a string representation of ObjectId
            final idValue = data['_id'] is String
                ? int.tryParse(data['_id'])
                : data['_id'] is int
                ? data['_id']
                : null;

            return Schedule(
              id: idValue,
              semester: data['semester'] ?? 0,
              className: data['className'] ?? '',
              dayOfWeek: data['dayOfWeek'] ?? 0,
              startTime: data['startTime'] ?? '',
              endTime: data['endTime'] ?? '',
              subject: data['subject'] ?? '',
              faculty: data['faculty'],
            );
          }).toList();
          notifyListeners();
          print('Loaded ${_schedules.length} schedules');
        } else {
          throw Exception('Failed to load schedules: ${response.statusCode}');
        }
      } catch (e) {
        print('Error loading schedules via HTTP: $e');
        _schedules = []; // Set to empty list on error
        notifyListeners();
        rethrow;
      }
    } else {
      // Use database for non-web platforms
      _schedules = await _dbHelper.getSchedulesBySemester(semester);
      notifyListeners();
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    if (_isWeb) {
      // Use HTTP call for web platform
      try {
        if (schedule.id == null) {
          throw Exception('Schedule ID is required for update');
        }

        final response = await http.put(
          Uri.parse('$_baseUrl/schedules/${schedule.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(schedule.toMap()),
        );

        if (response.statusCode == 200) {
          final index = _schedules.indexWhere((s) => s.id == schedule.id);
          if (index != -1) {
            _schedules[index] = schedule;
            notifyListeners();
          }
        } else {
          throw Exception('Failed to update schedule: ${response.statusCode}');
        }
      } catch (e) {
        print('Error updating schedule via HTTP: $e');
        rethrow;
      }
    } else {
      // Use database for non-web platforms
      await _dbHelper.updateSchedule(schedule);
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
        notifyListeners();
      }
    }
  }

  Future<void> deleteSchedule(int id) async {
    if (_isWeb) {
      // Use HTTP call for web platform
      try {
        final response = await http.delete(
          Uri.parse('$_baseUrl/schedules/$id'),
        );

        if (response.statusCode == 200) {
          _schedules.removeWhere((schedule) => schedule.id == id);
          notifyListeners();
        } else {
          throw Exception('Failed to delete schedule: ${response.statusCode}');
        }
      } catch (e) {
        print('Error deleting schedule via HTTP: $e');
        rethrow;
      }
    } else {
      // Use database for non-web platforms
      await _dbHelper.deleteSchedule(id);
      _schedules.removeWhere((schedule) => schedule.id == id);
      notifyListeners();
    }
  }

  Future<void> clearAllSchedulesForSemester(int semester) async {
    if (_isWeb) {
      // Use HTTP call for web platform
      try {
        final response = await http.delete(
          Uri.parse('$_baseUrl/schedules/semester/$semester'),
        );

        if (response.statusCode == 200) {
          _schedules.removeWhere((schedule) => schedule.semester == semester);
          notifyListeners();
        } else {
          throw Exception('Failed to clear schedules: ${response.statusCode}');
        }
      } catch (e) {
        print('Error clearing schedules via HTTP: $e');
        rethrow;
      }
    } else {
      // Use database for non-web platforms
      await _dbHelper.deleteAllSchedulesForSemester(semester);
      _schedules.removeWhere((schedule) => schedule.semester == semester);
      notifyListeners();
    }
  }

  // Get current schedule based on semester, class name, and current time
  Schedule? getCurrentSchedule(
    int semester,
    String className,
    DateTime currentTime,
  ) {
    final dayOfWeek = currentTime.weekday; // 1 = Monday, 7 = Sunday

    // Filter schedules for the given semester, class name, and day of week
    final filteredSchedules = _schedules.where(
      (schedule) =>
          schedule.semester == semester &&
          schedule.className == className &&
          schedule.dayOfWeek == dayOfWeek,
    );

    // Find the schedule that matches the current time
    for (final schedule in filteredSchedules) {
      // Parse start and end times
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final currentHour = currentTime.hour;
      final currentMinute = currentTime.minute;

      // Check if current time is within the schedule time range
      final isAfterStart =
          currentHour > startHour ||
          (currentHour == startHour && currentMinute >= startMinute);

      final isBeforeEnd =
          currentHour < endHour ||
          (currentHour == endHour && currentMinute <= endMinute);

      if (isAfterStart && isBeforeEnd) {
        return schedule;
      }
    }

    return null; // No current schedule found
  }
}
