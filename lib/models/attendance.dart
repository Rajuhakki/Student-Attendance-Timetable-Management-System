class Student {
  final int? id;
  final String name;
  final int semester;
  final String className;

  Student({
    this.id,
    required this.name,
    required this.semester,
    required this.className,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'semester': semester,
      'class_name': className,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      semester: map['semester'],
      className: map['class_name'],
    );
  }
}

class Attendance {
  final int? id;
  final String classroom;
  final int studentCount;
  final DateTime timestamp;
  final String facultyName;

  Attendance({
    this.id,
    required this.classroom,
    required this.studentCount,
    required this.timestamp,
    required this.facultyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classroom': classroom,
      'student_count': studentCount,
      'timestamp': timestamp.toIso8601String(),
      'faculty_name': facultyName,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      classroom: map['classroom'],
      studentCount: map['student_count'],
      timestamp: DateTime.parse(map['timestamp']),
      facultyName: map['faculty_name'],
    );
  }
}

class Schedule {
  final int? id;
  final int semester;
  final String className;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // Format: "HH:MM"
  final String endTime; // Format: "HH:MM"
  final String subject; // Add subject field
  final String? faculty; // Add faculty field

  Schedule({
    this.id,
    required this.semester,
    required this.className,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject, // Add subject parameter
    this.faculty, // Add faculty parameter
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semester': semester,
      'className': className,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'faculty': faculty,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      semester: map['semester'],
      className: map['className'] ?? map['class_name'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? map['day_of_week'] ?? 0,
      startTime: map['startTime'] ?? map['start_time'] ?? '',
      endTime: map['endTime'] ?? map['end_time'] ?? '',
      subject: map['subject'] ?? '',
      faculty: map['faculty'],
    );
  }
}

class TimetablePhoto {
  final int? id;
  final String departmentName;
  final int semester;
  final String imagePath;
  final DateTime uploadedAt;
  final bool analyzed;
  final String? analysisResult;

  TimetablePhoto({
    this.id,
    required this.departmentName,
    required this.semester,
    required this.imagePath,
    required this.uploadedAt,
    this.analyzed = false,
    this.analysisResult,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_name': departmentName,
      'semester': semester,
      'image_path': imagePath,
      'uploaded_at': uploadedAt.toIso8601String(),
      'analyzed': analyzed ? 1 : 0,
      'analysis_result': analysisResult,
    };
  }

  factory TimetablePhoto.fromMap(Map<String, dynamic> map) {
    return TimetablePhoto(
      id: map['id'],
      departmentName: map['department_name'],
      semester: map['semester'],
      imagePath: map['image_path'],
      uploadedAt: DateTime.parse(map['uploaded_at']),
      analyzed: map['analyzed'] == 1,
      analysisResult: map['analysis_result'],
    );
  }
}
