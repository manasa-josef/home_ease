import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewTaskPage extends StatefulWidget {
  final String userId;

  const NewTaskPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NewTaskPage> createState() => _NewTaskPageState();
}

class _NewTaskPageState extends State<NewTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _repeatOption = 'Never';
  bool _enableReminder = false;
  String? _selectedRoomId;
  String? _selectedRoomName;

  final List<String> _repeatOptions = [
    'Never',
    'Every day',
    'Every week',
    'Every month',
  ];

   Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a room')),
        );
        return;
      }

      try {
        // Check if user is authenticated
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to create tasks')),
          );
          return;
        }

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
          'userId': user.uid, // Use the authenticated user's ID
          'roomId': _selectedRoomId,
          'title': _titleController.text.trim(),
          'notes': _notesController.text.trim(),
          'date': finalDateTime != null ? Timestamp.fromDate(finalDateTime) : null,
          'reminder': _enableReminder,
          'repeat': _repeatOption,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Add error handling for permission denied
        try {
          await FirebaseFirestore.instance.collection('tasks').add(taskData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Task saved successfully!')),
            );
            Navigator.pop(context);
          }
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You don\'t have permission to create tasks in this room'),
              ),
            );
          } else {
            throw e;
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  Future<void> _selectRoom() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = snapshot.data?.docs ?? [];

            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomData = room.data() as Map<String, dynamic>;
                final roomName = roomData['name'] as String;

                return ListTile(
                  title: Text(roomName),
                  onTap: () {
                    setState(() {
                      _selectedRoomId = room.id;
                      _selectedRoomName = roomName;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
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

              // Room Selection
              ListTile(
                leading: const Icon(Icons.room),
                title: const Text('Room'),
                subtitle: Text(_selectedRoomName ?? 'Select a room'),
                onTap: _selectRoom,
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