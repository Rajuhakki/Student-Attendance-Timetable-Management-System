# Gemini API Key Setup

To enable Gemini AI-powered timetable analysis, you need to configure your Gemini API key.

## Steps to Configure:

1. **Get a Gemini API Key:**
   - Go to [Google AI Studio](https://aistudio.google.com/)
   - Create a new API key or use an existing one

2. **Configure the API Key:**
   - Open `lib/config/api_config.dart`
   - Replace `'YOUR_GEMINI_API_KEY'` with your actual API key:
   ```dart
   static const String geminiApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

3. **Save and Run:**
   - Save the file
   - Run the app and test the timetable upload feature

## How It Works:

1. When you upload a timetable photo, the app first performs OCR to extract text
2. The extracted text is then sent to Gemini AI for analysis
3. Gemini AI converts the text into a structured JSON timetable
4. The timetable is displayed in a table format below the upload section
5. The analyzed timetable is stored in the database and persists until removed

## Fallback:

If the API key is not configured or if there are any issues with Gemini AI, the app will fall back to using simulated timetable data.