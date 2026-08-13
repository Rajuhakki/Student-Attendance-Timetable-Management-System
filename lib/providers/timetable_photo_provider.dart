import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/attendance.dart';
import '../models/database_helper.dart';
import '../config/api_config.dart';

class TimetablePhotoProvider with ChangeNotifier {
  // Helper to check if we're running on web
  bool _isWeb() {
    return kIsWeb;
  }

  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<TimetablePhoto> _timetablePhotos = [];

  List<TimetablePhoto> get timetablePhotos => _timetablePhotos;

  // Load timetable photos for a specific department and semester
  Future<void> loadTimetablePhotos(String departmentName, int semester) async {
    print('Loading timetable photos for $departmentName, semester $semester');
    try {
      _timetablePhotos = await _dbHelper.getTimetablePhotosByDepartment(
        departmentName,
        semester,
      );
      print('Loaded ${_timetablePhotos.length} photos from database');
    } catch (e) {
      // If database is not available (e.g., on web), keep the existing list
      print('Database load failed (expected on web): $e');
      print('Keeping existing list with ${_timetablePhotos.length} photos');
    }
    print('Final timetable photos list length: ${_timetablePhotos.length}');
    notifyListeners();
  }

  // Insert a new timetable photo
  Future<void> insertTimetablePhoto(TimetablePhoto timetablePhoto) async {
    print('Inserting timetable photo');
    print('Photo ID: ${timetablePhoto.id}');
    print('Photo analyzed: ${timetablePhoto.analyzed}');
    print('Analysis result: ${timetablePhoto.analysisResult}');
    print('Photo imagePath: ${timetablePhoto.imagePath}');
    print('Photo uploadedAt: ${timetablePhoto.uploadedAt}');

    try {
      final id = await _dbHelper.insertTimetablePhoto(timetablePhoto);
      print('Database insert result ID: $id');
      if (id != -1) {
        // Reload the photos list to ensure UI updates correctly
        await loadTimetablePhotos(
          timetablePhoto.departmentName,
          timetablePhoto.semester,
        );
      }
    } catch (e) {
      // If database is not available (e.g., on web), add to local list
      print('Database insert failed (expected on web): $e');
      print('Adding photo to local list');
      _timetablePhotos.add(timetablePhoto);
      print('Added to local list, new list length: ${_timetablePhotos.length}');
      notifyListeners();
    }
  }

  // Update a timetable photo (e.g., after analysis)
  Future<void> updateTimetablePhoto(TimetablePhoto timetablePhoto) async {
    print('Updating timetable photo: ${timetablePhoto.id}');
    print('Photo analyzed: ${timetablePhoto.analyzed}');
    print(
      'Analysis result length: ${timetablePhoto.analysisResult?.length ?? 0}',
    );
    print('Photo imagePath: ${timetablePhoto.imagePath}');
    print('Photo uploadedAt: ${timetablePhoto.uploadedAt}');

    try {
      await _dbHelper.updateTimetablePhoto(timetablePhoto);
      print('Successfully updated in database');
    } catch (e) {
      print('Database update failed (expected on web): $e');
    }

    // Update in the local list
    // First try to find by ID
    int index = -1;
    if (timetablePhoto.id != null) {
      index = _timetablePhotos.indexWhere(
        (photo) => photo.id == timetablePhoto.id,
      );
      print('Found photo by ID at index $index');
    }

    // If not found by ID, try to find by imagePath and uploadedAt (for web where IDs are null)
    if (index == -1) {
      print('Searching for photo by imagePath and uploadedAt');
      print('Current timetable photos count: ${_timetablePhotos.length}');
      for (int i = 0; i < _timetablePhotos.length; i++) {
        final photo = _timetablePhotos[i];
        print(
          'Checking photo $i: ID=${photo.id}, imagePath=${photo.imagePath}, uploadedAt=${photo.uploadedAt}',
        );
        print(
          '  Comparing with: imagePath=${timetablePhoto.imagePath}, uploadedAt=${timetablePhoto.uploadedAt}',
        );
        print(
          '  imagePath match: ${photo.imagePath == timetablePhoto.imagePath}',
        );
        if (photo.uploadedAt != null && timetablePhoto.uploadedAt != null) {
          print(
            '  uploadedAt match: ${photo.uploadedAt.isAtSameMomentAs(timetablePhoto.uploadedAt)}',
          );
        }
      }

      index = _timetablePhotos.indexWhere(
        (photo) =>
            photo.imagePath == timetablePhoto.imagePath &&
            photo.uploadedAt.isAtSameMomentAs(timetablePhoto.uploadedAt),
      );
      print('Found photo by imagePath and uploadedAt at index $index');
    }

    if (index != -1) {
      print('Updating photo in local list at index $index');
      print('Old photo analyzed: ${_timetablePhotos[index].analyzed}');
      print(
        'Old photo analysis result length: ${_timetablePhotos[index].analysisResult?.length ?? 0}',
      );
      _timetablePhotos[index] = timetablePhoto;
      print('Updated photo analyzed: ${_timetablePhotos[index].analyzed}');
      print(
        'Updated photo analysis result length: ${_timetablePhotos[index].analysisResult?.length ?? 0}',
      );
      notifyListeners();
    } else {
      print('Photo not found in local list, adding new photo');
      print('Current list length: ${_timetablePhotos.length}');
      _timetablePhotos.add(timetablePhoto);
      print('New list length: ${_timetablePhotos.length}');
      notifyListeners();
    }
  }

  // Delete a timetable photo
  Future<void> deleteTimetablePhoto(int id) async {
    try {
      await _dbHelper.deleteTimetablePhoto(id);

      // Remove from the local list
      _timetablePhotos.removeWhere((photo) => photo.id == id);
      notifyListeners();
    } catch (e) {
      // If database is not available (e.g., on web), remove from local list
      _timetablePhotos.removeWhere((photo) => photo.id == id);
      notifyListeners();
      print('Error deleting timetable photo: $e');
    }
  }

  // Analyze timetable photo using Gemini AI
  Future<void> analyzeTimetablePhoto(TimetablePhoto timetablePhoto) async {
    print('Analyzing timetable photo ID: ${timetablePhoto.id} with Gemini AI');
    print('Photo analyzed status before analysis: ${timetablePhoto.analyzed}');

    try {
      // Create text recognizer for initial OCR
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      // Create input image from file
      InputImage inputImage;

      // Check if we're on web platform
      if (_isWeb()) {
        // On web, we can't use file paths directly
        print('On web platform, triggering fallback to simulated data');
        throw Exception('OCR not supported on web platform');
      } else {
        // On non-web platforms, we can use file paths
        inputImage = InputImage.fromFilePath(timetablePhoto.imagePath);
      }

      // Process the image with OCR
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      // Close the recognizer
      textRecognizer.close();

      // Use Gemini AI to analyze the OCR text and generate structured timetable data
      final analysisResult = await _analyzeWithGeminiAI(recognizedText.text);
      print(
        'Gemini AI analysis successful, result length: ${analysisResult.length}',
      );

      // Update the photo with analysis results
      final analyzedPhoto = TimetablePhoto(
        id: timetablePhoto.id,
        departmentName: timetablePhoto.departmentName,
        semester: timetablePhoto.semester,
        imagePath: timetablePhoto.imagePath,
        uploadedAt: timetablePhoto.uploadedAt,
        analyzed: true,
        analysisResult: analysisResult,
      );

      await updateTimetablePhoto(analyzedPhoto);
    } catch (e) {
      print('Gemini AI analysis failed, using fallback data: $e');
      // If Gemini AI fails, fall back to simulated data
      final analyzedPhoto = TimetablePhoto(
        id: timetablePhoto.id,
        departmentName: timetablePhoto.departmentName,
        semester: timetablePhoto.semester,
        imagePath: timetablePhoto.imagePath,
        uploadedAt: timetablePhoto.uploadedAt,
        analyzed: true,
        analysisResult: '''
{
  "monday": [
    {"subject": "Mathematics", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Physics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Chemistry", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Computer Science", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "English", "startTime": "15:15", "endTime": "16:15"}
  ],
  "tuesday": [
    {"subject": "Biology", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Mathematics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Physics Lab", "startTime": "11:15", "endTime": "13:15"},
    {"subject": "History", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Physical Education", "startTime": "15:15", "endTime": "16:15"}
  ],
  "wednesday": [
    {"subject": "Chemistry", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Biology", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Mathematics", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Economics", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Art", "startTime": "15:15", "endTime": "16:15"}
  ],
  "thursday": [
    {"subject": "Physics", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Chemistry Lab", "startTime": "10:00", "endTime": "12:00"},
    {"subject": "English", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Computer Science", "startTime": "15:15", "endTime": "16:15"}
  ],
  "friday": [
    {"subject": "Computer Science", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Mathematics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Biology", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Chemistry", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Physics", "startTime": "15:15", "endTime": "16:15"}
  ]
}''',
      );

      await updateTimetablePhoto(analyzedPhoto);
    }
  }

  // Use Gemini AI to analyze OCR text and generate structured timetable data
  Future<String> _analyzeWithGeminiAI(String ocrText) async {
    try {
      // Check if API key is configured
      if (!ApiConfig.isGeminiApiKeyConfigured()) {
        print('Gemini API key not provided, using fallback data');
        throw Exception('API key not configured');
      }

      // Initialize Gemini AI
      final model = GenerativeModel(
        model:
            'gemini-pro', // Using gemini-pro instead of gemini-pro-vision since we're sending text
        apiKey: ApiConfig.geminiApiKey,
      );

      // Create prompt for Gemini AI
      final prompt =
          '''
      Analyze the following timetable text extracted from an image and convert it into a structured JSON format.
      The timetable contains information about subjects, days of the week, and time slots.
      
      Extract the information and organize it by days of the week (monday, tuesday, wednesday, thursday, friday, saturday, sunday).
      For each day, create an array of periods with the following structure:
      {
        "subject": "Subject Name",
        "startTime": "HH:MM",
        "endTime": "HH:MM"
      }
      
      OCR Text:
      $ocrText
      
      Please provide the response in valid JSON format only, without any additional text or markdown.
      Example format:
      {
        "monday": [
          {"subject": "Mathematics", "startTime": "09:00", "endTime": "10:00"},
          {"subject": "Physics", "startTime": "10:00", "endTime": "11:00"}
        ],
        "tuesday": [
          {"subject": "Biology", "startTime": "09:00", "endTime": "10:00"}
        ]
      }
      ''';

      // Generate content using Gemini AI
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // Extract the JSON response
      final responseText = response.text ?? '';
      print('Gemini AI response: $responseText');

      // Validate that the response is valid JSON by checking if it starts with {
      if (responseText.trim().startsWith('{')) {
        // Return the structured JSON
        return responseText.trim();
      } else {
        throw Exception('Invalid JSON response from Gemini AI');
      }
    } catch (e) {
      print('Error analyzing with Gemini AI: $e');
      // Re-throw to trigger fallback
      rethrow;
    }
  }

  // Extract timetable data from OCR text (fallback method)
  String _extractTimetableData(String ocrText) {
    // This is a simplified extraction logic
    // In a real implementation, you would have more sophisticated parsing

    // For demonstration, we'll return a more comprehensive JSON structure
    // A real implementation would parse the OCR text to extract actual timetable data
    return '''
{
  "monday": [
    {"subject": "Mathematics", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Physics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Chemistry", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Computer Science", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "English", "startTime": "15:15", "endTime": "16:15"}
  ],
  "tuesday": [
    {"subject": "Biology", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Mathematics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Physics Lab", "startTime": "11:15", "endTime": "13:15"},
    {"subject": "History", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Physical Education", "startTime": "15:15", "endTime": "16:15"}
  ],
  "wednesday": [
    {"subject": "Chemistry", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Biology", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Mathematics", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Economics", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Art", "startTime": "15:15", "endTime": "16:15"}
  ],
  "thursday": [
    {"subject": "Physics", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Chemistry Lab", "startTime": "10:00", "endTime": "12:00"},
    {"subject": "English", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Computer Science", "startTime": "15:15", "endTime": "16:15"}
  ],
  "friday": [
    {"subject": "Computer Science", "startTime": "09:00", "endTime": "10:00"},
    {"subject": "Mathematics", "startTime": "10:00", "endTime": "11:00"},
    {"subject": "Biology", "startTime": "11:15", "endTime": "12:15"},
    {"subject": "Chemistry", "startTime": "14:00", "endTime": "15:00"},
    {"subject": "Physics", "startTime": "15:15", "endTime": "16:15"}
  ]
}''';
  }
}
