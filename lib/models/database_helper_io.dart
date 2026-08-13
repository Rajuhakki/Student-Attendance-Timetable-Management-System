import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (_isWeb()) {
      throw UnsupportedError('Database not supported on web');
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'attendance.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        semester INTEGER NOT NULL,
        className TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE student_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE class_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        classroom TEXT NOT NULL,
        student_count INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        faculty_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semester INTEGER NOT NULL,
        className TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        subject TEXT NOT NULL,
        faculty TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE timetable_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_name TEXT NOT NULL,
        semester INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        uploaded_at TEXT NOT NULL,
        analyzed BOOLEAN NOT NULL DEFAULT 0,
        analysis_result TEXT
      )
    ''');

    await db.insert('students', {
      'name': 'John Doe',
      'semester': 1,
      'className': 'A',
    });
    await db.insert('students', {
      'name': 'Jane Smith',
      'semester': 1,
      'className': 'A',
    });
    await db.insert('students', {
      'name': 'Robert Johnson',
      'semester': 1,
      'className': 'B',
    });
    await db.insert('students', {
      'name': 'Emily Davis',
      'semester': 1,
      'className': 'B',
    });
    await db.insert('students', {
      'name': 'Michael Wilson',
      'semester': 2,
      'className': 'A',
    });
    await db.insert('students', {
      'name': 'Sarah Brown',
      'semester': 2,
      'className': 'A',
    });
    await db.insert('students', {
      'name': 'David Miller',
      'semester': 2,
      'className': 'B',
    });
    await db.insert('students', {
      'name': 'Lisa Taylor',
      'semester': 2,
      'className': 'B',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE schedules ADD COLUMN subject TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE class_attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          classroom TEXT NOT NULL,
          student_count INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          faculty_name TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE attendance RENAME TO student_attendance');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE timetable_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          department_name TEXT NOT NULL,
          semester INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          uploaded_at TEXT NOT NULL,
          analyzed BOOLEAN NOT NULL DEFAULT 0,
          analysis_result TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE schedules ADD COLUMN faculty TEXT');
    }
  }

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<List<Student>> getStudentsByClass(int semester, String className) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'semester = ? AND className = ?',
      whereArgs: [semester, className],
    );
    return List.generate(maps.length, (i) => Student.fromMap(maps[i]));
  }

  Future<void> deleteAllStudents() async {
    await _database?.delete('students');
  }

  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert('attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceByStudent(int studentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getAllAttendance() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('attendance');
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getAttendanceByClassroom(String classroom) async {
    final parts = classroom.split(' - ');
    if (parts.length != 2) return [];
    final semesterPart = parts[0].split(' ');
    final classPart = parts[1].split(' ');
    if (semesterPart.length < 2 || classPart.length < 2) return [];
    final semester = int.tryParse(semesterPart[1]) ?? 0;
    final className = classPart[1];
    final today = DateTime.now().toIso8601String().split('T')[0];
    return await getAttendanceByClassAndDate(semester, className, today);
  }

  Future<List<Attendance>> getAttendanceByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getAttendanceByClassAndDate(int semester, String className, String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT a.* FROM attendance a
      JOIN students s ON a.studentId = s.id
      WHERE s.semester = ? AND s.className = ? AND a.date = ?
    ''',
      [semester, className, date],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<void> deleteAllAttendance() async {
    await _database?.delete('attendance');
  }

  Future<int> insertClassAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert('class_attendance', attendance.toMap());
  }

  Future<List<Attendance>> getAllClassAttendance() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('class_attendance');
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getClassAttendanceByClassroom(String classroom) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'class_attendance',
      where: 'classroom = ?',
      whereArgs: [classroom],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getClassAttendanceByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
        SELECT * FROM class_attendance 
        WHERE date(timestamp) = ?
        ''',
      [date],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<List<Attendance>> getClassAttendanceByDateRange(String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
        SELECT * FROM class_attendance 
        WHERE DATE(timestamp) BETWEEN ? AND ?
        ORDER BY timestamp DESC
        ''',
      [startDate, endDate],
    );
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<Attendance?> getLatestAttendanceForClass(String classroom) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'class_attendance',
      where: 'classroom = ?',
      whereArgs: [classroom],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return maps.isNotEmpty ? Attendance.fromMap(maps.first) : null;
  }

  Future<void> deleteAllClassAttendance() async {
    await _database?.delete('class_attendance');
  }

  Future<int> insertSchedule(Schedule schedule) async {
    final db = await database;
    return await db.insert('schedules', schedule.toMap());
  }

  Future<List<Schedule>> getSchedulesBySemester(int semester) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'semester = ?',
      whereArgs: [semester],
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  Future<void> updateSchedule(Schedule schedule) async {
    final db = await database;
    await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> deleteSchedule(int id) async {
    final db = await database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllSchedulesForSemester(int semester) async {
    final db = await database;
    await db.delete('schedules', where: 'semester = ?', whereArgs: [semester]);
  }

  Future<int> insertTimetablePhoto(TimetablePhoto timetablePhoto) async {
    final db = await database;
    return await db.insert('timetable_photos', timetablePhoto.toMap());
  }

  Future<List<TimetablePhoto>> getTimetablePhotosByDepartment(String departmentName, int semester) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'timetable_photos',
      where: 'department_name = ? AND semester = ?',
      whereArgs: [departmentName, semester],
    );
    return List.generate(maps.length, (i) => TimetablePhoto.fromMap(maps[i]));
  }

  Future<List<TimetablePhoto>> getAllTimetablePhotos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('timetable_photos');
    return List.generate(maps.length, (i) => TimetablePhoto.fromMap(maps[i]));
  }

  Future<void> updateTimetablePhoto(TimetablePhoto timetablePhoto) async {
    final db = await database;
    await db.update(
      'timetable_photos',
      timetablePhoto.toMap(),
      where: 'id = ?',
      whereArgs: [timetablePhoto.id],
    );
  }

  Future<void> deleteTimetablePhoto(int id) async {
    final db = await database;
    await db.delete('timetable_photos', where: 'id = ?', whereArgs: [id]);
  }

  bool _isWeb() {
    return kIsWeb;
  }
}
