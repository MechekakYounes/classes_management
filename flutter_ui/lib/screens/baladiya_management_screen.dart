import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';
import '../main.dart'; // To navigate to MainTabController
import 'login_screen.dart';
import 'dashboard_screen.dart';

class BaladiyaManagementScreen extends StatefulWidget {
  final int wilayaId;
  final String wilayaName;

  const BaladiyaManagementScreen({
    Key? key,
    required this.wilayaId,
    required this.wilayaName,
  }) : super(key: key);

  @override
  _BaladiyaManagementScreenState createState() => _BaladiyaManagementScreenState();
}

class _BaladiyaManagementScreenState extends State<BaladiyaManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _baladiyas = [];
  List<dynamic> _filteredBaladiyas = [];

  @override
  void initState() {
    super.initState();
    _loadBaladiyas();
    _searchController.addListener(_filterBaladiyas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBaladiyas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ApiService.getCommunesByWilaya(widget.wilayaId);
      setState(() {
        _baladiyas = list;
        _filteredBaladiyas = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterBaladiyas() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBaladiyas = _baladiyas;
      } else {
        _filteredBaladiyas = _baladiyas.where((item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'إضافة بلدية جديدة',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'اسم البلدية',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(context);
                try {
                  await ApiService.createCommune({
                    'name': name,
                    'wilaya_id': widget.wilayaId,
                  });
                  _loadBaladiyas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تمت إضافة البلدية بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشلت الإضافة: $e')),
                  );
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(dynamic item) {
    final controller = TextEditingController(text: item['name']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تعديل البلدية',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'اسم البلدية',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(context);
                try {
                  final id = int.parse(item['id'].toString());
                  await ApiService.updateCommune(id, {
                    'name': name,
                    'wilaya_id': widget.wilayaId,
                  });
                  _loadBaladiyas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل البلدية بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل التعديل: $e')),
                  );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(FontAwesomeIcons.triangleExclamation, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text('هل أنت متأكد من رغبتك في حذف بلدية "${item['name']}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final id = int.parse(item['id'].toString());
                  await ApiService.deleteCommune(id);
                  _loadBaladiyas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف البلدية بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الحذف: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
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
            'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
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
    final bool isUserAdmin = AuthService().isAdmin();

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: Text(
          'بلديات ولاية ${widget.wilayaName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        centerTitle: true,
        automaticallyImplyLeading: !isUserAdmin, // Hide back button for locked admin role
        actions: [
          IconButton(
            icon: const Icon(FontAwesomeIcons.rightFromBracket),
            onPressed: _handleLogout,
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('خطأ: $_error', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _loadBaladiyas,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      // Search and Action Bar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'البحث عن بلدية...',
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
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              icon: const Icon(FontAwesomeIcons.plus, color: Colors.cyan, size: 20),
                              onPressed: _showAddDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // List of Baladiyas
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadBaladiyas,
                          child: _filteredBaladiyas.isEmpty
                              ? const Center(
                                  child: Text('لا توجد بلديات مضافة', style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  itemCount: _filteredBaladiyas.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredBaladiyas[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 4,
                                      child: ListTile(
                                        onTap: () {
                                          final id = int.tryParse(item['id'].toString()) ?? 0;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DashboardScreen(communeId: id, communeName: item['name']),
                                            ),
                                          );
                                        },
                                        contentPadding: const EdgeInsets.all(16),
                                        title: Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(FontAwesomeIcons.pen, size: 18, color: Colors.teal),
                                              onPressed: () => _showEditDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(FontAwesomeIcons.trash, size: 18, color: Colors.red),
                                              onPressed: () => _confirmDelete(item),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
