import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/gemini_service_http.dart';

class ConversationMessage {
  final String text;
  final bool isUser;
  final String timestamp;

  ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ConversationScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const ConversationScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late FlutterTts flutterTts;
  late stt.SpeechToText _speechToText;
  late GeminiServiceHttp _geminiService;
  bool isSpeaking = false;
  bool isListening = false;
  bool isLoadingResponse = false;
  String recognizedText = '';

  final List<ConversationMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeechToText();
    _initGemini();

    _addMessage(
      'Hello! Welcome to our restaurant. How can I help you today?',
      isUser: false,
    );
  }

  void _initGemini() {
    try {
      _geminiService = GeminiServiceHttp(
        roleContext: widget.subtitle,
      );
    } catch (e) {
      debugPrint('Failed to initialize Gemini: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize AI: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.6);
    flutterTts.setPitch(1.2);
    flutterTts.setVolume(1.0);

    flutterTts.getVoices.then((voices) {
      if (voices != null && voices.isNotEmpty) {
        for (var voice in voices) {
          if (voice.toString().contains('female') ||
              voice.toString().contains('Female')) {
            flutterTts.setVoice({'name': voice.toString(), 'locale': 'en-US'});
            break;
          }
        }
      }
    });
  }

  void _initSpeechToText() {
    _speechToText = stt.SpeechToText();
    _initializeSpeechToText();
  }

  Future<void> _initializeSpeechToText() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) {
          debugPrint('STT Error: $error');
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
        },
      );
      if (!available) {
        debugPrint('Speech to Text not available');
      }
    } catch (e) {
      debugPrint('Failed to initialize STT: $e');
    }
  }

  Future<void> _startListening() async {
    if (isListening) {
      await _stopListening();
      return;
    }

    // Check and request microphone permission
    PermissionStatus status = await Permission.microphone.request();

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for speech recognition',
            ),
          ),
        );
      }
      return;
    }

    if (!_speechToText.isListening) {
      bool available = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Error: $error');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $error')));
          }
        },
        onStatus: (status) {
          debugPrint('Status: $status');
        },
      );

      if (available) {
        setState(() {
          isListening = true;
          recognizedText = '';
        });

        _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                recognizedText = result.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech to Text is not available on this device'),
            ),
          );
        }
      }
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();

    if (recognizedText.isNotEmpty) {
      _addMessage(recognizedText, isUser: true);
      _getAIResponse(recognizedText);
    }

    if (mounted) {
      setState(() {
        isListening = false;
      });
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    final now = DateTime.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      messages.add(
        ConversationMessage(text: text, isUser: isUser, timestamp: timeString),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() {
        isSpeaking = false;
      });
    } else {
      setState(() {
        isSpeaking = true;
      });
      await flutterTts.speak(text).then((_) {
        if (mounted) {
          setState(() {
            isSpeaking = false;
          });
        }
      });
    }
  }

  void _submitMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _addMessage(text, isUser: true);
      _textController.clear();
      setState(() {
        isListening = false;
      });
      _getAIResponse(text);
    }
  }

  Future<void> _getAIResponse(String userMessage) async {
    setState(() {
      isLoadingResponse = true;
    });

    try {
      final response = await _geminiService.sendMessage(userMessage);
      _addMessage(response, isUser: false);
      await _speak(response);
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      _addMessage(
        'Sorry, I\'m having trouble responding right now. Please try again.',
        isUser: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingResponse = false;
        });
      }
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speechToText.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMsg = message.isUser;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment:
                        isUserMsg
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Card(
                        color: isUserMsg ? Colors.blue[300] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isUserMsg
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      message.text,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            isUserMsg
                                                ? Colors.white
                                                : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!isUserMsg) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () => _speak(message.text),
                                      icon: Icon(
                                        isSpeaking
                                            ? Icons.volume_up
                                            : Icons.volume_up_outlined,
                                        color:
                                            isUserMsg
                                                ? Colors.white
                                                : Colors.black87,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message.timestamp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isUserMsg
                                          ? Colors.white70
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recognizedText.isNotEmpty)
         
         
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  isListening ? 'Listening...' : 'Tap to speak',
                  style: TextStyle(
                    fontSize: 16,
                    color: isListening ? Colors.red : Colors.grey,
                    fontWeight:
                        isListening ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? Colors.red : Colors.black,
                boxShadow: [
                  BoxShadow(
                    color:
                        isListening
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.black26,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: isListening ? _stopListening : _startListening,
                icon: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 28,
                ),
                padding: const EdgeInsets.all(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
