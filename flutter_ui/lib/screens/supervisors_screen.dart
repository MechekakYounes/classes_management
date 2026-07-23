import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'supervisor_filter_dialog.dart';

class SupervisorsScreen extends StatefulWidget {
  const SupervisorsScreen({Key? key}) : super(key: key);

  @override
  _SupervisorsScreenState createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<SupervisorsScreen> {
  List<dynamic> supervisors = [];
  List<dynamic> filteredSupervisors = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name_asc';

  // Role-based filter params (auto-applied from role)
  int? _filterWilayaId;

  // User-selected filter state
  int? _filterCommuneId;
  bool _hasActiveFilter = false;

  @override
  void initState() {
    super.initState();
    _setupRoleBasedFilters();
    _refreshSupervisors();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupRoleBasedFilters() {
    final auth = AuthService();
    if (auth.isAdmin()) {
      _filterWilayaId = auth.wilayaId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get headerText {
    final auth = AuthService();
    if (auth.isSuperAdmin()) return 'جميع المشرفين البلديين وطنياً';
    if (auth.isAdmin()) return 'المشرفون البلديون بـ ${auth.wilayaName ?? "الولاية"}';
    return 'المشرفون البلديون';
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SupervisorFilterDialog(
        initialWilayaId: _filterWilayaId,
        initialCommuneId: _filterCommuneId,
      ),
    );
    if (result != null) {
      setState(() {
        _filterWilayaId  = result['wilayaId'];
        _filterCommuneId = result['communeId'];
        _hasActiveFilter = result['wilayaId'] != null || result['communeId'] != null;
      });
      _refreshSupervisors();
    }
  }

  Future<void> _refreshSupervisors() async {
    setState(() { isLoading = true; error = null; });
    try {
      final fetched = await ApiService.getSupervisors(
        wilayaId:  _filterWilayaId,
        communeId: _filterCommuneId,
      );
      setState(() {
        supervisors = fetched;
        filteredSupervisors = List.from(supervisors);
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
      filteredSupervisors = supervisors.where((s) {
        final name = "${s['name']} ${s['username']}".toLowerCase();
        return name.contains(query);
      }).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    filteredSupervisors.sort((a, b) {
      final nameA = (a['name'] ?? '').toString().toLowerCase();
      final nameB = (b['name'] ?? '').toString().toLowerCase();
      return _sortBy == 'name_desc' ? nameB.compareTo(nameA) : nameA.compareTo(nameB);
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('ترتيب المشرفين', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('الاسم (أ-ي)'),
              trailing: _sortBy == 'name_asc' ? Icon(Icons.check, color: Colors.cyan) : null,
              onTap: () { setState(() => _sortBy = 'name_asc'); _applySorting(); Navigator.pop(context); },
            ),
            ListTile(
              title: Text('الاسم (ي-أ)'),
              trailing: _sortBy == 'name_desc' ? Icon(Icons.check, color: Colors.cyan) : null,
              onTap: () { setState(() => _sortBy = 'name_desc'); _applySorting(); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSupervisorDialog() => _showSupervisorDialog();
  void _showEditSupervisorDialog(Map<dynamic, dynamic> sup) => _showSupervisorDialog(supervisor: sup);

  void _showSupervisorDialog({Map<dynamic, dynamic>? supervisor}) async {
    final isEdit = supervisor != null;
    final _nameController = TextEditingController(text: supervisor?['name'] ?? '');
    final _usernameController = TextEditingController(text: supervisor?['username'] ?? '');
    final _passwordController = TextEditingController();
    final _phoneController = TextEditingController(text: supervisor?['phone'] ?? '');

    List<dynamic> communes = [];
    int? selectedCommuneId = supervisor?['commune_id'];
    bool isDialogLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isDialogLoading) {
              final auth = AuthService();
              ApiService.getCommunes(wilayaId: auth.wilayaId).then((list) {
                setDialogState(() { communes = list; isDialogLoading = false; });
              }).catchError((_) { setDialogState(() => isDialogLoading = false); });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Center(
                child: Text(
                  isEdit ? 'تعديل بيانات المشرف' : 'إضافة مشرف بلدي جديد',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan.shade800),
                ),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(_nameController, 'الاسم الكامل *', icon: FontAwesomeIcons.user),
                      _buildTextField(_usernameController, 'اسم المستخدم *', icon: FontAwesomeIcons.at),
                      _buildTextField(
                        _passwordController,
                        isEdit ? 'كلمة المرور (اترك فارغاً لعدم التغيير)' : 'كلمة المرور *',
                        icon: FontAwesomeIcons.lock, obscureText: true,
                      ),
                      _buildTextField(_phoneController, 'رقم الهاتف (اختياري)', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone),
                      SizedBox(height: 12),
                      isDialogLoading
                          ? Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                              value: selectedCommuneId,
                              decoration: InputDecoration(
                                labelText: 'البلدية المخصصة *',
                                prefixIcon: Icon(FontAwesomeIcons.locationDot, color: Colors.cyan, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: communes.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name'] ?? 'بلدية'))).toList(),
                              onChanged: (val) => setDialogState(() => selectedCommuneId = val),
                            ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(child: Text('إلغاء', style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
                    if (selectedCommuneId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى اختيار البلدية')));
                      return;
                    }

                    final auth = AuthService();
                    final data = <String, dynamic>{
                      'name':       _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : _usernameController.text.trim(),
                      'username':   _usernameController.text.trim(),
                      'phone':      _phoneController.text.trim(),
                      'commune_id': selectedCommuneId,
                      'wilaya_id':  auth.wilayaId,
                    };
                    if (_passwordController.text.trim().isNotEmpty) data['password'] = _passwordController.text.trim();

                    try {
                      if (isEdit) {
                        await ApiService.updateSupervisor(supervisor!['id'], data);
                      } else {
                        await ApiService.createSupervisor(data);
                      }
                      _refreshSupervisors();
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
      },
    );
  }

  void _deleteSupervisor(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تأكيد الحذف', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف هذا المشرف البلدي؟'),
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
        await ApiService.deleteSupervisor(id);
        _refreshSupervisors();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }

  Widget _buildTextField(
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
        title: Text(headerText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 23)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('خطأ: $error'))
              : RefreshIndicator(
                  onRefresh: _refreshSupervisors,
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
                                  hintText: 'البحث عن مشرف بلدي...',
                                  prefixIcon: Icon(FontAwesomeIcons.search, color: Colors.cyan, size: 18),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(FontAwesomeIcons.xmark, color: Colors.blueGrey.shade700, size: 16),
                                          onPressed: () {
                                            setState(() { _searchController.clear(); filteredSupervisors = List.from(supervisors); _applySorting(); });
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.transparent)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.cyan, width: 2)),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Material(
                              color: _hasActiveFilter ? Colors.cyan.shade50 : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _hasActiveFilter ? BorderSide(color: Colors.cyan, width: 1.5) : BorderSide.none,
                              ),
                              elevation: 2,
                              child: IconButton(
                                icon: Icon(FontAwesomeIcons.sliders, color: Colors.cyan, size: 20),
                                onPressed: _showFilterDialog,
                              ),
                            ),
                            SizedBox(width: 10),
                            Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: IconButton(icon: Icon(FontAwesomeIcons.arrowUpZA, color: Colors.cyan, size: 20), onPressed: _showSortDialog),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: _showAddSupervisorDialog,
                                icon: Icon(FontAwesomeIcons.plus, size: 16),
                                label: Text('إضافة مشرف بلدي', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: Colors.cyan.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.cyan.shade200)),
                              child: Text('${filteredSupervisors.length} مشرف', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.cyan.shade800)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: filteredSupervisors.isEmpty
                              ? Center(child: Text('لا يوجد مشرفون بلديون', style: TextStyle(color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: filteredSupervisors.length,
                                  itemBuilder: (context, index) {
                                    final sup = filteredSupervisors[index];
                                    final supName = sup['name'] ?? sup['username'] ?? 'مجهول';
                                    final communeName = sup['commune']?['name'] ?? 'غير مخصص';
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 2,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.cyan.shade100,
                                          child: Icon(FontAwesomeIcons.userShield, color: Colors.cyan.shade800),
                                        ),
                                        title: Text(supName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                        subtitle: Text("البلدية: $communeName\nاسم المستخدم: ${sup['username'] ?? 'N/A'}"),
                                        isThreeLine: true,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.pen, color: Colors.blue, size: 18),
                                              onPressed: () => _showEditSupervisorDialog(sup),
                                            ),
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.trash, color: Colors.red, size: 18),
                                              onPressed: () => _deleteSupervisor(sup['id']),
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
