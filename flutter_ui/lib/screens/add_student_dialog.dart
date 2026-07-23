import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';
import '../auth_service.dart';

class AddEditStudentDialog extends StatefulWidget {
  final Map<String, dynamic>? student;

  const AddEditStudentDialog({Key? key, this.student}) : super(key: key);

  @override
  _AddEditStudentDialogState createState() => _AddEditStudentDialogState();
}

class _AddEditStudentDialogState extends State<AddEditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Role info
  final auth = AuthService();
  
  // Selections
  int? _selectedWilayaId;
  int? _selectedCommuneId;
  int? _selectedClassId;
  int? _selectedGroupId;
  int? _selectedTeacherId;

  // Dropdown lists
  List<dynamic> wilayas = [];
  List<dynamic> communes = [];
  List<dynamic> classes = [];
  List<dynamic> groups = [];
  List<dynamic> teachers = [];

  // Locks
  bool lockWilaya = false;
  bool lockCommune = false;
  bool lockClass = false;
  bool lockTeacher = false;
  bool lockGroup = false; // Usually not locked, even for teacher

  @override
  void initState() {
    super.initState();
    _setupRoleLocks();
    _populateFields();
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
    if (auth.isTeacher()) {
      lockTeacher = true;
      _selectedTeacherId = auth.user?['id'];
      // A teacher might only have one group, but let's allow group selection if they have multiple, or lock it.
      // The requirement says: "Teacher: Teacher Name field is automatically set... adds a required selector for the Student Group."
      // So group is NOT locked.
    }
  }

  void _populateFields() {
    if (widget.student != null) {
      _firstNameController.text = widget.student!['fname'] ?? '';
      _lastNameController.text = widget.student!['name'] ?? '';
      _phoneController.text = widget.student!['phone'] ?? '';
      
      _selectedGroupId = int.tryParse(widget.student!['group_id']?.toString() ?? '');
      // If we are editing, we ideally need to fetch the full hierarchy up. 
      // For simplicity, we assume we either have them in student data or we rely on role locks.
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
      if (_selectedGroupId != null) {
        if (!lockTeacher) teachers = await ApiService.getTeachers(groupId: _selectedGroupId);
      }
      
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onWilayaChanged(int? newId) async {
    if (newId == null || newId == _selectedWilayaId) return;
    setState(() {
      _selectedWilayaId = newId;
      _selectedCommuneId = null;
      _selectedClassId = null;
      _selectedGroupId = null;
      _selectedTeacherId = null;
      communes = [];
      classes = [];
      groups = [];
      teachers = [];
      _isLoading = true;
    });
    try {
      communes = await ApiService.getCommunesByWilaya(newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onCommuneChanged(int? newId) async {
    if (newId == null || newId == _selectedCommuneId) return;
    setState(() {
      _selectedCommuneId = newId;
      _selectedClassId = null;
      _selectedGroupId = null;
      _selectedTeacherId = null;
      classes = [];
      groups = [];
      teachers = [];
      _isLoading = true;
    });
    try {
      classes = await ApiService.getClasses(communeId: newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onClassChanged(int? newId) async {
    if (newId == null || newId == _selectedClassId) return;
    setState(() {
      _selectedClassId = newId;
      _selectedGroupId = null;
      _selectedTeacherId = null;
      groups = [];
      teachers = [];
      _isLoading = true;
    });
    try {
      groups = await ApiService.getGroupsByClass(newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onGroupChanged(int? newId) async {
    if (newId == null || newId == _selectedGroupId) return;
    setState(() {
      _selectedGroupId = newId;
      _selectedTeacherId = null;
      teachers = [];
      _isLoading = true;
    });
    try {
      teachers = await ApiService.getTeachers(groupId: newId);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a Group.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'fname': _firstNameController.text.trim(),
        'name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'group_id': _selectedGroupId,
      };

      if (widget.student == null) {
        await ApiService.createStudent(data);
      } else {
        await ApiService.updateStudent(widget.student!['id'], data);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 500, maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.student == null ? 'Add New Student' : 'Edit Student',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyan.shade800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading && wilayas.isEmpty && communes.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _firstNameController,
                              decoration: _inputDeco('First Name', FontAwesomeIcons.user),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: _inputDeco('Last Name', FontAwesomeIcons.user),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _inputDeco('Parent Phone', FontAwesomeIcons.phone),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 8),
                            
                            // Wilaya
                            if (!lockWilaya) ...[
                              _buildDropdown(
                                'Wilaya',
                                _selectedWilayaId,
                                wilayas.map((w) => DropdownMenuItem<int>(value: w['id'], child: Text(w['name']))).toList(),
                                _onWilayaChanged,
                              ),
                              SizedBox(height: 12),
                            ] else ...[
                               _buildLockedField('Wilaya', auth.wilayaName ?? 'Locked Wilaya'),
                               SizedBox(height: 12),
                            ],

                            // Commune
                            if (!lockCommune) ...[
                              _buildDropdown(
                                'Baladiya',
                                _selectedCommuneId,
                                communes.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                                _onCommuneChanged,
                              ),
                              SizedBox(height: 12),
                            ] else ...[
                               _buildLockedField('Baladiya', auth.communeName ?? 'Locked Baladiya'),
                               SizedBox(height: 12),
                            ],

                            // Class/School
                            if (!lockClass) ...[
                              _buildDropdown(
                                'School Name',
                                _selectedClassId,
                                classes.map((c) => DropdownMenuItem<int>(value: c['id'], child: Text(c['name']))).toList(),
                                _onClassChanged,
                              ),
                              SizedBox(height: 12),
                            ] else ...[
                               _buildLockedField('School', auth.user?['class']?['name'] ?? 'Locked School'),
                               SizedBox(height: 12),
                            ],

                            // Group
                             if (!lockGroup) ...[
                              _buildDropdown(
                                'Student Group',
                                _selectedGroupId,
                                groups.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['name']))).toList(),
                                _onGroupChanged,
                              ),
                              SizedBox(height: 12),
                            ] else ...[
                               _buildLockedField('Group', auth.user?['group']?['name'] ?? 'Locked Group'),
                               SizedBox(height: 12),
                            ],

                            // Teacher
                            if (!lockTeacher) ...[
                              _buildDropdown(
                                'Teacher',
                                _selectedTeacherId,
                                teachers.map((t) => DropdownMenuItem<int>(value: t['id'], child: Text(t['name']))).toList(),
                                (v) => setState(() => _selectedTeacherId = v),
                              ),
                              SizedBox(height: 12),
                            ] else ...[
                               _buildLockedField('Teacher', auth.user?['name'] ?? 'Locked Teacher'),
                               SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.cyan, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDropdown(String label, int? value, List<DropdownMenuItem<int>> items, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      decoration: _inputDeco(label, FontAwesomeIcons.caretDown).copyWith(prefixIcon: null),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
      hint: Text('Select $label'),
    );
  }

  Widget _buildLockedField(String label, String value) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: _inputDeco(label, FontAwesomeIcons.lock).copyWith(
        fillColor: Colors.grey.shade100,
        filled: true,
      ),
    );
  }
}
