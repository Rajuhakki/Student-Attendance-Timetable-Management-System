# Campus Coordinates Configuration

To configure the GPS location verification for check-in, you need to update the campus coordinates in the [record_attendance_screen.dart](file:///c%3A/Users/rajuh/html2/demo/lib/screens/record_attendance_screen.dart) file.

## Location Settings

In the [_RecordAttendanceScreenState](file:///c%3A/Users/rajuh/html2/demo/lib/screens/record_attendance_screen.dart#L14-L136) class, locate these constants:

```dart
static const double COLLEGE_LATITUDE = 12.9716; // Example latitude
static const double COLLEGE_LONGITUDE = 77.5946; // Example longitude
static const double ALLOWED_RADIUS_METERS = 1000.0; // 1km radius
```

## How to Configure

1. Replace `COLLEGE_LATITUDE` and `COLLEGE_LONGITUDE` with the actual coordinates of your college campus center
2. Adjust `ALLOWED_RADIUS_METERS` to define how far from the center point users can be to check in
3. Test the functionality to ensure it works correctly for your campus boundaries

## Finding Coordinates

You can find the coordinates of your campus using:
- Google Maps (right-click on the campus center and select "What's here?")
- Other mapping services that provide coordinates

## Testing

During testing, you can temporarily increase the radius to make testing easier, but remember to set it back to the appropriate value for production use.