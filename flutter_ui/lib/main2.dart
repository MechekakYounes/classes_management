import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_gp/add_edit_diag.dart';
import 'api_service.dart';

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
        scaffoldBackgroundColor: const Color(0xFFE0F7FA), // background
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        appBarTheme: AppBarTheme(
          toolbarHeight: 65, // increased height here

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
    studentScreen(),
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
        height: 100,
        child: Stack(
          children: [
            // Wave background
            Positioned.fill(
              child: CustomPaint(
                painter: WavePainter(),
              ),
            ),
            // Bottom nav bar icons centered in wave
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
                    icon: Icon(FontAwesomeIcons.person),
                    label: 'student',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FontAwesomeIcons.gear),
                    label: 'setting',
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

/// Custom wave painter for background
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0, 10);

// Gentle wave with moderate curvature
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 12);
    path.quadraticBezierTo(size.width * 3 / 4, 24, size.width, 10);

// Close the shape
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
  String _specialty = '';
  String _year = '';
  bool isLoading = true;
  String? error;

  List<dynamic> classes = [];

  List<dynamic> _filteredClasses = [];

  @override
  void initState() {
    super.initState();
    _refreshClasses();
    _filteredClasses = List.from(classes);
    _searchController.addListener(() {
      setState(() {}); // So suffixIcon updates reactively
    });
  }

  Future<void> _refreshClasses() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      classes = await ApiService.getClasses();
      // Debug: Print number of classes fetched
      print('Fetched ${classes.length} classes.');
    } catch (e) {
      error = e.toString();
      print('Error fetching classes: $error');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showAddEditDialog([Map<String, dynamic>? classToEdit]) {
    showDialog(
      context: context,
      builder: (context) => AddEditClassDialog(
        classToEdit: classToEdit,
        onSave: (data) async {
          if (classToEdit != null) {
            await ApiService.updateClass(classToEdit['id'], data);
          } else {
            await ApiService.createClass(data);
          }
          _refreshClasses();
        },
      ),
    );
  }

  void _applyFiltersclass() {
    List<dynamic> temp = classes.where((cls) {
      final matchesSpecialty =
          _specialty.isEmpty || cls['specialty'] == _specialty;
      final matchesYear = _year.isEmpty || cls['year'] == _year;
      return matchesSpecialty && matchesYear;
    }).toList();

    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name']!.compareTo(b['name']!));
    } else if (_sortBy == 'time') {
      temp.sort((a, b) => a['time']!.compareTo(b['time']!));
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
        String tempSpecialty = _specialty;
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
                decoration: InputDecoration(labelText: 'Specialty'),
                value: tempSpecialty.isEmpty ? null : tempSpecialty,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: 'CS', child: Text('CS')),
                  DropdownMenuItem(value: 'ST', child: Text('ST')),
                  DropdownMenuItem(value: 'AI', child: Text('AI')),
                ],
                onChanged: (value) => tempSpecialty = value ?? '',
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
                  _specialty = tempSpecialty;
                  _year = tempYear;
                });
                _applyFiltersclass();
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
        return cls['name']!.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' Class Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Search & Filter Row
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
                                  _filteredClasses = List.from(classes);
                                });
                              },
                            )
                          : null,

                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),

                      //  Hide border when not focused
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),

                      //  Optional: show border when focused
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                      ),

                      // Also hide default border
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
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
                      FontAwesomeIcons.sliders, // The filter icon
                      color: Colors.cyan, // Custom color
                      size: 20, // Icon size
                    ),
                    onPressed: _showFilterDialog, // Action for the filter icon
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                width: 250, // Set the button width here
                height: 45, // Set the button height here
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
                              cls['name']!,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Specialty: ${cls['specialty']} | Year: ${cls['year']} | Level: ${cls['level']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: Colors.teal),
                                SizedBox(height: 4),
                                Text(cls['time']!,
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupsScreen(
                                    className: cls[
                                        'name']!, // pass the class name here
                                  ),
                                ),
                              );
                            },
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
    final _specialtyController = TextEditingController();
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
                _buildTextField(_specialtyController, 'Specialty'),
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
              onPressed: () {
                setState(() {
                  classes.add({
                    'name': _nameController.text,
                    'specialty': _specialtyController.text,
                    'level': _levelController.text,
                    'semester': _semesterController.text,
                    'year': _yearController.text,
                    'time': DateTime.now().toString().split(' ')[0],
                  });
                  _applyFiltersclass(); // reapply any filters
                });
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

//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////GROUP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class GroupsScreen extends StatefulWidget {
  final String className;

  const GroupsScreen({required this.className});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'none';
  String _groupType = 'ALL'; // Default to 'ALL' for group type filter

  final List<Map<String, String>> _allGroups = [
    {"name": "Group 1", "type": "TD"},
    {"name": "Group 2", "type": "TP"},
    {"name": "Group 3", "type": "TD"},
    {"name": "Group 4", "type": "TP"},
  ];

  void _onGroupTapped(String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionsScreen(groupName: groupName),
      ),
    );
  }

  List<Map<String, String>> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _filteredGroups = List.from(_allGroups);
    _searchController.addListener(() {
      setState(() {
        _applyFilters();
      });
    });
  }

  void _applyFilters() {
    List<Map<String, String>> temp = _allGroups.where((grp) {
      final matchesType = _groupType == 'ALL' || grp['type'] == _groupType;
      final matchesName = _searchController.text.isEmpty ||
          grp['name']!
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesType && matchesName;
    }).toList();

    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name']!.compareTo(b['name']!));
    }

    setState(() {
      _filteredGroups = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    void _showFilterDialog() {
      showDialog(
        context: context,
        builder: (context) {
          String tempSortBy = _sortBy;
          String tempGroupType = _groupType;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Filter Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: UnderlineInputBorder(), // 👈 line style
                  ),
                  value: tempSortBy == 'none' ? null : tempSortBy,
                  items: [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                  onChanged: (value) {
                    tempSortBy = value ?? 'none';
                  },
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Group Type',
                    border: UnderlineInputBorder(), // 👈 line style
                  ),
                  value: tempGroupType == 'ALL' ? null : tempGroupType,
                  items: [
                    DropdownMenuItem(value: 'ALL', child: Text('All Types')),
                    DropdownMenuItem(value: 'TD', child: Text('TD')),
                    DropdownMenuItem(value: 'TP', child: Text('TP')),
                  ],
                  onChanged: (value) {
                    tempGroupType = value ?? 'ALL';
                  },
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
                    _groupType = tempGroupType;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className.length > 16
              ? widget.className.substring(0, 16) + '...'
              : widget.className,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _applyFilters(); // Apply filter whenever search changes
                    },
                    decoration: InputDecoration(
                      hintText: 'Search group...',
                      prefixIcon: Icon(FontAwesomeIcons.search,
                          color: Colors.cyan, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(FontAwesomeIcons.xmark,
                                  color: Colors.blueGrey.shade700, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _applyFilters(); // Reset filter
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.transparent),
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
                    icon: Icon(FontAwesomeIcons.sliders,
                        color: Colors.cyan, size: 20),
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
                      child: Text('No matching groups found',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _filteredGroups.length,
                      itemBuilder: (context, index) {
                        final grp = _filteredGroups[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(grp['name']!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Type: ${grp['type']}',
                                  style: TextStyle(fontSize: 14)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.edit,
                                      size: 18, color: Colors.teal),
                                  onPressed: () {
                                    _showUpdateGroupDialog(
                                        grp['name']!, grp['type']!);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.deleteLeft,
                                      size: 18, color: Colors.red),
                                  onPressed: () {
                                    _deleteGroup(grp['name']!);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(FontAwesomeIcons.plus,
                                      size: 18, color: Colors.blue),
                                  onPressed: () {
                                    _showAddSessionsDialog(grp['name']!);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to the Session screen with the group name
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SessionsScreen(
                                      groupName: grp[
                                          'name']!), // Pass group name to the new screen
                                ),
                              );
                            },
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

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempGroupName = ''; // Initially empty
        String tempGroupType = ''; // Initially empty

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Create Group',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group Name TextField
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter Group Name',
                ),
                onChanged: (value) {
                  tempGroupName = value;
                },
              ),
              SizedBox(height: 10),

              // Group Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Group Type'),
                value: tempGroupType.isEmpty ? null : tempGroupType,
                items: [
                  DropdownMenuItem(value: '', child: Text('Select Type')),
                  DropdownMenuItem(value: 'TD', child: Text('TD')),
                  DropdownMenuItem(value: 'TP', child: Text('TP')),
                ],
                onChanged: (value) =>
                    setState(() => tempGroupType = value ?? ''),
              ),
            ],
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),

            // Create Group Button
            ElevatedButton(
              onPressed: () {
                if (tempGroupName.isNotEmpty && tempGroupType.isNotEmpty) {
                  // Call your group creation logic here
                  // For example: _createGroup(tempGroupName, tempGroupType);

                  // After group creation, close the dialog
                  Navigator.pop(context);
                } else {
                  // Show a message to the user to enter valid data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in both fields!')),
                  );
                }
              },
              child: Text('Create Group'),
            ),
          ],
        );
      },
    );
  }

  void _showUpdateGroupDialog(String groupName, String groupType) {
    // Implement the same logic as create group dialog but pre-fill values for update
    showDialog(
      context: context,
      builder: (context) {
        String tempGroupName = groupName;
        String tempGroupType = groupType;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Update Group',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group Name TextField
              TextFormField(
                initialValue: tempGroupName,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter Group Name',
                ),
                onChanged: (value) {
                  tempGroupName = value;
                },
              ),
              SizedBox(height: 10),

              // Group Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Group Type'),
                value: tempGroupType.isEmpty ? null : tempGroupType,
                items: [
                  DropdownMenuItem(value: '', child: Text('Select Type')),
                  DropdownMenuItem(value: 'TD', child: Text('TD')),
                  DropdownMenuItem(value: 'TP', child: Text('TP')),
                ],
                onChanged: (value) =>
                    setState(() => tempGroupType = value ?? ''),
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
                // Logic to update the group
                Navigator.pop(context);
              },
              child: Text('Update Group'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGroup(String groupName) {
    // Implement the logic to delete the group
    setState(() {
      _allGroups.removeWhere((group) => group['name'] == groupName);
    });
  }

  void _showAddSessionsDialog(String groupName) {
    // Implement logic for adding sessions for the group
    showDialog(
      context: context,
      builder: (context) {
        String sessionName = '';
        DateTime startDate = DateTime.now();
        DateTime endDate = DateTime.now().add(Duration(days: 7));

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Sessions $groupName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Session Name',
                ),
                onChanged: (value) {
                  sessionName = value;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Start Date',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != startDate)
                    setState(() {
                      startDate = picked;
                    });
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'End Date',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != endDate)
                    setState(() {
                      endDate = picked;
                    });
                },
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
                // Logic to add the session
                Navigator.pop(context);
              },
              child: Text('Add Session'),
            ),
          ],
        );
      },
    );
  }
}

class SessionsScreen extends StatelessWidget {
  final String groupName;

  const SessionsScreen({required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sessions  $groupName'),
      ),
      body: Center(
        child: Text('Sessions  $groupName'),
      ),
    );
  }
}

///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
/*class SessionsScreen extends StatefulWidget {
  final String groupName; // Group name passed from GroupsScreen

  SessionsScreen({required this.groupName});

  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String _sessionName = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Function to save the session
  void _saveSession() {
    if (_sessionName.isNotEmpty && _startDate != null && _endDate != null) {
      // For now, just print the session details
      print("Session: $_sessionName");
      print("Start Date: $_startDate");
      print("End Date: $_endDate");

      // Optionally, save this session to a database or a list here

      // Navigate back after saving
      Navigator.pop(context);
    } else {
      // Show an alert if data is incomplete
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please fill in all fields."),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _sessionNameController,
              decoration: InputDecoration(labelText: 'Session Name'),
              onChanged: (value) {
                setState(() {
                  _sessionName = value;
                });
              },
            ),
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(labelText: 'Start Date'),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    _startDate = selectedDate;
                    _startDateController.text = selectedDate.toLocal().toString().split(' ')[0];
                  });
                }
              },
            ),
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(labelText: 'End Date'),
              onTap: () async {
                DateTime? selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selectedDate != null) {
                  setState(() {
                    _endDate = selectedDate;
                    _endDateController.text = selectedDate.toLocal().toString().split(' ')[0];
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSession,
              child: Text('Save Session'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////SESSION////////////////////////////////////////////////////////////////

class studentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("student ", style: TextStyle(fontSize: 24)),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Profile Screen", style: TextStyle(fontSize: 24)),
    );
  }
}
