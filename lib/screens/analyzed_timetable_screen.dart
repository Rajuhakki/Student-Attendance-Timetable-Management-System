import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/attendance.dart';

class AnalyzedTimetableScreen extends StatelessWidget {
  final TimetablePhoto timetablePhoto;

  const AnalyzedTimetableScreen({super.key, required this.timetablePhoto});

  @override
  Widget build(BuildContext context) {
    print('Building AnalyzedTimetableScreen');
    print('Timetable photo ID: ${timetablePhoto.id}');
    print('Timetable photo analyzed: ${timetablePhoto.analyzed}');
    print(
      'Timetable photo analysis result type: ${timetablePhoto.analysisResult.runtimeType}',
    );
    print(
      'Timetable photo analysis result is null: ${timetablePhoto.analysisResult == null}',
    );
    if (timetablePhoto.analysisResult != null) {
      print(
        'Timetable photo analysis result length: ${timetablePhoto.analysisResult!.length}',
      );
      final previewLength = timetablePhoto.analysisResult!.length < 100
          ? timetablePhoto.analysisResult!.length
          : 100;
      print(
        'Timetable photo analysis result preview: ${timetablePhoto.analysisResult!.substring(0, previewLength)}',
      );
    }

    // Parse the analysis result
    Map<String, dynamic> analysisData = {};
    if (timetablePhoto.analysisResult != null &&
        timetablePhoto.analysisResult!.isNotEmpty) {
      try {
        print('Raw analysis result: ${timetablePhoto.analysisResult}');
        // Remove any extra whitespace or newlines that might be causing issues
        final cleanedResult = timetablePhoto.analysisResult!.trim();
        print('Cleaned analysis result: $cleanedResult');
        analysisData = json.decode(cleanedResult);
        print('Parsed analysis data type: ${analysisData.runtimeType}');
        print('Parsed analysis data keys: ${analysisData.keys}');
        print('Parsed analysis data length: ${analysisData.length}');

        // Print details for each day
        for (var day in analysisData.keys) {
          if (analysisData[day] is List) {
            print('Day $day has ${analysisData[day].length} periods');
            for (int i = 0; i < (analysisData[day] as List).length; i++) {
              print('  Period $i: ${(analysisData[day] as List)[i]}');
            }
          } else {
            print('Day $day is not a list: ${analysisData[day]}');
          }
        }
      } catch (e, stackTrace) {
        // Handle JSON parsing error
        print('Error parsing timetable data: $e');
        print('Stack trace: $stackTrace');
        print('Raw analysis result: ${timetablePhoto.analysisResult}');
        analysisData = {};
      }
    } else {
      print('No analysis result found or empty result');
    }

    final List<String> days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final List<String> dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${timetablePhoto.departmentName} - Analyzed Timetable'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyzed Timetable',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploaded: ${timetablePhoto.uploadedAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (analysisData.isEmpty)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info, size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No analysis data available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The timetable photo has not been analyzed yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // Show raw data for debugging
                        if (timetablePhoto.analysisResult != null &&
                            timetablePhoto.analysisResult!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Raw Analysis Data:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timetablePhoto.analysisResult!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Beautiful timetable table
              Expanded(
                child: _buildTimetableTable(
                  context,
                  analysisData,
                  days,
                  dayNames,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build a beautiful timetable table
  Widget _buildTimetableTable(
    BuildContext context,
    Map<String, dynamic> analysisData,
    List<String> days,
    List<String> dayNames,
  ) {
    print('Building timetable table');
    print('Analysis data keys: ${analysisData.keys}');
    print('Analysis data length: ${analysisData.length}');
    print('Days: $days');
    print('Day names: $dayNames');

    // Find the maximum number of periods in a day to determine table rows
    int maxPeriods = 0;
    for (var day in days) {
      if (analysisData.containsKey(day) && analysisData[day] is List) {
        maxPeriods = maxPeriods > (analysisData[day] as List).length
            ? maxPeriods
            : (analysisData[day] as List).length;
        print('Day $day has ${(analysisData[day] as List).length} periods');
      } else {
        print('Day $day not found or not a list in analysis data');
      }
    }

    print('Max periods: $maxPeriods');

    // If no periods found, show a message
    if (maxPeriods == 0) {
      print('No periods found, showing empty message');
      return const Center(
        child: Text(
          'No timetable data found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    print('Building data table with $maxPeriods rows');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 16,
        headingRowColor: WidgetStatePropertyAll(
          Colors.indigo.withValues(alpha: 0.1),
        ),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
          fontSize: 16,
        ),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08);
          }
          return null; // Use default value for other states
        }),
        border: TableBorder.all(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        columns: [
          DataColumn(
            label: Container(
              padding: const EdgeInsets.all(12),
              child: const Text('Time'),
            ),
          ),
          ...dayNames.map(
            (day) => DataColumn(
              label: Container(
                padding: const EdgeInsets.all(12),
                child: Text(day),
              ),
            ),
          ),
        ],
        rows: List.generate(maxPeriods, (periodIndex) {
          print('Building row $periodIndex');
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.all(12),
                  child: _getTimeForPeriod(periodIndex),
                ),
              ),
              ...days.map((day) {
                if (analysisData.containsKey(day) &&
                    analysisData[day] is List &&
                    (analysisData[day] as List).length > periodIndex) {
                  final subject = (analysisData[day] as List)[periodIndex];
                  print('Day $day, period $periodIndex: ${subject['subject']}');
                  return DataCell(
                    Container(
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(minWidth: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['subject'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${subject['startTime'] ?? ''} - ${subject['endTime'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  print(
                    'Day $day, period $periodIndex: No data (containsKey: ${analysisData.containsKey(day)}, isList: ${analysisData[day] is List}, length: ${(analysisData[day] is List ? (analysisData[day] as List).length : 0)})',
                  );
                  return DataCell(
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: const Text('-'),
                    ),
                  );
                }
              }),
            ],
          );
        }),
      ),
    );
  }

  // Get time display for a period
  Widget _getTimeForPeriod(int periodIndex) {
    // This is a simplified time mapping
    // In a real app, you might want to extract actual times from the data
    final times = [
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
      '12:00 - 13:00',
      '13:00 - 14:00',
      '14:00 - 15:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
    ];

    if (periodIndex < times.length) {
      return Text(
        times[periodIndex],
        style: const TextStyle(fontWeight: FontWeight.w500),
      );
    }

    return Text('Period ${periodIndex + 1}');
  }
}
