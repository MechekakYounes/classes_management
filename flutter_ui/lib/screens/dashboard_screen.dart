import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../api_service.dart';
import '../auth_service.dart';
import 'groups_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int? communeId;
  final String? communeName;
  const DashboardScreen({Key? key, this.communeId, this.communeName}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> specialities = [];
  List<String> levels = [];
  List<String> years = [];
  String _sortBy = '';
  String _specialty = '';
  String _year = '';
  String _level = '';
  bool isLoading = true;
  String? error;
  List<dynamic> classes = [];

  // Fetch classes and update filters
  Future<void> fetchClassesAndUpdateFilters() async {
    try {
      List classes = await ApiService.getClasses(communeId: widget.communeId);

      // Extract unique specialities and years from the classes
      Set<String> specialities = Set();
      Set<String> levels = Set();
      Set<String> years = Set();
      for (var classData in classes) {
        if (classData['speciality'] != null)
          specialities.add(classData['speciality']);
        if (classData['level'] != null) levels.add(classData['level']);
        if (classData['year'] != null) years.add(classData['year']);
      }

      setState(() {
        availableSpecialities = specialities;
        availablelevel = levels;
        availableYears = years;
      });
    } catch (e) {}
  }

  List<Map<dynamic, dynamic>> _allClasses = [];
  List<Map<dynamic, dynamic>> _filteredClasses = [];

// To hold the unique specialities and years
  Set<String> availableSpecialities = Set();
  Set<String> availableYears = Set();
  Set<String> availablelevel = Set();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {});
      specialities = classes
          .map((cls) => cls['speciality']?.toString() ?? '')
          .toSet()
          .toList();
      years =
          classes.map((cls) => cls['year']?.toString() ?? '').toSet().toList();
      levels =
          classes.map((cls) => cls['level']?.toString() ?? '').toSet().toList();
    });
  }

  @override
  @override
  void dispose() {
    super.dispose();

    fetchClassesAndUpdateFilters();
  }

  void fetchFilterOptions() {
    specialities = _allClasses
        .map((cls) => cls['speciality']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    years = _allClasses
        .map((cls) => cls['year']?.toString() ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList();
    levels = _allClasses
        .map((cls) => cls['level']?.toString() ?? '')
        .where((y) => y.isNotEmpty)
        .toSet()
        .toList();

    availableSpecialities = Set.from(specialities);
    availableYears = Set.from(years);
    availablelevel = Set.from(levels);
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final fetchedClasses = await ApiService.getClasses(communeId: widget.communeId);
      final convertedClasses = fetchedClasses.map<Map<dynamic, dynamic>>((cls) {
        return Map<dynamic, dynamic>.from(cls).map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
      }).toList();

      setState(() {
        classes = fetchedClasses;
        _allClasses = convertedClasses;
        _filteredClasses = List.from(_allClasses);
        fetchFilterOptions();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print('Error loading classes: $e');
    }
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
              try {
                await ApiService.deleteClass(id);
                _loadData();
              } catch (e) {
                // Show error to user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete class: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(Map<dynamic, dynamic> classToEdit) {
    final _nameController = TextEditingController(text: classToEdit['name'] ?? '');
    final _addressController = TextEditingController(text: classToEdit['address'] ?? '');
    final _emailController = TextEditingController(text: classToEdit['email'] ?? '');
    final _phoneController = TextEditingController(text: classToEdit['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              'تعديل المدرسة',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan.shade800),
            ),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(_nameController, 'اسم المدرسة *', icon: FontAwesomeIcons.school),
                  _buildTextField(_addressController, 'العنوان / الحي', icon: FontAwesomeIcons.locationDot),
                  _buildTextField(_emailController, 'البريد الإلكتروني', icon: FontAwesomeIcons.envelope, keyboardType: TextInputType.emailAddress),
                  _buildTextField(_phoneController, 'رقم الهاتف', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone),
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
              child: Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى إدخال اسم المدرسة')));
                  return;
                }
                final int classId = int.tryParse(classToEdit['id'].toString()) ?? 0;
                if (classId == 0) return;
                try {
                  await ApiService.updateClass(classId, {
                    'name':    _nameController.text.trim(),
                    'address': _addressController.text.trim(),
                    'email':   _emailController.text.trim(),
                    'phone':   _phoneController.text.trim(),
                  });
                  fetchClassesAndUpdateFilters();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء التعديل: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }



  void _applyFiltersclass() {
    List<Map<dynamic, dynamic>> temp = _allClasses.where((cls) {
      final matchesSpecialty =
          _specialty.isEmpty || cls['speciality'] == _specialty;
      final matchesYear = _year.isEmpty || cls['year'] == _year;
      final matchesLevel =
          _level.isEmpty || cls['level'] == _level; // Added level filter

      return matchesSpecialty &&
          matchesYear &&
          matchesLevel; // Include the level in the filter logic
    }).toList();

    // Sorting logic
    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name']!.compareTo(b['name']!));
    } else if (_sortBy == 'time') {
      // Ensure 'time' is parsed to DateTime before sorting
      temp.sort((a, b) {
        final timeA = DateTime.tryParse(a['time'] ?? '') ?? DateTime.now();
        final timeB = DateTime.tryParse(b['time'] ?? '') ?? DateTime.now();
        return timeA.compareTo(timeB);
      });
    }

    setState(() {
      _filteredClasses = temp;
    });
  }

  @override
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;
        String tempSpeciality = _specialty;
        String tempYear = _year;
        String tempLevel = _level;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Filter Options',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sort By Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Sort by'),
                value: tempSortBy.isEmpty ? null : tempSortBy,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'time', child: Text('Time Added')),
                ],
                onChanged: (value) => setState(() => tempSortBy = value ?? ''),
              ),

              // Speciality Dropdown - dynamically populated based on available specialities
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Speciality'),
                value: tempSpeciality.isEmpty ? null : tempSpeciality,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availableSpecialities.map((speciality) {
                    return DropdownMenuItem(
                        value: speciality, child: Text(speciality));
                  }).toList(),
                ],
                onChanged: (value) =>
                    setState(() => tempSpeciality = value ?? ''),
              ),

              // Year Dropdown - dynamically populated based on available years
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Year'),
                value: tempYear.isEmpty ? null : tempYear,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availableYears.map((year) {
                    return DropdownMenuItem(value: year, child: Text(year));
                  }).toList(),
                ],
                onChanged: (value) => setState(() => tempYear = value ?? ''),
              ),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Level'),
                value: tempLevel.isEmpty ? null : tempLevel,
                items: [
                  DropdownMenuItem(value: '', child: Text('None')),
                  ...availablelevel.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    tempLevel = value ?? ''; // Update selected level
                    _applyFiltersclass(); // Apply the filter after selection
                  });
                },
              ),

              SizedBox(height: 10),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _sortBy = tempSortBy;
                  _specialty = tempSpeciality;
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
      _filteredClasses = _allClasses.where((cls) {
        return cls['name']!.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _showClassDetailsDialog(Map<String, dynamic> cls) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(
            child: Text(
              cls['name'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Speciality', cls['speciality']),
              _buildInfoRow('Level', cls['level']),
              _buildInfoRow('Semester', cls['semester']),
              _buildInfoRow('Year', cls['year']),
              _buildInfoRow(
                  'Created At', cls['created_at']?.substring(0, 10) ?? ''),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close', style: TextStyle(color: Colors.cyan)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    String appBarTitle;

    if (auth.isSupervisor()) {
      // Supervisor: always use their own commune name
      final cName = auth.communeName ?? '';
      appBarTitle = cName.isNotEmpty ? 'مدارس ($cName)' : 'المدارس';
    } else if (widget.communeName != null && widget.communeName!.isNotEmpty) {
      // Admin / SuperAdmin navigated to a specific Baladiya
      appBarTitle = 'مدارس ${widget.communeName}';
    } else {
      appBarTitle = 'Class Dashboard';
    }

    return Scaffold(
          appBar: AppBar(

        title: Text(

          appBarTitle,

          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 23),

        ),

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
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            height: 45,
                            child: ElevatedButton.icon(
                              onPressed: _showCreateClassDialog,
                              icon: Icon(FontAwesomeIcons.plus, size: 16),
                              label: Text(
                                'إضافة مدرسة',
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
                              '${_filteredClasses.length} مدرسة',
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
                                      onTap: () {
                                        // Convert the classId to int if it's a string
                                        final id = cls['id'] is int
                                            ? cls['id']
                                            : (cls['id'] is String
                                                ? int.tryParse(cls['id'])
                                                : null);

                                        if (id != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GroupsScreen(
                                                className: cls['name'],
                                                classId: id,
                                                // Now passing a properly converted int
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Invalid class ID')),
                                          );
                                        }
                                      },
                                      contentPadding: EdgeInsets.all(16),
                                      title: Text(
                                        cls['name'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 2.0),
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (cls['speciality'] != null && cls['speciality'].toString().isNotEmpty)
                                                Text(
                                                  'التخصص: ${cls['speciality']}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              if (cls['semester'] != null && cls['semester'].toString().isNotEmpty)
                                                Text(
                                                  'الفصل: ${cls['semester']}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              Text(
                                                'السنة: ${cls['year']}',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(FontAwesomeIcons.calendar,
                                                  size: 18,
                                                  color: Colors.black54),
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
                                                icon: Icon(FontAwesomeIcons.pen,
                                                    size: 18,
                                                    color: Colors.teal),
                                                onPressed: () =>
                                                    _showEditClassDialog(cls),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                    FontAwesomeIcons.trash,
                                                    size: 18,
                                                    color: Colors.red),
                                                onPressed: () {
                                                  // Check the type of cls['id'] and handle appropriately
                                                  final id = cls['id'] is int
                                                      ? cls['id']
                                                      : (cls['id'] is String
                                                          ? int.tryParse(
                                                              cls['id'])
                                                          : null);

                                                  if (id != null) {
                                                    _confirmDelete(id);
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Invalid class ID')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      onLongPress: () =>
                                          _showClassDetailsDialog(
                                              Map<String, dynamic>.from(cls)),
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

  void _showCreateClassDialog() async {
    final _nameController = TextEditingController();
    final _addressController = TextEditingController();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();

    // Inline manager fields
    final _mgrNameController = TextEditingController();
    final _mgrUsernameController = TextEditingController();
    final _mgrPasswordController = TextEditingController();
    final _mgrPhoneController = TextEditingController();

    List<dynamic> unassignedManagers = [];
    int? selectedManagerId;
    bool createNewManager = false;
    bool isDialogLoading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load unassigned managers on dialog open
            if (isDialogLoading) {
              ApiService.getUnassignedManagers().then((list) {
                setDialogState(() {
                  unassignedManagers = list;
                  isDialogLoading = false;
                });
              }).catchError((_) {
                setDialogState(() => isDialogLoading = false);
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Center(
                child: Text(
                  'إضافة مدرسة جديدة',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.cyan.shade800),
                ),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(_nameController, 'اسم المدرسة *', icon: FontAwesomeIcons.school),
                      _buildTextField(_addressController, 'العنوان / الحي *', icon: FontAwesomeIcons.locationDot),
                      _buildTextField(_emailController, 'البريد الإلكتروني للمدرسة *', icon: FontAwesomeIcons.envelope, keyboardType: TextInputType.emailAddress),
                      _buildTextField(_phoneController, 'رقم هاتف المدرسة (اختياري)', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone),
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 8),
                      Text(
                        'مدير المدرسة',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyan.shade900),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Text('مدير موجود'),
                              selected: !createNewManager,
                              selectedColor: Colors.cyan,
                              labelStyle: TextStyle(color: !createNewManager ? Colors.white : Colors.cyan.shade900),
                              onSelected: (val) {
                                setDialogState(() => createNewManager = !val);
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: Text('+ حساب جديد'),
                              selected: createNewManager,
                              selectedColor: Colors.cyan,
                              labelStyle: TextStyle(color: createNewManager ? Colors.white : Colors.cyan.shade900),
                              onSelected: (val) {
                                setDialogState(() => createNewManager = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (!createNewManager) ...[
                        isDialogLoading
                            ? Center(child: CircularProgressIndicator())
                            : DropdownButtonFormField<int>(
                                value: selectedManagerId,
                                decoration: InputDecoration(
                                  labelText: 'اختر مديراً شاغراً',
                                  prefixIcon: Icon(FontAwesomeIcons.userTie, color: Colors.cyan, size: 18),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: [
                                  DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('بدون مدير حالياً', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ...unassignedManagers.map((m) {
                                    return DropdownMenuItem<int>(
                                      value: m['id'],
                                      child: Text(m['name'] ?? m['username']),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (val) {
                                  setDialogState(() => selectedManagerId = val);
                                },
                              ),
                      ] else ...[
                        _buildTextField(_mgrNameController, 'اسم المدير الكامل *', icon: FontAwesomeIcons.user),
                        _buildTextField(_mgrUsernameController, 'اسم المستخدم (Username) *', icon: FontAwesomeIcons.at),
                        _buildTextField(_mgrPasswordController, 'كلمة المرور *', icon: FontAwesomeIcons.lock, obscureText: true),
                        _buildTextField(_mgrPhoneController, 'هاتف المدير (اختياري)', icon: FontAwesomeIcons.phone, keyboardType: TextInputType.phone),
                      ],
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
                  child: Text('إضافة المدرسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى إدخال اسم المدرسة')));
                      return;
                    }

                    Map<String, dynamic> newClassData = {
                      'name': _nameController.text.trim(),
                      'address': _addressController.text.trim(),
                      'email': _emailController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'commune_id': widget.communeId,
                    };

                    if (!createNewManager && selectedManagerId != null) {
                      newClassData['manager_id'] = selectedManagerId;
                    } else if (createNewManager) {
                      if (_mgrUsernameController.text.trim().isEmpty || _mgrPasswordController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور للمدير')));
                        return;
                      }
                      newClassData['new_manager'] = {
                        'name': _mgrNameController.text.trim().isNotEmpty ? _mgrNameController.text.trim() : '${_nameController.text} Manager',
                        'username': _mgrUsernameController.text.trim(),
                        'password': _mgrPasswordController.text.trim(),
                        'phone': _mgrPhoneController.text.trim(),
                      };
                    }

                    try {
                      await ApiService.createClass(newClassData);
                      fetchClassesAndUpdateFilters();
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء إضافة المدرسة: $e')));
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

  String formatDate(dynamic dateStr) {
    if (dateStr is String && dateStr.length >= 10) {
      return dateStr.substring(0, 10);
    }
    return '';
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
}
