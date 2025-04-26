import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({
    Key? key,
  }) : super(key: key);

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

  void initState() {
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

  Future<void> _refreshStudents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      students = await ApiService.getStudents();
      filteredStudents = List.from(students);
      setState(() {
        isLoading = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
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
        //final phone = (student['phone'] ?? '').toString().toLowerCase();

        return firstName.contains(lowerQuery) || lastName.contains(lowerQuery);
        // phone.contains(lowerQuery);
      }).toList();
    });
  }

  void _applySorting() {
    setState(() {
      if (_sortBy == 'name_asc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['fname']} ${a['name']}'.toLowerCase();
          final nameB = '${b['first_name']} ${b['last_name']}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
      } else if (_sortBy == 'name_desc') {
        filteredStudents.sort((a, b) {
          final nameA = '${a['first_name']} ${a['last_name']}'.toLowerCase();
          final nameB = '${b['first_name']} ${b['last_name']}'.toLowerCase();
          return nameB.compareTo(nameA);
        });
      } else if (_sortBy == 'email_asc') {
        filteredStudents.sort((a, b) {
          final emailA = (a['email'] ?? '').toString().toLowerCase();
          final emailB = (b['email'] ?? '').toString().toLowerCase();
          return emailA.compareTo(emailB);
        });
      } else if (_sortBy == 'email_desc') {
        filteredStudents.sort((a, b) {
          final emailA = (a['email'] ?? '').toString().toLowerCase();
          final emailB = (b['email'] ?? '').toString().toLowerCase();
          return emailB.compareTo(emailA);
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
                  DropdownMenuItem(
                      value: 'email_asc', child: Text('Email (A-Z)')),
                  DropdownMenuItem(
                      value: 'email_desc', child: Text('Email (Z-A)')),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text('Error: $error'));
    }

    return RefreshIndicator(
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
                                  color: Colors.blueGrey.shade700, size: 16),
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
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
                Text(
                  'Students (${filteredStudents.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.userGroup,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No students in this group',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    )
                  : filteredStudents.isEmpty
                      ? Center(
                          child: Text('No matching students found',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
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
