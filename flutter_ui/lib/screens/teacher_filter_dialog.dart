import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';

class TeacherFilterDialog extends StatefulWidget {
  final int? initialWilayaId;
  final int? initialCommuneId;
  final int? initialClassId;
  final int? initialGroupId;

  const TeacherFilterDialog({
    Key? key,
    this.initialWilayaId,
    this.initialCommuneId,
    this.initialClassId,
    this.initialGroupId,
  }) : super(key: key);

  @override
  _TeacherFilterDialogState createState() => _TeacherFilterDialogState();
}

class _TeacherFilterDialogState extends State<TeacherFilterDialog> {
  bool _isLoading = false;

  final auth = AuthService();

  int? _selectedWilayaId;
  int? _selectedCommuneId;
  int? _selectedClassId;
  int? _selectedGroupId;
  int? _selectedTeacherId; // If we add teacher filter later

  List<dynamic> wilayas = [];
  List<dynamic> communes = [];
  List<dynamic> classes = [];
  List<dynamic> groups = [];

  bool lockWilaya = false;
  bool lockCommune = false;
  bool lockClass = false;
  bool lockGroup = false;

  @override
  void initState() {
    super.initState();
    _selectedWilayaId = widget.initialWilayaId;
    _selectedCommuneId = widget.initialCommuneId;
    _selectedClassId = widget.initialClassId;
    _selectedGroupId = widget.initialGroupId;

    _setupRoleLocks();
    _loadInitialData();
  }

  void _setupRoleLocks() {
    if (auth.isAdmin() || auth.isSupervisor() || auth.isManager() || auth.isTeacher()) {
      lockWilaya = true;
      _selectedWilayaId = auth.wilayaId;
    }
    if (auth.isSupervisor() || auth.isManager() || auth.isTeacher()) {
      lockCommune = true;
      _selectedCommuneId = auth.communeId;
    }
    if (auth.isManager() || auth.isTeacher()) {
      lockClass = true;
      _selectedClassId = auth.classId;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (!lockWilaya) wilayas = await ApiService.getWilayas();
      
      if (_selectedWilayaId != null && !lockCommune) {
        communes = await ApiService.getCommunesByWilaya(_selectedWilayaId!);
      }
      if (_selectedCommuneId != null && !lockClass) {
        classes = await ApiService.getClasses(communeId: _selectedCommuneId);
      }
      if (_selectedClassId != null) {
        if (!lockGroup) groups = await ApiService.getGroupsByClass(_selectedClassId!);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onWilayaChanged(int? newId) async {
    if (newId == null) return;
    setState(() {
      _selectedWilayaId = newId;
      _selectedCommuneId = null;
      _selectedClassId = null;
      _selectedGroupId = null;
      communes = [];
      classes = [];
      groups = [];
      _isLoading = true;
    });
    try {
      communes = await ApiService.getCommunesByWilaya(newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onCommuneChanged(int? newId) async {
    if (newId == null) return;
    setState(() {
      _selectedCommuneId = newId;
      _selectedClassId = null;
      _selectedGroupId = null;
      classes = [];
      groups = [];
      _isLoading = true;
    });
    try {
      classes = await ApiService.getClasses(communeId: newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onClassChanged(int? newId) async {
    if (newId == null) return;
    setState(() {
      _selectedClassId = newId;
      _selectedGroupId = null;
      groups = [];
      _isLoading = true;
    });
    try {
      groups = await ApiService.getGroupsByClass(newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onGroupChanged(int? newId) async {
    if (newId == null) return;
    setState(() {
      _selectedGroupId = newId;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'wilayaId': _selectedWilayaId,
      'communeId': _selectedCommuneId,
      'classId': _selectedClassId,
      'groupId': _selectedGroupId,
    });
  }

  void _clearFilters() {
    Navigator.pop(context, {
      'wilayaId': lockWilaya ? auth.wilayaId : null,
      'communeId': lockCommune ? auth.communeId : null,
      'classId': lockClass ? auth.classId : null,
      'groupId': null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Teachers',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyan.shade800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading && wilayas.isEmpty && communes.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          if (!lockWilaya) ...[
                            _buildDropdown('Wilaya', _selectedWilayaId, wilayas, _onWilayaChanged),
                            SizedBox(height: 12),
                          ],
                          if (!lockCommune) ...[
                            _buildDropdown('Baladiya', _selectedCommuneId, communes, _onCommuneChanged),
                            SizedBox(height: 12),
                          ],
                          if (!lockClass) ...[
                            _buildDropdown('School Name', _selectedClassId, classes, _onClassChanged),
                            SizedBox(height: 12),
                          ],
                          if (!lockGroup) ...[
                            _buildDropdown('Group', _selectedGroupId, groups, _onGroupChanged),
                            SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearFilters,
                  child: Text('Clear', style: TextStyle(color: Colors.red)),
                ),
                SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, int? value, List<dynamic> items, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: value,
      items: [
        DropdownMenuItem<int>(value: null, child: Text('All')),
        ...items.map((item) => DropdownMenuItem<int>(value: item['id'], child: Text(item['name']))).toList(),
      ],
      onChanged: onChanged,
    );
  }
}
