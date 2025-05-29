import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as http_io;

class ApiService {
  static const String baseUrl = 'https://699b-2405-201-e016-b1cb-4bac-f481-d786-e3d1.ngrok-free.app';

  Future<http.Client> _getHttpClient() async {
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return http_io.IOClient(httpClient);
  }

  Future<Map<String, dynamic>> getChats() async {
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        var client = await _getHttpClient();
        final url = Uri.parse('$baseUrl/chats');
        print('Fetching chats from: $url (Attempt ${attempt + 1})');

        final response = await client.get(url).timeout(Duration(seconds: 30));
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        client.close();
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        throw Exception('Failed to load chats: ${response.statusCode} - ${response.body}');
      } catch (e) {
        attempt++;
        print('Error loading chats (Attempt $attempt): $e');
        if (attempt == maxRetries) {
          throw Exception('Error loading chats after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2));
      }
    }
    throw Exception('Unexpected error in getChats');
  }

  Future<Map<String, dynamic>> createChat() async {
    try {
      var client = await _getHttpClient();
      final response = await client.post(Uri.parse('$baseUrl/chats')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to create chat: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error creating chat: $e');
      throw Exception('Error creating chat: $e');
    }
  }

  Future<Map<String, dynamic>> getChat(String chatId) async {
    try {
      var client = await _getHttpClient();
      final response = await client.get(Uri.parse('$baseUrl/chats/$chatId')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Chat not found: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error loading chat: $e');
      throw Exception('Error loading chat: $e');
    }
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, String message, File? image) async {
    try {
      var client = await _getHttpClient();
      final url = Uri.parse('$baseUrl/chats/$chatId/message');
      print('Sending message to: $url');
      print('Message: $message');
      print('Image provided: ${image != null}');

      final body = {
        'message': message,
        'chat_id': chatId,
        'base64_image': image != null ? base64Encode(await image.readAsBytes()) : null,
      };

      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));

      print('sendMessage status: ${response.statusCode}');
      print('sendMessage raw body: ${response.body}');

      client.close();
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print('sendMessage parsed: $responseBody');

        String assistantResponse;
        if (responseBody['response'] != null) {
          assistantResponse = responseBody['response'].toString();
        } else if (responseBody['assistant'] != null) {
          assistantResponse = responseBody['assistant'].toString();
        } else {
          assistantResponse = 'No valid response found';
          print('Warning: No response or assistant field in JSON');
        }

        return {
          'response': assistantResponse,
          'chat_id': responseBody['chat_id']?.toString() ?? chatId,
        };
      }
      throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Error sending message to Solac: $e');
    }
  }

  Future<List<dynamic>> getJournalEntries() async {
    try {
      var client = await _getHttpClient();
      final response = await client.get(Uri.parse('$baseUrl/journal')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['journal_entries'];
      }
      throw Exception('Failed to load journal entries: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error loading journal entries: $e');
      throw Exception('Error loading journal entries: $e');
    }
  }

  Future<Map<String, dynamic>> createJournalEntry(String content) async {
    try {
      var client = await _getHttpClient();
      final response = await client.post(
        Uri.parse('$baseUrl/journal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      ).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['entry'];
      }
      throw Exception('Failed to create journal entry: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error creating journal entry: $e');
      throw Exception('Error creating journal entry: $e');
    }
  }

  Future<String> analyzeJournalEntry(String content) async {
    try {
      var client = await _getHttpClient();
      print('Analyzing journal entry: $content');

      final response = await client.post(
        Uri.parse('$baseUrl/journal/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      ).timeout(Duration(seconds: 30));

      print('Journal analysis response: ${response.statusCode}');
      print('Journal analysis body: ${response.body}');

      client.close();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['analysis'] ?? 'No analysis available';
      }
      throw Exception('Failed to analyze journal entry: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error analyzing journal entry: $e');
      throw Exception('Error analyzing journal entry: $e');
    }
  }

  Future<Map<String, dynamic>> updateJournalEntry(String entryId, String content, String? analysis) async {
    try {
      var client = await _getHttpClient();
      final response = await client.put(
        Uri.parse('$baseUrl/journal/$entryId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': content,
          'emotion_analysis': analysis,
        }),
      ).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['entry'];
      }
      throw Exception('Failed to update journal entry: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error updating journal entry: $e');
      throw Exception('Error updating journal entry: $e');
    }
  }

  Future<void> deleteJournalEntry(String entryId) async {
    try {
      var client = await _getHttpClient();
      final response = await client.delete(Uri.parse('$baseUrl/journal/$entryId')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to delete journal entry: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting journal entry: $e');
      throw Exception('Error deleting journal entry: $e');
    }
  }

  Future<Map<String, dynamic>> getSettings() async {
    try {
      var client = await _getHttpClient();
      final response = await client.get(Uri.parse('$baseUrl/settings')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['settings'];
      }
      throw Exception('Failed to load settings: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error loading settings: $e');
      throw Exception('Error loading settings: $e');
    }
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      var client = await _getHttpClient();
      final response = await client.put(
        Uri.parse('$baseUrl/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(settings),
      ).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['settings'];
      }
      throw Exception('Failed to update settings: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Error updating settings: $e');
      throw Exception('Error updating settings: $e');
    }
  }

  Future<void> deleteAllMemories() async {
    try {
      var client = await _getHttpClient();
      final response = await client.delete(Uri.parse('$baseUrl/memory')).timeout(Duration(seconds: 15));
      client.close();
      if (response.statusCode != 200) {
        throw Exception('Failed to delete all memories: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error deleting memories: $e');
      throw Exception('Error deleting memories: $e');
    }
  }
}