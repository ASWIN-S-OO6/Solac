import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  final List<Map<String, dynamic>> journalEntries;
  final Set<String> expandedEntries;
  final Map<String, String> tempAnalysis;
  final Map<String, String> entryAnalysis;
  final Set<String> analyzedEntries;
  final bool isLoading;
  final Function(String, {String? analysis}) onSaveEntry;
  final Function(String) onDeleteEntry;
  final Function(String) onToggleExpansion;
  final Function(bool) onToggleAll;
  final Function(String, String) onUpdateEntry;
  final Function(String) onAnalyze;
  final Function(String, String) onAnalyzeEntry;
  final Function(String, String) onSaveAnalysis;

  const JournalScreen({
    required this.journalEntries,
    required this.expandedEntries,
    required this.tempAnalysis,
    required this.entryAnalysis,
    required this.analyzedEntries,
    required this.isLoading,
    required this.onSaveEntry,
    required this.onDeleteEntry,
    required this.onToggleExpansion,
    required this.onToggleAll,
    required this.onUpdateEntry,
    required this.onAnalyze,
    required this.onAnalyzeEntry,
    required this.onSaveAnalysis,
    Key? key,
  }) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryController = TextEditingController();

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    Map<String, List<Map<String, dynamic>>> groupedEntries = {};
    for (var entry in widget.journalEntries) {
      String date = entry['date'] ?? today;
      groupedEntries.putIfAbsent(date, () => []).add(entry);
    }

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Journal Entry - $today',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _entryController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write your thoughts here...',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.save, size: 18),
                          label: Text('Save'),
                          onPressed: widget.isLoading
                              ? null
                              : () {
                            if (_entryController.text.isNotEmpty) {
                              widget.onSaveEntry(_entryController.text);
                              _entryController.clear();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter some text for your journal entry.')),
                              );
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.psychology, size: 18),
                          label: Text('Analyze'),
                          onPressed: widget.isLoading
                              ? null
                              : () {
                            if (_entryController.text.isNotEmpty) {
                              widget.onAnalyze(_entryController.text);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter some text to analyze.')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    if (widget.tempAnalysis.containsKey('latest'))
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emotion Analysis (Not Saved)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.tempAnalysis['latest']!,
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: widget.isLoading
                                    ? null
                                    : () {
                                  if (_entryController.text.isNotEmpty && widget.tempAnalysis.containsKey('latest')) {
                                    widget.onSaveEntry(_entryController.text, analysis: widget.tempAnalysis['latest']);
                                    _entryController.clear();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Please analyze the entry first or ensure text is entered.')),
                                    );
                                  }
                                },
                                child: Text('Save with Analysis'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 40, thickness: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Journal History',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                    widget.onToggleAll(widget.expandedEntries.isEmpty);
                  },
                  child: Text(
                    widget.expandedEntries.isEmpty ? 'Expand All' : 'Collapse All',
                    style: TextStyle(color: Color(0xFF2196F3)),
                  ),
                ),
              ],
            ),
          ),
          ...groupedEntries.keys.toList().map((date) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Card(
                child: ExpansionTile(
                  title: Text(
                    date,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  initiallyExpanded: date == today,
                  children: groupedEntries[date]!.map((entry) {
                    String entryId = entry['id'];
                    bool isExpanded = widget.expandedEntries.contains(entryId);
                    TextEditingController entryController = TextEditingController(text: entry['content']);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        color: Color(0xFF2E2E2E),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                'Entry at ${entry['time'] ?? 'Unknown time'}',
                                style: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isExpanded ? Icons.expand_less : Icons.expand_more,
                                      color: Color(0xFF2196F3),
                                    ),
                                    onPressed: () {
                                      widget.onToggleExpansion(entryId);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red[400]),
                                    onPressed: widget.isLoading
                                        ? null
                                        : () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Confirm Delete'),
                                          content: Text('Are you sure you want to delete this entry?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                widget.onDeleteEntry(entryId);
                                                Navigator.pop(context);
                                              },
                                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: entryController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        hintText: 'Edit entry...',
                                        hintStyle: TextStyle(color: Colors.white54),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      alignment: WrapAlignment.start,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.save, size: 16),
                                          label: Text('Update'),
                                          onPressed: widget.isLoading
                                              ? null
                                              : () {
                                            if (entryController.text != entry['content']) {
                                              widget.onUpdateEntry(entryId, entryController.text);
                                            }
                                          },
                                        ),
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.psychology, size: 16),
                                          label: Text('Analyze'),
                                          onPressed: widget.isLoading
                                              ? null
                                              : () {
                                            widget.onAnalyzeEntry(entryId, entryController.text);
                                          },
                                        ),
                                      ],
                                    ),
                                    if (entry['emotion_analysis'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0),
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Saved Emotion Analysis',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                entry['emotion_analysis'],
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (widget.entryAnalysis.containsKey(entryId))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0),
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF9C27B0), Color(0xFFCE93D8)],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current Emotion Analysis (Not Saved)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                widget.entryAnalysis[entryId]!,
                                                style: TextStyle(color: Colors.white),
                                              ),
                                              SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: widget.isLoading
                                                    ? null
                                                    : () {
                                                  widget.onSaveAnalysis(entryId, widget.entryAnalysis[entryId]!);
                                                },
                                                child: Text('Save This Analysis'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (!isExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  'Preview: ${entry['content'].length > 100 ? entry['content'].substring(0, 100) + '...' : entry['content']}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
          if (groupedEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.book, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    'No journal entries yet.\nAdd your first entry above!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 140),
        ],
      ),
    );
  }
}