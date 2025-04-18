// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'add_edit_diag.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
      ),
      home: const ClassDashboard(),
    );
  }
}

class ClassDashboard extends StatefulWidget {
  const ClassDashboard({super.key});

  @override
  State<ClassDashboard> createState() => _ClassDashboardState();
}

class _ClassDashboardState extends State<ClassDashboard> {
  List<dynamic> classes = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _refreshClasses();
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

  Widget _buildCard(Map<String, dynamic> classItem) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, 4),
            blurRadius: 6,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classItem['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Specialty: ${classItem['speciality']} | Level: ${classItem['level']} | Year: ${classItem['year']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditDialog(classItem),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(classItem['id']),
                    ),
                  ],
                )
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.calendar_today, color: Colors.teal),
              const SizedBox(height: 4),
              Text(classItem['created_at']?.substring(0, 10) ?? ''),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        elevation: 0,
        centerTitle: true,
        title: const Text('Class Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search class...',
                      prefixIcon: const Icon(Icons.search, color: Colors.cyan),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.filter_alt, color: Colors.cyan),
                        onPressed: () {},
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Create New button
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Create New Class"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Class Cards list
                  Expanded(
                    child: classes.isEmpty
                        ? const Center(child: Text('No classes available'))
                        : ListView.builder(
                            itemCount: classes.length,
                            itemBuilder: (context, index) {
                              final item = classes[index];
                              return GestureDetector(
                                onTap: () => _showAddEditDialog(item),
                                onLongPress: () => _confirmDelete(item['id']),
                                child: _buildCard(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.cyan,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}
