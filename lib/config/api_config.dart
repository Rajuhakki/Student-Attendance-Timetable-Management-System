class ApiConfig {
  // Gemini API key provided by user
  static const String geminiApiKey = 'AIzaSyBwr9SsPBDaEE2VzJ1Ssf33kobXY2OTmwc';

  // Helper method to check if API key is configured
  static bool isGeminiApiKeyConfigured() {
    return geminiApiKey.isNotEmpty && geminiApiKey != 'YOUR_GEMINI_API_KEY';
  }
}
