import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../api_service.dart';
import 'sessions_screen.dart'; // Assuming SessionsScreen exists

class GroupsScreen extends StatefulWidget {
  final String className;
  final int classId;

  const GroupsScreen({required this.className, required this.classId});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String? error;
  String _sortBy = 'none';
  String _groupType = 'ALL';

  List<dynamic> groups = [];
  List<dynamic> _filteredGroups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _searchController.addListener(() {
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSessionDialog(int groupId) {
    final _dateController = TextEditingController();
    final _endDateController = TextEditingController();
    final _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add New Session',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Start Date & Time',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final datetime = DateTime(date.year, date.month,
                                date.day, time.hour, time.minute);
                            _dateController.text = datetime.toString();
                          }
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _endDateController,
                  decoration: InputDecoration(
                    labelText: 'End Date & Time',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final datetime = DateTime(date.year, date.month,
                                date.day, time.hour, time.minute);
                            _endDateController.text = datetime.toString();
                          }
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: 'Comments',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Add Session'),
              onPressed: () async {
                if (_dateController.text.isEmpty ||
                    _endDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select dates')));
                  return;
                }

                try {
                  final sessionData = {
                    's_date': _dateController.text,
                    'end_date': _endDateController.text,
                    'comment': _commentController.text,
                  };

                  await ApiService.createSession(groupId, sessionData);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Session added successfully')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add session: $e')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSessionsList(int groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Sessions for $groupName'),
          ),
          body: FutureBuilder<List<dynamic>>(
            future: ApiService.getSessionsByGroup(groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final sessions = snapshot.data ?? [];

              if (sessions.isEmpty) {
                return Center(child: Text('No sessions found'));
              }

              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        '${DateTime.parse(session['s_date']).toString()} - '
                        '${DateTime.parse(session['end_date']).toString()}',
                      ),
                      subtitle: Text(session['comment'] ?? 'No comments'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmDeleteSession(session['id'], groupId),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () => _showAddSessionDialog(groupId),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSession(int sessionId, int groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteSession(sessionId, groupId);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Session deleted')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete session: $e')));
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Dans votre GroupsScreen ou où vous affichez la liste des groupes
  void _onGroupTapped(Map<String, dynamic> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          groupId: group['id'], // Assurez-vous que c'est bien un int
          groupName: group['name'], // Le nom du groupe
        ),
      ),
    );
  }

  Future<void> _loadGroups() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Use the new method to get groups for this specific class
      groups = (await ApiService.getGroupsByClass(widget.classId));
      _applyFilters();
    } catch (e) {
      error = e.toString();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilters() {
    final lowerQuery = _searchController.text.toLowerCase();
    List<dynamic> temp = groups.where((group) {
      final matchesType = _groupType == 'ALL' || group['type'] == _groupType;
      final matchesName = _searchController.text.isEmpty ||
          group['name'].toString().toLowerCase().contains(lowerQuery);
      return matchesType && matchesName;
    }).toList();

    if (_sortBy == 'name') {
      temp.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    }

    setState(() {
      _filteredGroups = temp;
    });
  }

  void _showCreateGroupDialog() {
    final _nameController = TextEditingController();
    String tempTypeAge = '';
    String tempGender = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Center(
                child: Text(
                  'إضافة فوج جديد',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_nameController, 'إسم الفوج *'),
                    SizedBox(height: 12),

                    // نوع الفوج
                    Text('نوع الفوج', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['كبار', 'صغار', 'مختلط'].map((val) {
                        final selected = tempTypeAge == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: selected,
                          selectedColor: Colors.cyan,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(() => tempTypeAge = val),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 14),

                    // الجنس
                    Text('الجنس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['ذكور', 'إناث', 'مختلط'].map((val) {
                        final selected = tempGender == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: selected,
                          selectedColor: Colors.cyan,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(() => tempGender = val),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('إلغاء'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('إنشاء', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إدخال اسم الفوج')),
                      );
                      return;
                    }

                    final newGroup = {
                      'name':     _nameController.text.trim(),
                      'type_age': tempTypeAge.isEmpty ? null : tempTypeAge,
                      'gender':   tempGender.isEmpty  ? null : tempGender,
                      'class_id': widget.classId,
                    };

                    try {
                      await ApiService.createGroup(widget.classId, newGroup);
                      Navigator.pop(context);
                      _loadGroups();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل إنشاء الفوج: ${e.toString()}')),
                      );
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

  void _showEditGroupDialog(Map<String, dynamic> group) {
    final _nameController = TextEditingController(text: group['name'] ?? '');
    String tempTypeAge = group['type_age'] ?? '';
    String tempGender = group['gender'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Center(
                child: Text(
                  'تعديل الفوج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_nameController, 'إسم الفوج *'),
                    SizedBox(height: 12),

                    // نوع الفوج
                    Text('نوع الفوج', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['كبار', 'صغار', 'مختلط'].map((val) {
                        final selected = tempTypeAge == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: selected,
                          selectedColor: Colors.cyan,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(() => tempTypeAge = val),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 14),

                    // الجنس
                    Text('الجنس', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['ذكور', 'إناث', 'مختلط'].map((val) {
                        final selected = tempGender == val;
                        return ChoiceChip(
                          label: Text(val),
                          selected: selected,
                          selectedColor: Colors.cyan,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setDialogState(() => tempGender = val),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('إلغاء'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إدخال اسم الفوج')),
                      );
                      return;
                    }

                    final updatedGroup = {
                      'name':     _nameController.text.trim(),
                      'type_age': tempTypeAge.isEmpty ? null : tempTypeAge,
                      'gender':   tempGender.isEmpty  ? null : tempGender,
                    };

                    try {
                      await ApiService.updateGroup(widget.classId, group['id'], updatedGroup);
                      Navigator.pop(context);
                      _loadGroups();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل تعديل الفوج: ${e.toString()}')),
                      );
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
                await ApiService.deleteGroup(widget.classId, groupId);
                _loadGroups();
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
                  border: UnderlineInputBorder(),
                ),
                value: tempSortBy,
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
                  border: UnderlineInputBorder(),
                ),
                value: tempGroupType,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.className,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
                      // Search & Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search group...',
                                prefixIcon: Icon(FontAwesomeIcons.search,
                                    color: Colors.cyan, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(FontAwesomeIcons.xmark,
                                            color: Colors.blueGrey.shade700,
                                            size: 18),
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
                              icon: Icon(FontAwesomeIcons.sliders,
                                  color: Colors.cyan, size: 20),
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
                              onPressed: _showCreateGroupDialog,
                              icon: Icon(FontAwesomeIcons.plus, size: 16),
                              label: Text(
                                'إضافة فوج',
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
                              '${_filteredGroups.length} فوج',
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
                        child: _filteredGroups.isEmpty
                            ? Center(
                                child: Text('No matching groups found',
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
                                        title: Text(group['name'] ?? '',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if ((group['type_age'] ?? '').toString().isNotEmpty)
                                                Row(children: [
                                                  SizedBox(width: 4),
                                                  Text('نوع الفوج: ${group['type_age']}', style: TextStyle(fontSize: 13)),
                                                ]),
                                              if ((group['gender'] ?? '').toString().isNotEmpty)
                                                Row(children: [
                                                  Icon(Icons.people, size: 14, color: Colors.cyan.shade700),
                                                  SizedBox(width: 4),
                                                  Text('الجنس: ${group['gender']}', style: TextStyle(fontSize: 13)),
                                                ]),
                                              if ((group['type_age'] ?? '').toString().isEmpty && (group['gender'] ?? '').toString().isEmpty)
                                                Text('لا توجد تفاصيل إضافية', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                  FontAwesomeIcons.calendar,
                                                  size: 18,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                final id = group['id'] is int
                                                    ? group['id']
                                                    : (group['id'] is String
                                                        ? int.tryParse(
                                                            group['id'])
                                                        : null);
                                                if (id != null) {
                                                  _showSessionsList(
                                                      id, group['name'] ?? '');
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Invalid group ID')),
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.pen,
                                                  size: 18, color: Colors.teal),
                                              onPressed: () =>
                                                  _showEditGroupDialog(group),
                                            ),
                                            IconButton(
                                              icon: Icon(FontAwesomeIcons.trash,
                                                  size: 18, color: Colors.red),
                                              onPressed: () {
                                                final id = group['id'] is int
                                                    ? group['id']
                                                    : (group['id'] is String
                                                        ? int.tryParse(
                                                            group['id'])
                                                        : null);
                                                if (id != null) {
                                                  _confirmDeleteGroup(id);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Invalid group ID')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
// Par exemple, dans votre ListView.builder ou autre widget qui affiche les groupes
                                        onTap: () => _onGroupTapped(group),
                                      ));
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
