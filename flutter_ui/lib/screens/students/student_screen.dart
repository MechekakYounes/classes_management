import 'package:flutter/material.dart';
import 'package:project_gp/core/services/api_service.dart';
import 'package:project_gp/core/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_gp/screens/dialogs/add_student_dialog.dart';
import 'package:project_gp/screens/dialogs/student_filter_dialog.dart';
import 'package:project_gp/screens/dialogs/edit_payement_status.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = '';

  // Active filters
  int? _filterWilayaId;
  int? _filterCommuneId;
  int? _filterClassId;
  int? _filterGroupId;

  String headerText = "Students";

  @override
  void initState() {
    super.initState();
    _setupHeader();
    _refreshStudents();
    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setupHeader() {
    final auth = AuthService();
    if (auth.isSuperAdmin()) {
      headerText = "All Students (Nationwide)";
    } else if (auth.isAdmin()) {
      headerText = "Students - ${auth.wilayaName ?? 'Wilaya'}";
    } else if (auth.isSupervisor()) {
      headerText = "Students - ${auth.communeName ?? 'Baladiya'}";
    } else if (auth.isManager()) {
      headerText = "Students - School";
    } else if (auth.isTeacher()) {
      headerText = "Students - Group";
    }
  }

  Future<void> _refreshStudents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      students = await ApiService.getStudents(
        wilayaId: _filterWilayaId,
        communeId: _filterCommuneId,
        classId: _filterClassId,
        groupId: _filterGroupId,
      );
      filteredStudents = List.from(students);
      _applySorting();
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredStudents = List.from(students);
      });
      _applySorting();
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredStudents = students.where((student) {
        final firstName = (student['fname'] ?? '').toString().toLowerCase();
        final lastName = (student['name'] ?? '').toString().toLowerCase();
        return firstName.contains(lowerQuery) || lastName.contains(lowerQuery);
      }).toList();
    });
  }

  void _applySorting() {
    setState(() {
      if (_sortBy == 'name_asc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['fname']} ${a['name']}'.toLowerCase();
          final nameB = '${b['fname']} ${b['name']}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
      } else if (_sortBy == 'name_desc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['fname']} ${a['name']}'.toLowerCase();
          final nameB = '${b['fname']} ${b['name']}'.toLowerCase();
          return nameB.compareTo(nameA);
        });
      }
    });
  }



  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Sort Options',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('Default')),
                  DropdownMenuItem(
                      value: 'name_asc', child: Text('Name (A-Z)')),
                  DropdownMenuItem(
                      value: 'name_desc', child: Text('Name (Z-A)')),
                ],
                onChanged: (value) => tempSortBy = value ?? '',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sortBy = tempSortBy;
                });
                _applySorting();
                Navigator.pop(context);
              },
              child: Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteStudent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Student'),
        content: Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteStudent(id);
        _refreshStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete student: $e')),
        );
      }
    }
  }

  void _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StudentFilterDialog(
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
        // Note: Teacher ID isn't handled by backend API in getStudents yet, so skipping it for now, 
        // or we could add it to ApiService if needed.
      });
      _refreshStudents();
    }
  }

  void _showAddEditStudentDialog({Map<String, dynamic>? student}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddEditStudentDialog(student: student),
    );
    if (result == true) {
      _refreshStudents();
    }
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
                  onRefresh: _refreshStudents,
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
                                  hintText: 'Search students...',
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
                                              filteredStudents = List.from(students);
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
                                onPressed: () => _showAddEditStudentDialog(),
                                icon: Icon(FontAwesomeIcons.plus, size: 16),
                                label: Text(
                                  'إضافة تلميذ',
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
                                '${filteredStudents.length} تلميذ',
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
                          child: filteredStudents.isEmpty
                              ? Center(
                                  child: Text('No students found',
                                      style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.builder(
  itemCount: filteredStudents.length,
  itemBuilder: (context, index) {
    final student = filteredStudents[index];
    final studentName = "${student['fname']} ${student['name']}";

    final bool isPaid = student['payement_status'] == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.cyan.shade100,
          child: Icon(
            FontAwesomeIcons.user,
            color: Colors.cyan.shade800,
            size: 18,
          ),
        ),
        title: Text(
          studentName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hifdh: ${student['hifdh'] ?? 'N/A'}",
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),

              // Payment Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPaid
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: isPaid
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid ? "PAID" : "UNPAID",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: isPaid
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.moneyBill,
                color: Colors.blueGrey,
                size: 20,
              ),
              onPressed: () async {
                final updated = await showDialog(
                 context: context,
                 builder: (_) => EditPaymentStatusDialog(
                  student: student,
                 ),
                );

                if (updated == true) {
                _refreshStudents();
                               }
              },

            ),
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.pen,
                color: Colors.blue,
                size: 20,
              ),
              onPressed: () =>
                  _showAddEditStudentDialog(student: student),
            ),
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.trash,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () =>
                  _deleteStudent(student['id']),
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






