import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../face.dart';
import '../permission.dart';
import '../trans.dart';
import '../ts.dart';

class ChatScreen extends StatefulWidget {
  final String currentChatId;
  final String chatTitle;
  final List<Map<String, String>> chatMessages;
  final File? uploadedImage;
  final bool isLoading;
  final Function(String, File?) onMessageSent;
  final Function(File?) onImagePicked;

  const ChatScreen({
    required this.currentChatId,
    required this.chatTitle,
    required this.chatMessages,
    required this.uploadedImage,
    required this.isLoading,
    required this.onMessageSent,
    required this.onImagePicked,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String? _selectedLanguage;
  Map<int, String> _translatedMessages = {};
  Map<int, String> _faceAnalysisResults = {};
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SpeechService.init();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _scrollToBottom();
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _initSpeech() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: ${error.errorMsg}')),
        );
      },
    );
    if (available) {
      // Speech is available
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!await PermissionService.requestMicrophonePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission denied. Please enable it in settings.')),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
          }
        });
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      if (_speechEnabled && widget.chatMessages.isNotEmpty) {
        final lastMessage = widget.chatMessages.last;
        if (lastMessage['assistant']?.isNotEmpty ?? false) {
          SpeechService.speak(lastMessage['assistant']!);
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImageAndAnalyze() async {
    if (!await PermissionService.requestCameraPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      widget.onImagePicked(imageFile);
      final analysis = await FaceRecognitionService.analyzeFace(imageFile);
      setState(() {
        _faceAnalysisResults[widget.chatMessages.length] = analysis;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (!await PermissionService.requestCameraPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission denied. Please enable it in settings.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      widget.onImagePicked(File(pickedFile.path));
    }
  }

  Future<void> _translateMessage(int index, String text) async {
    if (_selectedLanguage == null) return;
    final translated = await TranslationService.translate(
      text,
      TranslationService.supportedLanguages[_selectedLanguage]!,
    );
    setState(() {
      _translatedMessages[index] = translated;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    SpeechService.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  _speechEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _speechEnabled = !_speechEnabled;
                    SpeechService.setSpeechEnabled(_speechEnabled);
                  });
                },
                tooltip: 'Toggle Speech',
              ),
              DropdownButton<String>(
                iconEnabledColor: Colors.white54,
                borderRadius: BorderRadius.circular(10),
                hint: Text('Translate', style: TextStyle(color: Colors.white)),
                value: _selectedLanguage,
                items: TranslationService.supportedLanguages.keys.map((lang) {
                  return DropdownMenuItem<String>(
                    value: lang,
                    child: Text(lang, style: TextStyle(color: Colors.white),),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value;
                    _translatedMessages.clear();
                  });
                },
                dropdownColor: Color(0xFF2E2E2E),
                style: TextStyle(color: Colors.white),
                icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
              ),
              IconButton(
                icon: Icon(Icons.face, color: Colors.white70),
                onPressed: _pickImageAndAnalyze,
                tooltip: 'Analyze Face',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.chatMessages.length,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final message = widget.chatMessages[index];
              final isUser = message['user']?.isNotEmpty ?? false;
              final hasAssistant = message['assistant']?.isNotEmpty ?? false;
              final displayText = isUser
                  ? message['user']!
                  : (hasAssistant ? message['assistant']! : 'Solac: Waiting...');

              if (!isUser && !hasAssistant && message['assistant'] == '...') {
                return SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? LinearGradient(
                              colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
                            )
                                : LinearGradient(
                              colors: [Color(0xFF2E2E2E), Color(0xFF424242)],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: isUser ? Radius.circular(12) : Radius.circular(0),
                              bottomRight: isUser ? Radius.circular(0) : Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUser ? 'You' : 'Solac',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isUser ? Colors.white70 : Colors.white60,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                _translatedMessages.containsKey(index)
                                    ? _translatedMessages[index]!
                                    : displayText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              if (!isUser && _selectedLanguage != null)
                                TextButton(
                                  onPressed: () => _translateMessage(index, displayText),
                                  child: Text(
                                    'Translate to $_selectedLanguage',
                                    style: TextStyle(color: Color(0xFF2196F3)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_faceAnalysisResults.containsKey(index))
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _faceAnalysisResults[index]!,
                              style: TextStyle(color: Color(0xFFF57C00)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.uploadedImage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color(0xFF2E2E2E),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.uploadedImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(Icons.close, size: 16, color: Colors.red),
                        onPressed: () => widget.onImagePicked(null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            color: Color(0xFF2E2E2E),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text Field at the top
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type or speak your message to Solac...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.grey[800]?.withOpacity(0.5),
                  ),
                  style: TextStyle(color: Colors.white),
                  onSubmitted: (_) {
                    if ((_controller.text.trim().isNotEmpty || widget.uploadedImage != null) && !widget.isLoading) {
                      widget.onMessageSent(_controller.text.trim(), widget.uploadedImage);
                      _controller.clear();
                    }
                  },
                ),
              ),
              SizedBox(height: 8),
              // Buttons row at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.white70),
                    onPressed: widget.isLoading ? null : _pickImageFromCamera,
                    tooltip: 'Take Photo',
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.white70,
                    ),
                    onPressed: widget.isLoading ? null : _toggleListening,
                    tooltip: 'Voice Input',
                  ),
                  Spacer(), // This will push the send button to the right
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white70),
                    onPressed: widget.isLoading
                        ? null
                        : () {
                      if (_controller.text.trim().isNotEmpty || widget.uploadedImage != null) {
                        widget.onMessageSent(_controller.text.trim(), widget.uploadedImage);
                        _controller.clear();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter a message, take a photo, or use voice input')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}