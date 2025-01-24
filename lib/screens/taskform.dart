import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskFormPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String userId;

  const TaskFormPage({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeatOption = 'Never';
  bool _enableReminder = false;

  final List<String> _repeatOptions = [
    'Never',
    'Every day',
    'Every week',
    'Every month',
  ];

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final DateTime? finalDateTime = _selectedDate != null && _selectedTime != null
            ? DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
                _selectedTime!.hour,
                _selectedTime!.minute,
              )
            : null;

        final taskData = {
          'userId': widget.userId,
          'roomId': widget.roomId,
          'title': _titleController.text.trim(),
          'notes': _notesController.text.trim(),
          'date': finalDateTime != null ? Timestamp.fromDate(finalDateTime) : null,
          'reminder': _enableReminder,
          'repeat': _repeatOption,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('tasks').add(taskData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task saved successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  suffixIcon: TextButton(
                    onPressed: () {
                      // Add preset functionality here if needed
                    },
                    child: const Text('Use Preset'),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Room
              ListTile(
                leading: const Icon(Icons.room),
                title: const Text('Room'),
                subtitle: Text(widget.roomName),
              ),

              // Repeat
              ListTile(
                leading: const Icon(Icons.repeat),
                title: const Text('Repeat'),
                subtitle: Text(_repeatOption),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('Repeat'),
                      children: _repeatOptions
                          .map(
                            (option) => SimpleDialogOption(
                              onPressed: () {
                                setState(() => _repeatOption = option);
                                Navigator.pop(context);
                              },
                              child: Text(option),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),

              // Reminder
              SwitchListTile(
                title: const Text('Reminder'),
                value: _enableReminder,
                onChanged: (bool value) {
                  setState(() {
                    _enableReminder = value;
                  });
                },
              ),
              if (_enableReminder) ...[
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  ),
                  onTap: _selectDate,
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    _selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context),
                  ),
                  onTap: _selectTime,
                ),
              ],
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
