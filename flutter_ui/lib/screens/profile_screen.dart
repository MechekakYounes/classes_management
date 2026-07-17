import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart' show ApiService;
import 'login_screen.dart';
import '../auth_service.dart' show AuthService;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.triangleExclamation,
                color: Colors.red.shade400,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of the Class Manager application?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: ()async {
                Navigator.of(context).pop();
                final success = await AuthService().logout();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout Succeeded.'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApiConfigDialog() {
    final TextEditingController urlController = TextEditingController(
      text:"${ApiService.baseUrl}",
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                FontAwesomeIcons.server,
                color: Colors.cyan,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Server Configuration',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modify the Laravel API Server base URL for network communication:',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueGrey.shade700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  labelStyle: const TextStyle(color: Colors.cyan),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.cyan, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newUrl = urlController.text.trim();
                if (newUrl.isNotEmpty) {
                  setState(() {
                    ApiService.baseUrl = newUrl;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('API Base URL updated successfully to: $newUrl'),
                      backgroundColor: Colors.teal.shade600,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'French', 'Arabic'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Select Language',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: GoogleFonts.poppins(fontSize: 15)),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: Colors.cyan,
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedLanguage = value;
                    });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language switched to $value'),
                        backgroundColor: Colors.cyan.shade600,
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Light cyan background
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Professional Profile Header Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.cyan.shade600,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.cyan.shade100,
                        child: Text(
                          'AD',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'System Administrator',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'admin@classmanager.local',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // SECTION: Preferences
                  _buildSectionHeader('PREFERENCES'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.globe, color: Colors.cyan, size: 20),
                          title: Text('Language', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedLanguage,
                                style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                          onTap: _showLanguageDialog,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(FontAwesomeIcons.solidMoon, color: Colors.cyan, size: 20),
                          title: Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                          value: _darkMode,
                          activeColor: Colors.cyan,
                          onChanged: (bool value) {
                            setState(() {
                              _darkMode = value;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(FontAwesomeIcons.solidBell, color: Colors.cyan, size: 20),
                          title: Text('Notifications', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                          value: _notificationsEnabled,
                          activeColor: Colors.cyan,
                          onChanged: (bool value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // SECTION: Server Configuration
                  _buildSectionHeader('API CONFIGURATION'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(FontAwesomeIcons.server, color: Colors.cyan, size: 20),
                      title: Text('API Server Base URL', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text(
                        ApiService.baseUrl,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.edit, size: 16, color: Colors.cyan),
                      onTap: _showApiConfigDialog,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION: About & App Info
                  _buildSectionHeader('ABOUT'),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.info, color: Colors.cyan, size: 20),
                          title: Text('App Version', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                          trailing: Text('1.0.0 (Build 1)', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14)),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(FontAwesomeIcons.shieldHalved, color: Colors.cyan, size: 20),
                          title: Text('Privacy Policy', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(FontAwesomeIcons.rightFromBracket, size: 18),
                      label: Text(
                        'LOGOUT',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
