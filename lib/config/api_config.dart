/// API Configuration for GroceryMate
/// 
/// To use Claude Vision API for enhanced OCR:
/// 1. Get your API key from https://console.anthropic.com/
/// 2. Replace 'YOUR_API_KEY_HERE' with your actual key
/// 3. Keep this file secure and never commit it to public repositories
/// 
/// Note: The app will work without an API key using ML Kit fallback,
/// but Claude Vision provides better accuracy for all tag types.

class ApiConfig {
  /// Anthropic Claude API Key
  /// Get yours at: https://console.anthropic.com/
  static const String anthropicApiKey = 'YOUR_API_KEY_HERE';
  
  /// Check if API key is configured
  static bool get isClaudeVisionEnabled => 
      anthropicApiKey.isNotEmpty && 
      anthropicApiKey != 'YOUR_API_KEY_HERE';
  
  /// Claude Vision model to use
  static const String claudeModel = 'claude-sonnet-4-20250514';
  
  /// API version
  static const String anthropicVersion = '2023-06-01';
  
  /// API endpoint
  static const String anthropicEndpoint = 'https://api.anthropic.com/v1/messages';
}
