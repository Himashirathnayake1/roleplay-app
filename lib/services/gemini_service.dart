import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final String roleContext;

  GeminiService({required this.roleContext}) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception(
        'GEMINI_API_KEY not found in .env file. '
        'Please add your API key from https://aistudio.google.com/app/apikey',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );

    // Start chat with role context as first system message
    _chat = _model.startChat(history: [
      Content.text(roleContext),
      Content.model([TextPart('Understood. I will act according to this role.')]),
    ]);
  }

  /// Send a message and get AI response
  Future<String> sendMessage(String message) async {
    try {
      final content = Content.text(message);
      final response = await _chat.sendMessage(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }

  /// Send a message and get streaming response
  Stream<String> sendMessageStream(String message) async* {
    try {
      final content = Content.text(message);
      final response = _chat.sendMessageStream(content);

      await for (final chunk in response) {
        if (chunk.text != null && chunk.text!.isNotEmpty) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      throw Exception('Failed to get streaming response from Gemini: $e');
    }
  }

  /// Reset the conversation history
  void resetConversation() {
    _chat = _model.startChat(history: []);
  }
}
