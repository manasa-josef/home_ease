import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';

class ModernNewTaskPage extends StatefulWidget {
  final String userId;

  const ModernNewTaskPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ModernNewTaskPage> createState() => _ModernNewTaskPageState();
}

class _ModernNewTaskPageState extends State<ModernNewTaskPage> {
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
          'userId': user.uid,
          'roomId': _selectedRoomId,
          'title': _titleController.text.trim(),
          'notes': _notesController.text.trim(),
          'date': finalDateTime != null ? Timestamp.fromDate(finalDateTime) : null,
          'reminder': _enableReminder,
          'repeat': _repeatOption,
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
        };

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
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in to select a room')),
    );
    return;
  }

  await showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data?.docs ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text('No rooms found. Please create a room first.'),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final roomData = room.data() as Map<String, dynamic>;
              final roomName = roomData['name'] as String;
              final roomIcon = roomData['icon'] ?? Icons.room_outlined;

              return ListTile(
                title: Text(roomName, style: Theme.of(context).textTheme.titleMedium),
                leading: Icon(roomIcon is IconData ? roomIcon : IconData(
                  int.parse(roomIcon.toString()),
                  fontFamily: 'MaterialIcons',
                )),
                trailing: const Icon(Icons.chevron_right),
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
  );
}

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        child: child!,
      ),
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        child: child!,
      ),
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
        title: const Text('Create New Task'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: child,
                  ),
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    prefixIcon: const Icon(Icons.title),
                    suffixIcon: TextButton(
                      onPressed: () {},
                      child: const Text('Preset'),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Room Selection
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(
                    _selectedRoomName ?? 'Select Room',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectRoom,
                ),
              ),
              const SizedBox(height: 16),
              // Repeat
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.repeat_rounded),
                  title: const Text('Repeat'),
                  trailing: Text(
                    _repeatOption,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Repeat Frequency'),
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
              ),
              const SizedBox(height: 16),
              // Reminder
              SwitchListTile(
                title: const Text('Enable Reminder'),
                secondary: const Icon(Icons.alarm_rounded),
                value: _enableReminder,
                onChanged: (bool value) {
                  setState(() {
                    _enableReminder = value;
                  });
                },
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month_rounded),
                        title: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_rounded),
                        title: Text(
                          _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),
                crossFadeState: _enableReminder
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Create Task'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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