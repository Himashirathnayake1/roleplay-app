import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Direct HTTP implementation of Gemini API (bypasses SDK issues)
class GeminiServiceHttp {
  final String apiKey;
  final String roleContext;
  final List<Map<String, dynamic>> conversationHistory = [];

  GeminiServiceHttp({required this.roleContext})
    : apiKey = dotenv.env['GEMINI_API_KEY'] ?? '' {
    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. '
        'Please add your API key from https://aistudio.google.com/app/apikey',
      );
    }

    // Initialize with role context
    conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': roleContext},
      ],
    });
    conversationHistory.add({
      'role': 'model',
      'parts': [
        {'text': 'Understood. I will act according to this role.'},
      ],
    });
  }

  /// Send a message and get AI response using direct HTTP
  Future<String> sendMessage(String message) async {
    try {
      // Add user message to history
      conversationHistory.add({
        'role': 'user',
        'parts': [
          {'text': message},
        ],
      });

      // Use v1 API endpoint with available model
      final url =
          'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey';

      final requestBody = {
        'contents': conversationHistory,
        'generationConfig': {
          'temperature': 0.9,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;

          if (parts.isNotEmpty) {
            final responseText = parts[0]['text'] as String;

            // Add AI response to history
            conversationHistory.add({
              'role': 'model',
              'parts': [
                {'text': responseText},
              ],
            });

            return responseText;
          }
        }
        throw Exception('Empty response from Gemini API');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'API Error ${response.statusCode}: ${errorData['error']['message'] ?? response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }

  /// Reset the conversation history
  void resetConversation() {
    conversationHistory.clear();
    conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': roleContext},
      ],
    });
    conversationHistory.add({
      'role': 'model',
      'parts': [
        {'text': 'Understood. I will act according to this role.'},
      ],
    });
  }
}
