import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../components/app_drawer.dart';
import '../service/api_service.dart';
import 'chat_scree.dart';
import 'journal_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String currentChatId = Uuid().v4();
  String chatTitle = "New Conversation";
  List<Map<String, String>> chatMessages = [];
  List<Map<String, dynamic>> conversations = [];
  List<Map<String, dynamic>> journalEntries = [];
  Map<String, dynamic> settings = {
    "user_type": "Regular",
    "disability_type": null,
    "system_prompt": "You are a helpful assistant with memory of past conversations. Respond empathetically, adapting to the user's emotional state. Give professional and accurate responses."
  };
  Set<String> expandedEntries = {};
  File? uploadedImage;
  Map<String, String> tempAnalysis = {};
  Map<String, String> entryAnalysis = {};
  Set<String> analyzedEntries = {};
  bool showDeleteConfirmation = false;
  bool isLoading = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPersistentData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatMessages.isEmpty) {
        setState(() {
          chatMessages.add({
            'user': '',
            'assistant': _generateGreeting()
          });
        });
      }
    });
  }

  String _generateGreeting() {
    final greetings = [
      "Hello! I'm here to assist you today. What's on your mind?",
      "Hi there! Ready to chat or explore your thoughts?",
      "Welcome! I'm your assistant. How can I help you now?",
      "Hey! Excited to talk with you. What's up?"
    ];
    return greetings[DateTime.now().millisecond % greetings.length];
  }

  void _loadPersistentData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedChatId = prefs.getString('currentChatId') ?? Uuid().v4();
      print('Loading persistent data with chatId: $savedChatId');

      final convs = await apiService.getChats();
      print('Received conversations: $convs');

      final entries = await apiService.getJournalEntries();
      final savedSettings = await apiService.getSettings();

      setState(() {
        currentChatId = savedChatId;
        conversations = List<Map<String, dynamic>>.from(convs['conversations'] ?? []);
        journalEntries = entries.cast<Map<String, dynamic>>();
        settings = savedSettings;
        isLoading = false;
      });
      print('State updated with ${conversations.length} conversations');
    } catch (e) {
      setState(() => isLoading = false);
      print('Error in _loadPersistentData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data. Please check your internet connection and try again.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadPersistentData,
          ),
        ),
      );
    }
  }

  void _saveCurrentChatId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentChatId', currentChatId);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void createNewChat() async {
    setState(() => isLoading = true);
    try {
      final result = await apiService.createChat();
      setState(() {
        currentChatId = result['chat_id'] ?? Uuid().v4();
        chatTitle = result['conversation']['title'] ?? "New Conversation";
        chatMessages = [{
          'user': '',
          'assistant': _generateGreeting()
        }];
        uploadedImage = null;
        conversations.add(Map<String, dynamic>.from(result['conversation']));
        isLoading = false;
      });
      _saveCurrentChatId();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating chat: $e')));
    }
  }

  void loadChat(String chatId) async {
    setState(() => isLoading = true);
    try {
      final result = await apiService.getChat(chatId);
      setState(() {
        currentChatId = chatId;
        chatTitle = result['conversation']['title'] ?? "Conversation";
        chatMessages = (result['conversation']['messages'] as List? ?? []).map((m) {
          return {
            'user': m['user']?.toString() ?? '',
            'assistant': m['assistant']?.toString() ?? ''
          };
        }).toList();
        if (chatMessages.isEmpty) {
          chatMessages.add({
            'user': '',
            'assistant': _generateGreeting()
          });
        }
        uploadedImage = null;
        isLoading = false;
      });
      _saveCurrentChatId();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = [
      ChatScreen(
        currentChatId: currentChatId,
        chatTitle: chatTitle,
        chatMessages: chatMessages,
        uploadedImage: uploadedImage,
        isLoading: isLoading,
        onMessageSent: (String message, File? image) async {
          setState(() {
            isLoading = true;
            if (message.isNotEmpty) {
              chatMessages.add({'user': message});
            }
            if (image != null) {
              chatMessages.add({'user': '[Image uploaded]'});
            }
          });

          try {
            final result = await apiService.sendMessage(currentChatId, message.isEmpty ? '[Image]' : message, image);
            print('Solac response received: ${result['response']}');

            setState(() {
              chatMessages.add({
                'assistant': result['response']?.toString() ?? 'Solac: No response received'
              });

              if (chatMessages.length <= 3 && message.isNotEmpty) {
                chatTitle = message.length > 30 ? message.substring(0, 30) + "..." : message;
              }

              bool found = false;
              for (var conv in conversations) {
                if (conv['id'] == currentChatId) {
                  conv['title'] = chatTitle;
                  conv['messages'].add({
                    'user': message.isEmpty ? '[Image]' : message,
                    'assistant': result['response']?.toString() ?? ''
                  });
                  conv['timestamp'] = DateTime.now().toIso8601String();
                  found = true;
                  break;
                }
              }

              if (!found) {
                conversations.add({
                  'id': currentChatId,
                  'title': chatTitle,
                  'messages': [
                    {'user': message.isEmpty ? '[Image]' : message, 'assistant': result['response']?.toString() ?? ''}
                  ],
                  'timestamp': DateTime.now().toIso8601String()
                });
              }

              uploadedImage = null;
              isLoading = false;
            });
          } catch (e) {
            print('Error fetching Solac response: $e');
            setState(() {
              chatMessages.add({
                'assistant': 'Error: Could not get response from Solac'
              });
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sending message to Solac: $e')),
            );
          }
        },
        onImagePicked: (File? file) {
          setState(() {
            uploadedImage = file;
          });
        },
      ),
      JournalScreen(
        journalEntries: journalEntries,
        expandedEntries: expandedEntries,
        tempAnalysis: tempAnalysis,
        entryAnalysis: entryAnalysis,
        analyzedEntries: analyzedEntries,
        isLoading: isLoading,
        onSaveEntry: (String entry, {String? analysis}) async {
          setState(() => isLoading = true);
          try {
            final entryData = await apiService.createJournalEntry(entry);
            setState(() {
              journalEntries.add({
                'id': entryData['id'] ?? Uuid().v4(),
                'content': entryData['content'] ?? entry,
                'date': entryData['date'] ?? DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                'time': entryData['time'] ?? DateFormat('HH:mm').format(DateTime.now()),
                'timestamp': entryData['timestamp'] ?? DateTime.now().toIso8601String(),
                'emotion_analysis': analysis,
              });
              tempAnalysis.clear();
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Journal entry saved!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving entry: $e')));
          }
        },
        onDeleteEntry: (String entryId) async {
          setState(() => isLoading = true);
          try {
            await apiService.deleteJournalEntry(entryId);
            setState(() {
              journalEntries.removeWhere((entry) => entry['id'] == entryId);
              expandedEntries.remove(entryId);
              entryAnalysis.remove(entryId);
              analyzedEntries.remove(entryId);
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Journal entry deleted!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
          }
        },
        onToggleExpansion: (String entryId) {
          setState(() {
            if (expandedEntries.contains(entryId)) {
              expandedEntries.remove(entryId);
            } else {
              expandedEntries.add(entryId);
            }
          });
        },
        onToggleAll: (bool expand) {
          setState(() {
            if (expand) {
              expandedEntries = journalEntries.map((e) => e['id'] as String).toSet();
            } else {
              expandedEntries.clear();
            }
          });
        },
        onUpdateEntry: (String entryId, String newContent) async {
          setState(() => isLoading = true);
          try {
            final updatedEntry = await apiService.updateJournalEntry(entryId, newContent, null);
            setState(() {
              for (var entry in journalEntries) {
                if (entry['id'] == entryId) {
                  entry['content'] = updatedEntry['content'] ?? newContent;
                  entry['last_edited'] = updatedEntry['last_edited'] ?? DateTime.now().toIso8601String();
                  break;
                }
              }
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Journal entry updated!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating entry: $e')));
          }
        },
        onAnalyze: (String text) async {
          setState(() => isLoading = true);
          try {
            final analysis = await apiService.analyzeJournalEntry(text);
            setState(() {
              tempAnalysis['latest'] = analysis;
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis completed!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error analyzing entry: $e')));
          }
        },
        onAnalyzeEntry: (String entryId, String text) async {
          setState(() => isLoading = true);
          try {
            final analysis = await apiService.analyzeJournalEntry(text);
            if (analysis.isNotEmpty) {
              setState(() {
                entryAnalysis[entryId] = analysis;
                analyzedEntries.add(entryId);
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entry analysis completed!')));
            } else {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis returned empty result')));
            }
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error analyzing entry: $e')));
          }
        },
        onSaveAnalysis: (String entryId, String analysis) async {
          setState(() => isLoading = true);
          try {
            final updatedEntry = await apiService.updateJournalEntry(
                entryId, journalEntries.firstWhere((e) => e['id'] == entryId)['content'], analysis);
            setState(() {
              for (var entry in journalEntries) {
                if (entry['id'] == entryId) {
                  entry['emotion_analysis'] = updatedEntry['emotion_analysis'] ?? analysis;
                  break;
                }
              }
              entryAnalysis.remove(entryId);
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis saved!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving analysis: $e')));
          }
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(

          ),
        ),
        title: Text('Solac', style: GoogleFonts.poppins()),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        conversations: conversations,
        settings: settings,
        onNewChat: createNewChat,
        onLoadChat: loadChat,
        onSettingsChanged: (Map<String, dynamic> newSettings) async {
          setState(() => isLoading = true);
          try {
            final updatedSettings = await apiService.updateSettings(newSettings);
            setState(() {
              settings = updatedSettings;
              isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Settings updated!')));
          } catch (e) {
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating settings: $e')));
          }
        },
        onDeleteAllMemories: () {
          setState(() {
            showDeleteConfirmation = true;
          });
        }, onSelectScreen: _onItemTapped,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF212121), Color(0xFF3F51B5).withOpacity(0.2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
              ),
            ),
          if (showDeleteConfirmation)
            AlertDialog(
              title: Text('Confirm Delete All Memories'),
              content: Text('Are you sure you want to delete all memories? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      showDeleteConfirmation = false;
                    });
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() => isLoading = true);
                    try {
                      await apiService.deleteAllMemories();
                      setState(() {
                        conversations.clear();
                        journalEntries.clear();
                        chatMessages.clear();
                        expandedEntries.clear();
                        tempAnalysis.clear();
                        entryAnalysis.clear();
                        analyzedEntries.clear();
                        showDeleteConfirmation = false;
                        isLoading = false;
                        chatMessages.add({
                          'user': '',
                          'assistant': _generateGreeting()
                        });
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('All memories deleted successfully!')),
                      );
                    } catch (e) {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting memories: $e')));
                    }
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),

    );
  }
}