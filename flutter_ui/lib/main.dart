import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_gp/api_service.dart';

void main() {
  runApp(ClassManagerApp());
}

class ClassManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        appBarTheme: AppBarTheme(
          toolbarHeight: 65,
          backgroundColor: Colors.cyan,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan.shade600,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: MainTabController(),
    );
  }
}

class MainTabController extends StatefulWidget {
  @override
  _MainTabControllerState createState() => _MainTabControllerState();
}

class _MainTabControllerState extends State<MainTabController> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    GroupScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        height: 120,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.group),
                    label: 'Groups',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SvgPicture.asset(
                        'assets/icons/plus.svg',
                        width: 24,
                        height: 24,
                        colorFilter:
                            ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 20);
    path.quadraticBezierTo(size.width * 3 / 4, 40, size.width, 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = '';
  String _speciality = '';
  String _year = '';
  bool isLoading = true;
  String? error;

  List<dynamic> classes = [];
  List<dynamic> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _refreshClasses();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _refreshClasses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      classes = await ApiService.getClasses();
      _filteredClasses = List.from(classes);
    } catch (e) {
      error = e.toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.deleteClass(id);
              _refreshClasses();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(Map<String, dynamic> classToEdit) {
    final _nameController = TextEditingController(text: classToEdit['name']);
    final _specialityController =
        TextEditingController(text: classToEdit['speciality']);
    final _levelController = TextEditingController(text: classToEdit['level']);
    final _semesterController =
        TextEditingController(text: classToEdit['semester'] ?? '');
    final _yearController = TextEditingController(text: classToEdit['year']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text('Edit Class', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Class Name'),
                _buildTextField(_specialityController, 'Speciality'),
                _buildTextField(_levelController, 'Level'),
                _buildTextField(_semesterController, 'Semester'),
                _buildTextField(_yearController, 'Year'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () async {
                Map<String, dynamic> updatedData = {
                  'name': _nameController.text,
                  'speciality': _specialityController.text,
                  'level': _levelController.text,
                  'semester': _semesterController.text,
                  'year': _yearController.text,
                };

                await ApiService.updateClass(classToEdit['id'], updatedData);
                _refreshClasses();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _applyFilters() {
    List<dynamic> temp = classes.where((cls) {
      final matchesSpeciality =
          _speciality.isEmpty || cls['speciality'] == _speciality;
      final matchesYear = _year.isEmpty || cls['year'] == _year;
      return matchesSpeciality && matchesYear;
    }).toList();

    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name'].compareTo(b['name']));
    } else if (_sortBy == 'time') {
      temp.sort((a, b) => a['created_at'] != null && b['created_at'] != null
          ? a['created_at'].compareTo(b['created_at'])
          : 0);
    }

    setState(() {
      _filteredClasses = temp;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;
        String tempSpeciality = _speciality;
        String tempYear = _year;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Filter Options',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sort by'),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'time', child: Text('Time Added')),
                ],
                onChanged: (value) => tempSortBy = value ?? '',
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Speciality'),
                value: tempSpeciality.isEmpty ? null : tempSpeciality,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: 'CS', child: Text('CS')),
                  DropdownMenuItem(value: 'ST', child: Text('ST')),
                  DropdownMenuItem(value: 'AI', child: Text('AI')),
                ],
                onChanged: (value) => tempSpeciality = value ?? '',
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Year'),
                value: tempYear.isEmpty ? null : tempYear,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: '2023', child: Text('2023')),
                  DropdownMenuItem(value: '2024', child: Text('2024')),
                  DropdownMenuItem(value: '2025', child: Text('2025')),
                ],
                onChanged: (value) => tempYear = value ?? '',
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sortBy = tempSortBy;
                  _speciality = tempSpeciality;
                  _year = tempYear;
                });
                _applyFilters();
                Navigator.pop(context);
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredClasses = classes.where((cls) {
        return cls['name'].toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Class Dashboard'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _search,
                              decoration: InputDecoration(
                                hintText: 'Search class...',
                                prefixIcon: Icon(
                                  FontAwesomeIcons.search,
                                  color: Colors.cyan,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.blueGrey.shade700,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filteredClasses =
                                                List.from(classes);
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
                                  borderSide:
                                      BorderSide(color: Colors.cyan, width: 2),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      BorderSide(color: Colors.transparent),
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
                            child: IconButton(
                              icon: Icon(
                                FontAwesomeIcons.sliders,
                                color: Colors.cyan,
                                size: 20,
                              ),
                              onPressed: _showFilterDialog,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 250,
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateClassDialog,
                            icon: SvgPicture.asset(
                              'assets/icons/plus.svg',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Create New Class',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredClasses.isEmpty
                            ? Center(
                                child: Text('No matching classes found',
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _filteredClasses.length,
                                itemBuilder: (context, index) {
                                  final cls = _filteredClasses[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(
                                        cls['name'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Speciality: ${cls['speciality']} | Year: ${cls['year']} | Level: ${cls['level']}',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 18, color: Colors.teal),
                                              SizedBox(height: 4),
                                              Text(
                                                  cls['created_at']
                                                          ?.substring(0, 10) ??
                                                      '',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                          SizedBox(width: 10),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () =>
                                                    _showEditClassDialog(cls),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _confirmDelete(cls['id']),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      onTap: () => _GroupScreenState,
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

  void _showCreateClassDialog() {
    final _nameController = TextEditingController();
    final _specialityController = TextEditingController();
    final _levelController = TextEditingController();
    final _semesterController = TextEditingController();
    final _yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Create New Class',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(_nameController, 'Class Name'),
                _buildTextField(_specialityController, 'Speciality'),
                _buildTextField(_levelController, 'Level'),
                _buildTextField(_semesterController, 'Semester'),
                _buildTextField(_yearController, 'Year'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Create'),
              onPressed: () async {
                Map<String, dynamic> newClass = {
                  'name': _nameController.text,
                  'speciality': _specialityController.text,
                  'level': _levelController.text,
                  'semester': _semesterController.text,
                  'year': _yearController.text,
                };

                await ApiService.createClass(newClass);
                _refreshClasses();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class GroupScreen extends StatefulWidget {
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String? error;
  late int selectedClassId;

  List<dynamic> classes = [];
  List<dynamic> groups = [];
  List<dynamic> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      classes = await ApiService.getClasses();
      if (classes.isNotEmpty) {
        await _loadGroups(classes[0]['id']);
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadGroups(int classId) async {
    setState(() {
      isLoading = true;
      selectedClassId = classId;
      error = null;
    });

    try {
      groups = await ApiService.getGroups();
      groups = groups.where((group) => group['class_id'] == classId).toList();
      _filteredGroups = List.from(groups);
    } catch (e) {
      error = e.toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _search(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredGroups = groups.where((group) {
        return group['name'].toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _showCreateGroupDialog() {
    final _nameController = TextEditingController();
    final _typeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Create New Group',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Group Name'),
                _buildTextField(_typeController, 'Group Type'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Create'),
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group name cannot be empty')),
                  );
                  return;
                }

                Map<String, dynamic> newGroup = {
                  'name': _nameController.text,
                  'type': _typeController.text,
                  'class_id': selectedClassId,
                };

                try {
                  await ApiService.createGroup(selectedClassId, newGroup);
                  Navigator.pop(context);
                  _loadGroups(selectedClassId);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to create group: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    final _nameController = TextEditingController(text: group['name'] ?? '');
    final _typeController = TextEditingController(text: group['type'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title:
              Text('Edit Group', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_nameController, 'Group Name'),
                _buildTextField(_typeController, 'Group Type'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Group name cannot be empty')),
                  );
                  return;
                }

                Map<String, dynamic> updatedGroup = {
                  'name': _nameController.text,
                  'type': _typeController.text,
                };

                try {
                  await ApiService.updateGroup(
                      selectedClassId, group['id'], updatedGroup);
                  Navigator.pop(context);
                  _loadGroups(selectedClassId!);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to update group: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteGroup(int groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteGroup(selectedClassId, groupId);
                _loadGroups(selectedClassId);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Failed to delete group: ${e.toString()}')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedClassId,
                            hint: Text('Select a class'),
                            onChanged: (int? value) {
                              if (value != null) {
                                _loadGroups(value);
                              }
                            },
                            items: classes.map<DropdownMenuItem<int>>((cls) {
                              return DropdownMenuItem<int>(
                                value: cls['id'],
                                child: Text(
                                    '${cls['name']} (${cls['speciality']} - ${cls['level']} - ${cls['year']})'),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _search,
                              decoration: InputDecoration(
                                hintText: 'Search group...',
                                prefixIcon: Icon(
                                  FontAwesomeIcons.search,
                                  color: Colors.cyan,
                                  size: 20,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          FontAwesomeIcons.xmark,
                                          color: Colors.blueGrey.shade700,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filteredGroups = List.from(groups);
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
                                  borderSide:
                                      BorderSide(color: Colors.cyan, width: 2),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      BorderSide(color: Colors.transparent),
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
                            child: IconButton(
                              icon: Icon(
                                FontAwesomeIcons.sliders,
                                color: Colors.cyan,
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: 250,
                          height: 45,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateGroupDialog,
                            icon: SvgPicture.asset(
                              'assets/icons/plus.svg',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Create New Group',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _filteredGroups.isEmpty
                            ? Center(
                                child: Text('No groups found for this class',
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                itemCount: _filteredGroups.length,
                                itemBuilder: (context, index) {
                                  final group = _filteredGroups[index];
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(
                                        group['name'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Type: ${group['type'] ?? 'Not specified'}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue),
                                            onPressed: () =>
                                                _showEditGroupDialog(group),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _confirmDeleteGroup(
                                                    group['id']),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showEditGroupDialog(group),
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

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  AssetImage('assets/images/profile_placeholder.png'),
            ),
            SizedBox(height: 20),
            Text(
              'User Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'user@example.com',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 30),
            _buildProfileButton('Edit Profile', Icons.edit, () {}),
            _buildProfileButton('Settings', Icons.settings, () {}),
            _buildProfileButton('Logout', Icons.logout, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileButton(
      String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.cyan,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon),
            Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
