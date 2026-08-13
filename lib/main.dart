import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Add this import for kIsWeb
import 'providers/attendance_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/timetable_photo_provider.dart';
import 'screens/admin_passkey_screen.dart';
import 'screens/home_screen.dart'; // Import home screen
import 'services/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: "assets/.env");

  // Check if we're running on web
  print('Checking if running on web...');
  print('kIsWeb result: $kIsWeb');
  if (!kIsWeb) {
    // Initialize MongoDB service only on non-web platforms
    print('Initializing MongoDB service on non-web platform');
    final mongoService = MongoDbService();
    await mongoService.init();
  } else {
    print('Skipping MongoDB initialization on web platform');
  }

  // Initialize database factory for FFI
  // Check if we're running on the web
  if (kIsWeb) {
    // For web, we'll use a different approach
    // Database functionality will be limited on web
    print('Running on web platform - using limited database functionality');
  } else {
    // Only initialize sqflite for non-web platforms
    print('Running on non-web platform - initializing sqflite');
    try {
      // Import sqflite_common_ffi only when not on web
      // This is a workaround since conditional imports don't work in main()
    } catch (e) {
      // Handle the case where sqflite is not available
      print('Error initializing sqflite: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AttendanceProvider()),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => TimetablePhotoProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          secondary: Colors.deepPurpleAccent,
          tertiary: Colors.blueAccent,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          labelStyle: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.indigo.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 4,
          shadowColor: Colors.black26,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const HomeScreen(), // Use HomeScreen as the home
      routes: {'/admin': (context) => const AdminPasskeyScreen()},
    );
  }
}
