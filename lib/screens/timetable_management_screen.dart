import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../providers/schedule_provider.dart';
import '../providers/timetable_photo_provider.dart';
import '../models/attendance.dart';
import 'unified_timetable_screen.dart';
import 'analyzed_timetable_screen.dart';

class TimetableManagementScreen extends StatefulWidget {
  final int semester;
  final String departmentName;

  const TimetableManagementScreen({
    super.key,
    required this.semester,
    required this.departmentName,
  });

  @override
  State<TimetableManagementScreen> createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  bool _isWeb = false;
  late ScheduleProvider _scheduleProvider;
  late TimetablePhotoProvider _timetablePhotoProvider;
  bool _isLoading = false;
  List<TimetablePhoto> _timetablePhotos = [];

  // Manual entry data
  final Map<String, List<Map<String, TextEditingController>>> _manualEntries =
      {};
  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _isWeb = _checkIfWeb();
    _scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    _timetablePhotoProvider = Provider.of<TimetablePhotoProvider>(
      context,
      listen: false,
    );
    _initializeManualEntries();
    _loadTimetablePhotos();
  }

  bool _checkIfWeb() {
    try {
      return 0.0.toString().contains('e');
    } catch (e) {
      return false;
    }
  }

  void _initializeManualEntries() {
    for (var day in _daysOfWeek) {
      _manualEntries[day] = [];
      // Initialize with 8 periods per day
      for (int i = 0; i < 8; i++) {
        _manualEntries[day]!.add({
          'subject': TextEditingController(),
          'faculty': TextEditingController(), // Add faculty controller
          'startTime': TextEditingController(),
          'endTime': TextEditingController(),
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var dayEntries in _manualEntries.values) {
      for (var entry in dayEntries) {
        entry['subject']?.dispose();
        entry['faculty']?.dispose(); // Dispose faculty controller
        entry['startTime']?.dispose();
        entry['endTime']?.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _loadTimetablePhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _timetablePhotoProvider.loadTimetablePhotos(
        widget.departmentName,
        widget.semester,
      );
      _timetablePhotos = _timetablePhotoProvider.timetablePhotos;
    } catch (e) {
      print('Error loading timetable photos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = pickedImage;

          // For web, we need to read the bytes
          if (_isWeb) {
            pickedImage.readAsBytes().then((bytes) {
              setState(() {
                _webImageBytes = bytes;
              });
            });
          }
        });

        // Upload the image
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? capturedImage = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (capturedImage != null) {
        setState(() {
          _selectedImage = capturedImage;

          // For web, we need to read the bytes
          if (_isWeb) {
            capturedImage.readAsBytes().then((bytes) {
              setState(() {
                _webImageBytes = bytes;
              });
            });
          }
        });

        // Upload the image
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a TimetablePhoto object
      final timetablePhoto = TimetablePhoto(
        departmentName: widget.departmentName,
        semester: widget.semester,
        imagePath: _selectedImage!.path,
        uploadedAt: DateTime.now(),
      );

      // Save to provider
      await _timetablePhotoProvider.insertTimetablePhoto(timetablePhoto);

      // Clear the selected image
      setState(() {
        _selectedImage = null;
        _webImageBytes = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the photos
      await _loadTimetablePhotos();

      // Automatically trigger analysis for the newly uploaded photo
      // Find the newly uploaded photo (the one with the latest timestamp)
      final updatedPhotos = _timetablePhotoProvider.timetablePhotos;
      if (updatedPhotos.isNotEmpty) {
        // Sort by uploadedAt to get the most recent one
        updatedPhotos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        final latestPhoto = updatedPhotos.first;

        // Only analyze if it hasn't been analyzed yet
        if (!latestPhoto.analyzed) {
          // Small delay to ensure UI updates
          await Future.delayed(const Duration(milliseconds: 500));
          await _analyzeTimetable(latestPhoto);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeTimetable(TimetablePhoto timetablePhoto) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Analyze the timetable photo
      await _timetablePhotoProvider.analyzeTimetablePhoto(timetablePhoto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable analyzed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload the photos
      await _loadTimetablePhotos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveManualEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear existing schedules for this department and semester
      await _scheduleProvider.loadSchedulesBySemester(widget.semester);
      final existingSchedules = _scheduleProvider.schedules
          .where(
            (schedule) =>
                schedule.className == widget.departmentName &&
                schedule.semester == widget.semester,
          )
          .toList();

      for (var schedule in existingSchedules) {
        await _scheduleProvider.deleteSchedule(schedule.id!);
      }

      // Save new schedules
      for (int dayIndex = 0; dayIndex < _daysOfWeek.length; dayIndex++) {
        final day = _daysOfWeek[dayIndex];
        final dayEntries = _manualEntries[day] ?? [];

        for (
          int periodIndex = 0;
          periodIndex < dayEntries.length;
          periodIndex++
        ) {
          final entry = dayEntries[periodIndex];
          final subject = entry['subject']?.text.trim();
          final faculty = entry['faculty']?.text.trim(); // Add faculty
          final startTime = entry['startTime']?.text.trim();
          final endTime = entry['endTime']?.text.trim();

          // Only save if all required fields are filled
          if (subject!.isNotEmpty &&
              startTime!.isNotEmpty &&
              endTime!.isNotEmpty) {
            final schedule = Schedule(
              semester: widget.semester,
              className: widget.departmentName,
              dayOfWeek: dayIndex + 1, // Monday = 1, Sunday = 7
              startTime: startTime,
              endTime: endTime,
              subject: subject,
              faculty: faculty!.isNotEmpty
                  ? faculty
                  : null, // Add faculty to schedule
            );

            await _scheduleProvider.addSchedule(schedule);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving timetable: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_isWeb) {
      // On web, use the bytes we captured
      if (_webImageBytes != null) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
          ),
        );
      } else {
        return Container();
      }
    } else {
      // On non-web platforms, use Image.file
      if (_selectedImage != null) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
          ),
        );
      } else {
        return Container();
      }
    }
  }

  Widget _buildManualEntryTable() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Timetable Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 12,
                headingRowColor: WidgetStatePropertyAll(
                  Colors.indigo.withValues(alpha: 0.1),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  fontSize: 14,
                ),
                columns: [
                  const DataColumn(label: Text('Day')),
                  const DataColumn(label: Text('Period')),
                  const DataColumn(label: Text('Subject')),
                  const DataColumn(
                    label: Text('Faculty'), // Add faculty column
                  ),
                  const DataColumn(label: Text('Start Time')),
                  const DataColumn(label: Text('End Time')),
                ],
                rows: [
                  for (
                    int dayIndex = 0;
                    dayIndex < _daysOfWeek.length;
                    dayIndex++
                  )
                    for (
                      int periodIndex = 0;
                      periodIndex <
                          (_manualEntries[_daysOfWeek[dayIndex]] ?? []).length;
                      periodIndex++
                    )
                      DataRow(
                        cells: [
                          DataCell(Text(_dayNames[dayIndex])),
                          DataCell(Text('${periodIndex + 1}')),
                          DataCell(
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller:
                                    _manualEntries[_daysOfWeek[dayIndex]]![periodIndex]['subject'],
                                decoration: const InputDecoration(
                                  hintText: 'Subject',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            // Add faculty input field
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller:
                                    _manualEntries[_daysOfWeek[dayIndex]]![periodIndex]['faculty'],
                                decoration: const InputDecoration(
                                  hintText: 'Faculty',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller:
                                    _manualEntries[_daysOfWeek[dayIndex]]![periodIndex]['startTime'],
                                decoration: const InputDecoration(
                                  hintText: 'HH:MM',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller:
                                    _manualEntries[_daysOfWeek[dayIndex]]![periodIndex]['endTime'],
                                decoration: const InputDecoration(
                                  hintText: 'HH:MM',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveManualEntries,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.indigo,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          SizedBox(width: 10),
                          Text('Saving...'),
                        ],
                      )
                    : const Text(
                        'Save Timetable',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} - Timetable Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image selection section
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload Timetable Photo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload a photo of the timetable or capture one using your camera:',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _captureImage,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_selectedImage != null) ...[
                            _buildImagePreview(),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _uploadImage,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: Colors.indigo,
                                ),
                                child: const Text('Upload Image'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Existing timetable photos
                  if (_timetablePhotos.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Analyzed Timetables',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _timetablePhotos.length,
                        itemBuilder: (context, index) {
                          final photo = _timetablePhotos[index];
                          return Card(
                            margin: const EdgeInsets.only(left: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.indigo,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    photo.uploadedAt.toLocal().toString().split(
                                      ' ',
                                    )[0],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AnalyzedTimetableScreen(
                                                timetablePhoto: photo,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('View'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  // Manual entry section
                  _buildManualEntryTable(),
                ],
              ),
            ),
    );
  }
}
