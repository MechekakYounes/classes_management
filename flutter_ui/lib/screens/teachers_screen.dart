import 'package:flutter/material.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'teacher_filter_dialog.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({Key? key}) : super(key: key);

  @override
  _TeachersScreenState createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> teachers = [];
  List<dynamic> filteredTeachers = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();

  int? _filterWilayaId;
  int? _filterCommuneId;
  int? _filterClassId;
  int? _filterGroupId;

  String _sortBy = 'name_asc';

  @override
  void initState() {
    super.initState();
    _setupRoleBasedFilters();
    _refreshTeachers();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupRoleBasedFilters() {
    final auth = AuthService();
    if (auth.isAdmin()) {
      _filterWilayaId = auth.wilayaId;
    } else if (auth.isSupervisor()) {
      _filterCommuneId = auth.communeId;
      _filterWilayaId = auth.wilayaId;
    } else if (auth.isManager() || auth.isTeacher()) {
      _filterClassId = auth.classId;
      _filterCommuneId = auth.communeId;
      _filterWilayaId = auth.wilayaId;
    }
  }

  String get headerText {
    final auth = AuthService();
    if (auth.isSuperAdmin()) return 'All Teachers Nationwide';
    if (auth.isAdmin()) return 'Teachers in ${auth.wilayaName ?? "Wilaya"}';
    if (auth.isSupervisor()) return 'Teachers in Baladiya';
    if (auth.isManager()) return 'Teachers in ${auth.user?['class']?['name'] ?? "School"}';
    return 'My Teachers';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshTeachers() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final fetchedTeachers = await ApiService.getTeachers(
        wilayaId: _filterWilayaId,
        communeId: _filterCommuneId,
        classId: _filterClassId,
        groupId: _filterGroupId,
      );
      setState(() {
        teachers = fetchedTeachers;
        filteredTeachers = List.from(teachers);
        _applySorting();
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredTeachers = teachers.where((teacher) {
        final name = "${teacher['name']} ${teacher['username']}".toLowerCase();
        return name.contains(query);
      }).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    filteredTeachers.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();

      switch (_sortBy) {
        case 'name_asc':
          return nameA.compareTo(nameB);
        case 'name_desc':
          return nameB.compareTo(nameA);
        default:
          return 0;
      }
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sort Teachers', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Name (A-Z)'),
              trailing: _sortBy == 'name_asc' ? Icon(Icons.check, color: Colors.cyan) : null,
              onTap: () {
                setState(() => _sortBy = 'name_asc');
                _applySorting();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Name (Z-A)'),
              trailing: _sortBy == 'name_desc' ? Icon(Icons.check, color: Colors.cyan) : null,
              onTap: () {
                setState(() => _sortBy = 'name_desc');
                _applySorting();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TeacherFilterDialog(
        initialWilayaId: _filterWilayaId,
        initialCommuneId: _filterCommuneId,
        initialClassId: _filterClassId,
        initialGroupId: _filterGroupId,
      ),
    );

    if (result != null) {
      setState(() {
        _filterWilayaId = result['wilayaId'];
        _filterCommuneId = result['communeId'];
        _filterClassId = result['classId'];
        _filterGroupId = result['groupId'];
      });
      _refreshTeachers();
    }
  }

  void _showAddEditTeacherDialog({Map<String, dynamic>? teacher}) {
    final isEdit = teacher != null;
    final _nameController = TextEditingController(text: teacher?['name'] ?? '');
    final _usernameController = TextEditingController(text: teacher?['username'] ?? '');
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController(text: teacher?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              isEdit ? 'تعديل بيانات المعلم' : 'إضافة معلم جديد',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan.shade800),
            ),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(_nameController, 'الاسم الكامل *', icon: FontAwesomeIcons.user),
                  _buildDialogTextField(_usernameController, 'اسم المستخدم *', icon: FontAwesomeIcons.at),
                  _buildDialogTextField(
                    _passwordController,
                    isEdit ? 'كلمة المرور (اترك فارغاً لعدم التغيير)' : 'كلمة المرور *',
                    icon: FontAwesomeIcons.lock,
                    obscureText: true,
                  ),
                  _buildDialogTextField(_phoneController, 'رقم الهاتف (اختياري)', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isEdit ? 'حفظ' : 'إنشاء الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (_usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى إدخال اسم المستخدم')));
                  return;
                }
                if (!isEdit && _passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى إدخال كلمة المرور')));
                  return;
                }

                final data = <String, dynamic>{
                  'name':     _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : _usernameController.text.trim(),
                  'username': _usernameController.text.trim(),
                  'phone':    _phoneController.text.trim(),
                };
                if (_passwordController.text.trim().isNotEmpty) {
                  data['password'] = _passwordController.text.trim();
                }

                try {
                  if (isEdit) {
                    await ApiService.updateTeacher(teacher!['id'], data);
                  } else {
                    await ApiService.createTeacher(data);
                  }
                  _refreshTeachers();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTeacher(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تأكيد الحذف', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف هذا المعلم؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(child: Text('إلغاء'), onPressed: () => Navigator.pop(ctx, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteTeacher(id);
        _refreshTeachers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }

  Widget _buildDialogTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.cyan, size: 18) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: Text(
          headerText,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : RefreshIndicator(
                  onRefresh: _refreshTeachers,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search teachers...',
                                  prefixIcon: Icon(FontAwesomeIcons.search,
                                      color: Colors.cyan, size: 18),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(FontAwesomeIcons.xmark,
                                              color: Colors.blueGrey.shade700,
                                              size: 16),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              filteredTeachers = List.from(teachers);
                                              _applySorting();
                                            });
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                        color: Colors.cyan, width: 2),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: IconButton(
                                icon: Icon(
                                  FontAwesomeIcons.sliders,
                                  color: Colors.cyan,
                                  size: 20,
                                ),
                                onPressed: _showFilterDialog,
                              ),
                            ),
                            SizedBox(width: 10),
                            Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: IconButton(
                                icon: Icon(
                                  FontAwesomeIcons.arrowUpZA,
                                  color: Colors.cyan,
                                  size: 20,
                                ),
                                onPressed: _showSortDialog,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddEditTeacherDialog(),
                                icon: Icon(FontAwesomeIcons.plus, size: 16),
                                label: Text(
                                  'إضافة معلم',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyan.shade200),
                              ),
                              child: Text(
                                '${filteredTeachers.length} معلم',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.cyan.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: filteredTeachers.isEmpty
                              ? Center(
                                  child: Text('No teachers found',
                                      style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.builder(
                                  itemCount: filteredTeachers.length,
                                  itemBuilder: (context, index) {
                                    final teacher = filteredTeachers[index];
                                    final teacherName = teacher['name'] ?? 'Unknown';
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.cyan.shade100,
                                          child: Icon(FontAwesomeIcons.userTie,
                                              color: Colors.cyan.shade800),
                                        ),
                                        title: Text(teacherName,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                            "Group: ${teacher['group']?['name'] ?? 'N/A'}\nSchool: ${teacher['class']?['name'] ?? 'N/A'}"),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.pen,
                                                  color: Colors.blue, size: 20),
                                              onPressed: () =>
                                                  _showAddEditTeacherDialog(
                                                      teacher: teacher),
                                            ),
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.trash,
                                                  color: Colors.red, size: 20),
                                              onPressed: () =>
                                                  _deleteTeacher(teacher['id']),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
