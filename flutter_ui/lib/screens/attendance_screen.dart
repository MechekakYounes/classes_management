import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../api_service.dart';

class AttendanceScreen extends StatefulWidget {
  final int sessionId;
  final int groupId;
  final String sessionDate;

  const AttendanceScreen({
    Key? key,
    required this.sessionId,
    required this.groupId,
    required this.sessionDate,
  }) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> students = [];
  Map<int, String> attendanceStatus = {};
  bool hasUnsavedChanges = false;
  List<dynamic> existingAttendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  static AttendanceScreen fromArguments(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return AttendanceScreen(
      sessionId: args['sessionId'],
      groupId: args['groupId'],
      sessionDate: args['sessionDate'],
    );
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Load students for this group
      final studentsData = await ApiService.getStudentsByGroup(widget.groupId);

      // Load existing attendance records for this session
      final attendanceData =
          await ApiService.getAttendanceBySession(widget.sessionId);

      // Store the existing attendance records for later use during updates
      existingAttendanceRecords = attendanceData;

      // Initialize attendance status map
      Map<int, String> status = {};
      for (var student in studentsData) {
        int studentId = int.parse(student['id'].toString());

        // Find if student has existing attendance record
        var existingRecord = attendanceData.firstWhere(
          (record) => int.parse(record['student_id'].toString()) == studentId,
          orElse: () => null,
        );

        // Set status based on existing record or default to 'absent'
        if (existingRecord != null) {
          status[studentId] = existingRecord['status'] ?? 'absent';
        } else {
          status[studentId] = 'absent';
        }
      }

      setState(() {
        students = studentsData;
        attendanceStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  Future<void> _saveAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare attendance data
      List<Map<String, dynamic>> attendanceData = [];

      // Build the list of attendance records from the attendance status map
      attendanceStatus.forEach((studentId, status) {
        attendanceData.add({
          'student_id': studentId,
          'session_id': widget.sessionId,
          'status': status,
        });
      });

      print('Saving attendance for ${attendanceData.length} students');

      // Call the bulk create/update method with the session ID and attendance data
      final result = await ApiService.bulkCreateAttendance(
          widget.sessionId, attendanceData);

      // Refresh attendance data after saving
      await _loadAttendanceData();

      setState(() {
        isLoading = false;
        hasUnsavedChanges = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Attendance saved successfully'),
          backgroundColor:
              result['status'] == 'partial' ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print('Error in _saveAttendance: $e');

      setState(() {
        isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleAttendance(int studentId) {
    setState(() {
      // Cycle through the statuses: absent -> present -> justified -> absent
      switch (attendanceStatus[studentId]) {
        case 'absent':
          attendanceStatus[studentId] = 'present';
          break;
        case 'present':
          attendanceStatus[studentId] = 'justified';
          break;
        case 'justified':
          attendanceStatus[studentId] = 'absent';
          break;
        default:
          attendanceStatus[studentId] = 'present';
      }
      hasUnsavedChanges = true;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var student in students) {
        int studentId = int.parse(student['id'].toString());
        attendanceStatus[studentId] = 'present';
      }
      hasUnsavedChanges = true;
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var student in students) {
        int studentId = int.parse(student['id'].toString());
        attendanceStatus[studentId] = 'absent';
      }
      hasUnsavedChanges = true;
    });
  }

  void _markAllJustified() {
    setState(() {
      for (var student in students) {
        int studentId = int.parse(student['id'].toString());
        attendanceStatus[studentId] = 'justified';
      }
      hasUnsavedChanges = true;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red.shade300;
      case 'justified':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return FontAwesomeIcons.check;
      case 'absent':
        return FontAwesomeIcons.xmark;
      case 'justified':
        return FontAwesomeIcons.fileLines;
      default:
        return FontAwesomeIcons.question;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (hasUnsavedChanges) {
          // Show dialog to confirm leaving without saving
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                  'You have unsaved attendance changes. Do you want to save before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Leave Without Saving'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _saveAttendance();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Save and Leave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Take Attendance'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.floppyDisk),
              onPressed: _saveAttendance,
              tooltip: 'Save Attendance',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text('Error: $error'))
                : Column(
                    children: [
                      _buildSessionInfo(),
                      _buildActionButtons(),
                      _buildAttendanceLegend(),
                      Expanded(
                        child: _buildStudentsList(),
                      ),
                    ],
                  ),
        bottomNavigationBar: hasUnsavedChanges
            ? Container(
                color: Colors.amber.shade100,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Text('You have unsaved changes',
                        style: TextStyle(color: Colors.amber.shade900)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _saveAttendance,
                      child: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSessionInfo() {
    // Count the number of each status
    int presentCount =
        attendanceStatus.values.where((status) => status == 'present').length;
    int justifiedCount =
        attendanceStatus.values.where((status) => status == 'justified').length;
    int absentCount =
        attendanceStatus.values.where((status) => status == 'absent').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.calendarDay, color: Colors.cyan),
              const SizedBox(width: 12),
              Text(
                widget.sessionDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Students: ${students.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Present: $presentCount',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Justified: $justifiedCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Absent: $absentCount',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.check, size: 16),
              label: const Text('All Present'),
              onPressed: _markAllPresent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.fileLines, size: 16),
              label: const Text('All Justified'),
              onPressed: _markAllJustified,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(FontAwesomeIcons.xmark, size: 16),
              label: const Text('All Absent'),
              onPressed: _markAllAbsent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.xmark,
                  size: 12, color: Colors.red.shade300),
              const Text(' Absent '),
              const Icon(FontAwesomeIcons.rightLong,
                  size: 12, color: Colors.grey),
              const Text(' Present '),
              Icon(FontAwesomeIcons.check, size: 12, color: Colors.green),
              const Icon(FontAwesomeIcons.rightLong,
                  size: 12, color: Colors.grey),
              const Text(' Justified '),
              Icon(FontAwesomeIcons.fileLines, size: 12, color: Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.userGroup,
                size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No students in this group',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final studentId = int.parse(student['id'].toString());
        final status = attendanceStatus[studentId] ?? 'absent';
        final statusColor = _getStatusColor(status);
        final statusIcon = _getStatusIcon(status);

        return GestureDetector(
          onTap: () => _toggleAttendance(studentId),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: statusColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.cyan.shade100,
                child: Text(
                  '${student['fname']?[0]}${student['name']?[0]}',
                  style: TextStyle(color: Colors.cyan.shade800),
                ),
              ),
              title: Text(
                '${student['fname']} ${student['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(student['email'] ?? 'No email'),
              trailing: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
