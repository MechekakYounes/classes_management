import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';

class AdminFilterDialog extends StatefulWidget {
  final int? initialWilayaId;

  const AdminFilterDialog({Key? key, this.initialWilayaId}) : super(key: key);

  @override
  _AdminFilterDialogState createState() => _AdminFilterDialogState();
}

class _AdminFilterDialogState extends State<AdminFilterDialog> {
  bool _isLoading = false;
  final auth = AuthService();

  int? _selectedWilayaId;
  List<dynamic> wilayas = [];

  @override
  void initState() {
    super.initState();
    _selectedWilayaId = widget.initialWilayaId;
    _loadWilayas();
  }

  Future<void> _loadWilayas() async {
    setState(() => _isLoading = true);
    try {
      wilayas = await ApiService.getWilayas();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(FontAwesomeIcons.sliders, color: Colors.cyan, size: 20),
          SizedBox(width: 10),
          Text('تصفية المشرفين الولائيين', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  onChanged: (val) => setState(() => _selectedWilayaId = val),
                ),
              ],
            ),
      actions: [
        TextButton(
          child: Text('إعادة ضبط', style: TextStyle(color: Colors.red)),
          onPressed: () => Navigator.pop(context, <String, dynamic>{'wilayaId': null}),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('تطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.pop(context, {'wilayaId': _selectedWilayaId}),
        ),
      ],
    );
  }
}
