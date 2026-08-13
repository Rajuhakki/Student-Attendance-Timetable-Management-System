# Student Attendance Tracker

A mobile application for faculty members to record student attendance in classrooms hourly, replacing the manual system with a digital solution.

## Features

1. **Record Attendance**: Faculty can easily record the number of students present in each classroom with timestamp and faculty name.
2. **View Records**: View historical attendance data with filtering options (by classroom, by date, etc.).
3. **Secure Storage**: All attendance data is stored locally on the device using SQLite database.
4. **Real-time Access**: Administrators can access attendance records in real-time.

## Screenshots

![Home Screen](screenshots/home.png)
![Record Attendance](screenshots/record.png)
![View Records](screenshots/view.png)

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio / Xcode / VS Code

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

## Dependencies

- `sqflite`: For local database storage
- `path`: For database path management
- `intl`: For date/time formatting
- `provider`: For state management

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── attendance.dart
│   └── database_helper.dart
├── providers/
│   └── attendance_provider.dart
└── screens/
    ├── record_attendance_screen.dart
    └── view_attendance_screen.dart
```

## How It Works

1. Faculty members open the app and select "Record Attendance"
2. They enter the classroom name, number of students present, their name, and the date/time
3. The data is saved to a local SQLite database
4. Administrators can view all attendance records through the "View Attendance Records" screen
5. Records can be filtered by classroom or date for easier analysis

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any queries, please open an issue in the repository.