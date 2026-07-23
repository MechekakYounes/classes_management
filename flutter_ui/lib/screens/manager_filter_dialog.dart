import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';

class ManagerFilterDialog extends StatefulWidget {
  final int? initialWilayaId;
  final int? initialCommuneId;
  final int? initialClassId;

  const ManagerFilterDialog({
    Key? key,
    this.initialWilayaId,
    this.initialCommuneId,
    this.initialClassId,
  }) : super(key: key);

  @override
  _ManagerFilterDialogState createState() => _ManagerFilterDialogState();
}

class _ManagerFilterDialogState extends State<ManagerFilterDialog> {
  bool _isLoading = false;
  final auth = AuthService();

  int? _selectedWilayaId;
  int? _selectedCommuneId;
  int? _selectedClassId;

  List<dynamic> wilayas = [];
  List<dynamic> communes = [];
  List<dynamic> classes = [];

  bool lockWilaya = false;
  bool lockCommune = false;

  @override
  void initState() {
    super.initState();
    _selectedWilayaId = widget.initialWilayaId;
    _selectedCommuneId = widget.initialCommuneId;
    _selectedClassId = widget.initialClassId;
    _setupRoleLocks();
    _loadInitialData();
  }

  void _setupRoleLocks() {
    if (auth.isAdmin() || auth.isSupervisor()) {
      lockWilaya = true;
      _selectedWilayaId = auth.wilayaId;
    }
    if (auth.isSupervisor()) {
      lockCommune = true;
      _selectedCommuneId = auth.communeId;
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      if (!lockWilaya) wilayas = await ApiService.getWilayas();
      if (_selectedWilayaId != null && !lockCommune) {
        communes = await ApiService.getCommunesByWilaya(_selectedWilayaId!);
      }
      if (_selectedCommuneId != null) {
        classes = await ApiService.getClasses(communeId: _selectedCommuneId);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _onWilayaChanged(int? newId) async {
    setState(() {
      _selectedWilayaId = newId;
      _selectedCommuneId = null;
      _selectedClassId = null;
      communes = [];
      classes = [];
      _isLoading = true;
    });
    try {
      if (newId != null) communes = await ApiService.getCommunesByWilaya(newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onCommuneChanged(int? newId) async {
    setState(() {
      _selectedCommuneId = newId;
      _selectedClassId = null;
      classes = [];
      _isLoading = true;
    });
    try {
      if (newId != null) classes = await ApiService.getClasses(communeId: newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(FontAwesomeIcons.sliders, color: Colors.cyan, size: 20),
          SizedBox(width: 10),
          Text('تصفية المدراء', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wilaya
                  if (!lockWilaya) ...[
                    Text('الولاية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
                    SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _selectedWilayaId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.mapLocationDot, color: Colors.cyan, size: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        hintText: 'كل الولايات',
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text('كل الولايات')),
                        ...wilayas.map((w) => DropdownMenuItem<int>(value: w['id'], child: Text(w['name'] ?? ''))),
                      ],
                      onChanged: (val) => _onWilayaChanged(val),
                    ),
                    SizedBox(height: 12),
                  ],

                  // Commune
                  if (!lockCommune) ...[
                    Text('البلدية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
                    SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      value: _selectedCommuneId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(FontAwesomeIcons.locationDot, color: Colors.cyan, size: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        hintText: 'كل البلديات',
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text('كل البلديات')),
                        ...communes.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name'] ?? ''))),
                      ],
                      onChanged: communes.isEmpty ? null : (val) => _onCommuneChanged(val),
                    ),
                    SizedBox(height: 12),
                  ],

                  // School / Class
                  Text('المدرسة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey)),
                  SizedBox(height: 4),
                  DropdownButtonFormField<int>(
                    value: _selectedClassId,
                    decoration: InputDecoration(
                      prefixIcon: Icon(FontAwesomeIcons.school, color: Colors.cyan, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      hintText: 'كل المدارس',
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text('كل المدارس')),
                      ...classes.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name'] ?? ''))),
                    ],
                    onChanged: classes.isEmpty ? null : (val) => setState(() => _selectedClassId = val),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          child: Text('إعادة ضبط', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.pop(context, <String, dynamic>{
            'wilayaId': null, 'communeId': null, 'classId': null,
          }),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context, {
            'wilayaId': _selectedWilayaId,
            'communeId': _selectedCommuneId,
            'classId': _selectedClassId,
          }),
        ),
      ],
    );
  }
}
