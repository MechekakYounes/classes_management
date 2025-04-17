import 'package:flutter/material.dart';

class AddEditClassDialog extends StatefulWidget {
  final Map<String, dynamic>? classToEdit;
  final Function(Map<String, dynamic>) onSave;

  const AddEditClassDialog({
    super.key,
    this.classToEdit,
    required this.onSave,
  });

  @override
  _AddEditClassDialogState createState() => _AddEditClassDialogState();
}

class _AddEditClassDialogState extends State<AddEditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _classNameController;
  late TextEditingController _specialtyController;
  late TextEditingController _levelController;
  late TextEditingController _yearController;
  late TextEditingController _semesterController;

  @override
  void initState() {
    super.initState();
    _classNameController =
        TextEditingController(text: widget.classToEdit?['name']);
    _specialtyController =
        TextEditingController(text: widget.classToEdit?['speciality']);
    _levelController =
        TextEditingController(text: widget.classToEdit?['level']);
    _yearController = TextEditingController(text: widget.classToEdit?['year']);
    _semesterController =
        TextEditingController(text: widget.classToEdit?['semester']);
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _specialtyController.dispose();
    _levelController.dispose();
    _yearController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.classToEdit == null ? 'Add Class' : 'Edit Class'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _classNameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(labelText: 'Level'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(labelText: 'Semester'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final classData = {
                'name': _classNameController.text,
                'speciality': _specialtyController.text,
                'level': _levelController.text,
                'year': _yearController.text,
                'semester': _semesterController.text,
              };
              widget.onSave(classData);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
