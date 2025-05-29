import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> conversations;
  final Map<String, dynamic> settings;
  final Function onNewChat;
  final Function(String) onLoadChat;
  final Function(Map<String, dynamic>) onSettingsChanged;
  final Function onDeleteAllMemories;
  final Function(int) onSelectScreen; // New callback to update _selectedIndex

  const AppDrawer({
    required this.conversations,
    required this.settings,
    required this.onNewChat,
    required this.onLoadChat,
    required this.onSettingsChanged,
    required this.onDeleteAllMemories,
    required this.onSelectScreen,
    Key? key,
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late String userType;
  String? disabilityType;
  late String systemPrompt;
  final Map<String, String> disabilityTemplates = {
    "Autism Spectrum Disorder (ASD)":
    "You are an assistant specially designed to support individuals with Autism Spectrum Disorder (ASD). Be clear, direct, and avoid abstract language or idioms. Be patient with repetitive questions. Understand that the user may have sensory sensitivities and difficulty with social cues. Make responses dynamic and human-like. If the user seems overwhelmed, suggest a break or change of topic.",
    "ADHD":
    "You are an assistant specially designed to support individuals with Attention Deficit Hyperactivity Disorder (ADHD). Keep responses concise and to the point. Break complex information into smaller, manageable chunks. Use bullet points and lists when appropriate. Be understanding of potential topic shifts and help the user stay on track. Avoid overwhelming the user with too much information at once. Celebrate small wins and be encouraging.",
    "Dyslexia":
    "You are an assistant specially designed to support individuals with Dyslexia. Use simple, clear language and avoid jargon. Present information in short paragraphs with generous spacing. Avoid complex sentence structures. Use numbered lists for instructions or multi-step processes. Be patient if the user makes spelling mistakes or reading errors.",
    "Speech Delay":
    "You are an assistant specially designed to support individuals with Speech Delay. Use simple, direct language. Ask one question at a time. Be patient and give the user time to respond. Avoid correcting errors directly - instead model correct language use. Encourage communication in any form. Celebrate attempts at communication."
  };

  @override
  void initState() {
    super.initState();
    userType = widget.settings['user_type'] ?? "Regular";
    disabilityType = widget.settings['disability_type'];
    systemPrompt = widget.settings['system_prompt'] ??
        "You are a helpful assistant with memory of past conversations. Respond empathetically, adapting to the user's emotional state. Give professional and accurate responses.";
  }

  @override
  Widget build(BuildContext context) {
    var sortedConvs = List<Map<String, dynamic>>.from(widget.conversations)
      ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    return Drawer(
      backgroundColor: Color(0xFF212121).withOpacity(0.95),
      child: ListView(
        padding: EdgeInsets.zero,
        physics: BouncingScrollPhysics(),
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF212121), Color(0xFF3F51B5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Solac',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your personal AI companion',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.add, color: Color(0xFF2196F3)),
            title: Text('New Chat',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            onTap: () {
              widget.onNewChat();
              Navigator.pop(context);
            },
          ),
          Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'CHAT HISTORY',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...sortedConvs.map((conv) {
            String title = conv['title'];
            if (conv['messages'].isNotEmpty && title == "New Conversation") {
              title = conv['messages'][0]['user'].length > 30
                  ? conv['messages'][0]['user'].substring(0, 30) + "..."
                  : conv['messages'][0]['user'];
            }
            return ListTile(
              leading:
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white70),
              title: Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                widget.onLoadChat(conv['id']);
                Navigator.pop(context);
              },
            );
          }).toList(),
          if (sortedConvs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No chat history yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'USER SETTINGS',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Type',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    borderRadius: BorderRadius.circular(12),
                    value: userType,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: ['Regular', 'Specially Abled', 'Personalized']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(value, style: TextStyle(color: Colors.white)),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        userType = newValue!;
                        if (userType != 'Specially Abled') {
                          disabilityType = null;
                        }
                        Map<String, dynamic> newSettings =
                        Map.from(widget.settings);
                        newSettings['user_type'] = userType;
                        newSettings['disability_type'] = disabilityType;
                        widget.onSettingsChanged(newSettings);
                      });
                    },
                    dropdownColor: Color(0xFF424242),
                    style: TextStyle(color: Colors.white),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          if (userType == 'Specially Abled')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disability Type',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  SizedBox(height: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF424242),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: disabilityType,
                      isExpanded: true,
                      underline: SizedBox(),
                      hint: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Select Disability Type',
                            style: TextStyle(color: Colors.white70)),
                      ),
                      items: disabilityTemplates.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(value, style: TextStyle(color: Colors.white)),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          disabilityType = newValue;
                          Map<String, dynamic> newSettings =
                          Map.from(widget.settings);
                          newSettings['disability_type'] = disabilityType;
                          newSettings['system_prompt'] =
                          disabilityTemplates[disabilityType]!;
                          widget.onSettingsChanged(newSettings);
                        });
                      },
                      dropdownColor: Color(0xFF424242),
                      style: TextStyle(color: Colors.white),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ExpansionTile(
            title: Text('System Prompt',
                style:
                TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            iconColor: Colors.white70,
            collapsedIconColor: Colors.white70,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Customize System Prompt',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  controller: TextEditingController(text: systemPrompt),
                  onChanged: (value) {
                    systemPrompt = value;
                  },
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Map<String, dynamic> newSettings = Map.from(widget.settings);
                    newSettings['system_prompt'] = systemPrompt;
                    widget.onSettingsChanged(newSettings);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('System prompt updated!')),
                    );
                  },
                  child: Text('Save System Prompt'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
          Divider(height: 1, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'MEMORY MANAGEMENT',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.delete_outline, size: 20),
              label: Text('Delete All Memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                widget.onDeleteAllMemories();
                Navigator.pop(context);
              },
            ),
          ),
          Divider(height: 20, color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.chat_bubble_outline, size: 20, color: Colors.white),
                  label: Text(
                    'Chat',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF424242),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onSelectScreen(0); // Update _selectedIndex to 0
                    Navigator.pop(context);
                    // Navigation handled by MainScreen's _widgetOptions
                  },
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.book_outlined, size: 20, color: Colors.white),
                  label: Text(
                    'Journal',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF424242),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    widget.onSelectScreen(1); // Update _selectedIndex to 1
                    Navigator.pop(context);
                    // Navigation handled by MainScreen's _widgetOptions
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}