import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'taskform.dart';

class TaskListPage extends StatefulWidget {
  final String roomName;
  final String roomId;
  final String userId;

  const TaskListPage({
    Key? key, 
    required this.roomName, 
    required this.roomId,
    required this.userId,
  }) : super(key: key);

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  Future<void> _handleTaskAction(BuildContext context, Map<String, dynamic> task, String taskId) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Done'),
                onTap: () async {
                  await _markTaskAsDone(task, taskId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.skip_next, color: Colors.blue),
                title: const Text('Skip'),
                onTap: () async {
                  await _skipTask(task, taskId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markTaskAsDone(Map<String, dynamic> task, String taskId) async {
    try {
      final nextOccurrence = _calculateActualNextOccurrence(task);
      
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'completedInstances': FieldValue.arrayUnion([_getCurrentDateKey()]),
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'nextOccurrence': nextOccurrence,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task completed. Next occurrence on ${DateFormat('yyyy-MM-dd').format(nextOccurrence)}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error marking task as done: $e');
    }
  }

  Future<void> _skipTask(Map<String, dynamic> task, String taskId) async {
    try {
      final nextOccurrence = _calculateActualNextOccurrence(task);
      
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({
        'skippedInstances': FieldValue.arrayUnion([_getCurrentDateKey()]),
        'nextOccurrence': nextOccurrence,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Task skipped. Next occurrence on ${DateFormat('yyyy-MM-dd').format(nextOccurrence)}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error skipping task: $e');
    }
  }

  DateTime _calculateActualNextOccurrence(Map<String, dynamic> task) {
    final currentDate = DateTime.now();
    final taskDate = (task['date'] as Timestamp).toDate();
    final repeat = task['repeat'];

    switch (repeat) {
      case 'Every day':
        return currentDate.add(const Duration(days: 1));
      case 'Every week':
        return currentDate.add(const Duration(days: 7));
      case 'Every month':
        return DateTime(
          currentDate.year, 
          currentDate.month + 1, 
          taskDate.day
        );
      default:
        return taskDate;
    }
  }

  String _getCurrentDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime _calculateNextOccurrence(Map<String, dynamic> task) {
    final currentDate = DateTime.now();
    final taskDate = (task['date'] as Timestamp).toDate();
    final repeat = task['repeat'];

    switch (repeat) {
      case 'Daily':
        return currentDate.add(const Duration(days: 1));
      case 'Weekly':
        return currentDate.add(const Duration(days: 7));
      case 'Monthly':
        return DateTime(currentDate.year, currentDate.month + 1, taskDate.day);
      default:
        return taskDate;
    }
  }
bool _shouldShowTask(Map<String, dynamic> task) {
  final completedInstances = List<String>.from(task['completedInstances'] ?? []);
  final skippedInstances = List<String>.from(task['skippedInstances'] ?? []);
  final currentDateKey = _getCurrentDateKey();

  if (completedInstances.contains(currentDateKey) || skippedInstances.contains(currentDateKey)) {
    return false;
  }

  final repeat = task['repeat'];
  final now = DateTime.now();
  final taskDate = (task['date'] as Timestamp).toDate();

  if (repeat != null && repeat != 'Never') {
    final nextOccurrence = task['nextOccurrence'] != null
        ? (task['nextOccurrence'] as Timestamp).toDate()
        : _calculateNextOccurrence(task);

    return (now.year == nextOccurrence.year &&
            now.month == nextOccurrence.month &&
            now.day == nextOccurrence.day) ||
           now.isAfter(taskDate); // Show if overdue
  }

  return now.isAfter(taskDate) || 
         (now.year == taskDate.year && now.month == taskDate.month && now.day == taskDate.day);
}


  Widget _buildTaskStatus(Map<String, dynamic> task) {
    final taskDate = (task['date'] as Timestamp).toDate();
    final now = DateTime.now();
    final duration = now.difference(taskDate);
    
    final dateStr = DateFormat('yyyy-MM-dd').format(taskDate);
    final timeStr = DateFormat('HH:mm').format(taskDate);
    
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.red),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.access_time, size: 16, color: Colors.red),
        const SizedBox(width: 4),
        Text(
          timeStr,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          duration.inDays > 0
              ? 'Overdue by ${duration.inDays} day${duration.inDays > 1 ? 's' : ''}'
              : duration.inHours > 0
                  ? 'Overdue by ${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}'
                  : 'Overdue by ${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksRef = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: widget.userId)
        .where('roomId', isEqualTo: widget.roomId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: const Color.fromARGB(255, 241, 240, 242),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tasksRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data?.docs ?? [];
          final visibleTasks = tasks.where((taskDoc) {
            final task = taskDoc.data() as Map<String, dynamic>;
            return _shouldShowTask(task);
          }).toList();

          if (visibleTasks.isEmpty) {
            return const Center(
              child: Text('No tasks to show. Tap + to add a task.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visibleTasks.length,
            itemBuilder: (context, index) {
              final taskDoc = visibleTasks[index];
              final task = taskDoc.data() as Map<String, dynamic>;
              final taskId = taskDoc.id;
              final taskDate = (task['date'] as Timestamp).toDate();
              final now = DateTime.now();
              final isOverdue = now.isAfter(taskDate);

              final dateStr = DateFormat('yyyy-MM-dd').format(taskDate);
              final timeStr = DateFormat('HH:mm').format(taskDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _handleTaskAction(context, task, taskId),
                  title: Text(
                    task['title'] ?? 'Untitled Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOverdue)
                        _buildTaskStatus(task)
                      else
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.access_time,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (task['notes']?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task['notes'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModernTaskFormPage(
              roomName: widget.roomName,
              roomId: widget.roomId,
              userId: widget.userId,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}