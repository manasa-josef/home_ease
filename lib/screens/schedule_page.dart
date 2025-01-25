import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  final String userId;
  const SchedulePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _monthDates = [];

  @override
  void initState() {
    super.initState();
    _generateMonthDates();
  }

  void _generateMonthDates() {
    // Generate all dates for the current month
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    _monthDates = List.generate(
      lastDayOfMonth.day,
      (index) => firstDayOfMonth.add(Duration(days: index)),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Stream<List<Task>> _getTasksForDate(DateTime date) {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: widget.userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Task.fromFirestore(doc);
                } catch (e) {
                  debugPrint("Error parsing task: $e");
                  return null;
                }
              })
              .where((task) => task != null && _shouldShowTask(task!, date))
              .cast<Task>()
              .toList();
        });
  }

  bool _shouldShowTask(Task task, DateTime selectedDate) {
    // Skip completed tasks
    if (task.isCompleted) return false;

    final taskDate = task.date.toDate();

    // Ensure selected date is not before the task creation date
    if (selectedDate.isBefore(task.createdAt.toDate())) return false;

    // Filter based on repeat type
    switch (task.repeat.toLowerCase()) {
      case 'every day':
        return true;
      case 'every week':
        final difference = selectedDate.difference(taskDate).inDays;
        return difference % 7 == 0 && !selectedDate.isBefore(taskDate);
      case 'every month':
        return selectedDate.day == taskDate.day && !selectedDate.isBefore(taskDate);
      default:
        return DateUtils.isSameDay(taskDate, selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today, ${DateFormat('MMM dd').format(_selectedDate)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _monthDates.length,
                    itemBuilder: (context, index) {
                      final date = _monthDates[index];
                      final isSelected = DateUtils.isSameDay(date, _selectedDate);

                      return GestureDetector(
                        onTap: () => _onDateSelected(date),
                        child: Container(
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(date).toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Colors.green : Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.green : Colors.black,
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _getTasksForDate(_selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No tasks for this date'));
                }

                final tasks = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isOverdue = task.date.toDate().isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.notes.isNotEmpty)
                              Text(
                                task.notes,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('rooms')
                                  .doc(task.roomId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                final roomName = snapshot.data?.get('name') ?? 'Unknown Room';
                                return Text(
                                  roomName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: isOverdue
                          ? Text(
                              '${_getDaysOverdue(task.date.toDate())} Overdue',
                              style: const TextStyle(color: Colors.red),
                            )
                          : Text(
                              DateFormat('hh:mm a').format(task.date.toDate()),
                              style: const TextStyle(color: Colors.orange),
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getDaysOverdue(DateTime dueDate) {
    final difference = DateTime.now().difference(dueDate);
    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    }
    return '${difference.inDays}d';
  }
}

class Task {
  final String title;
  final String notes;
  final String roomId;
  final String userId;
  final Timestamp createdAt;
  final Timestamp date;
  final bool isCompleted;
  final bool reminder;
  final String repeat;

  Task({
    required this.title,
    required this.notes,
    required this.roomId,
    required this.userId,
    required this.createdAt,
    required this.date,
    required this.isCompleted,
    required this.reminder,
    required this.repeat,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      title: data['title'] ?? '',
      notes: data['notes'] ?? '',
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      date: data['date'] as Timestamp? ?? Timestamp.now(),
      isCompleted: data['isCompleted'] ?? false,
      reminder: data['reminder'] ?? false,
      repeat: data['repeat'] ?? '',
    );
  }
}
