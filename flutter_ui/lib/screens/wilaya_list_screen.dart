import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/wilayas.dart';
import '../auth_service.dart';
import 'login_screen.dart';
import 'baladiya_management_screen.dart';

class WilayaListScreen extends StatefulWidget {
  const WilayaListScreen({Key? key}) : super(key: key);

  @override
  _WilayaListScreenState createState() => _WilayaListScreenState();
}

class _WilayaListScreenState extends State<WilayaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MapEntry<int, String>> _filteredWilayas = [];

  @override
  void initState() {
    super.initState();
    _filteredWilayas = algerianWilayas.entries.toList();
    _searchController.addListener(_filterWilayas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterWilayas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredWilayas = algerianWilayas.entries.toList();
      } else {
        _filteredWilayas = algerianWilayas.entries.where((entry) {
          final numberStr = entry.key.toString();
          final name = entry.value.toLowerCase();
          return numberStr.contains(query) || name.contains(query);
        }).toList();
      }
    });
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Text(
                'تأكيد الخروج',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من نظام إدارة الصفوف؟',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await AuthService().logout();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل الخروج بنجاح', style: GoogleFonts.poppins()),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade500),
              child: const Text('تسجيل خروج'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Matches ScaffoldBackgroundColor
      appBar: AppBar(
        title: Text(
          'قائمة الولايات',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.rightFromBracket),
            onPressed: _handleLogout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن ولاية بالاسم أو الرقم...',
                prefixIcon: const Icon(FontAwesomeIcons.search, color: Colors.cyan, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(FontAwesomeIcons.xmark, color: Colors.blueGrey.shade700, size: 18),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.cyan, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Grid layout of Wilayas
            Expanded(
              child: _filteredWilayas.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _filteredWilayas.length,
                      itemBuilder: (context, index) {
                        final entry = _filteredWilayas[index];
                        final wilayaNum = entry.key.toString().padLeft(2, '0');
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BaladiyaManagementScreen(
                                    wilayaId: entry.key,
                                    wilayaName: entry.value,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.cyan.shade100,
                                    radius: 20,
                                    child: Text(
                                      wilayaNum,
                                      style: TextStyle(
                                        color: Colors.cyan.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    entry.value,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
