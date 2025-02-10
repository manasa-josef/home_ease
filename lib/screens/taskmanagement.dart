import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_ease/screens/new_tasks.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class TaskManagementPage extends StatefulWidget {
  final String userId;

  const TaskManagementPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskManagementPage> createState() => _TaskManagementPageState();
}

class _TaskManagementPageState extends State<TaskManagementPage>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'createdAt';
  late AnimationController _lottieController;

  final List<Map<String, String>> _filterOptions = [
    {'value': 'createdAt', 'label': 'Recently Added'},
    {'value': 'date', 'label': 'Due Date'},
  ];

  final Map<String, IconData> roomIcons = {
    'Living Room': Icons.weekend,
    'Kitchen': Icons.kitchen,
    'Bedroom': Icons.bed,
    'Bathroom': Icons.bathroom,
    'Office': Icons.computer,
    'Garden': Icons.yard,
    'Garage': Icons.garage,
    'Default': Icons.room,
  };

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildFloatingOvalButton(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      title: const Text(
        'My Tasks',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, size: 28),
          onSelected: (String value) {
            setState(() {
              _selectedFilter = value;
            });
          },
          itemBuilder: (BuildContext context) => _filterOptions
              .map((filter) => PopupMenuItem<String>(
                    value: filter['value'],
                    child: Row(
                      children: [
                        Icon(
                          filter['value'] == 'createdAt'
                              ? Icons.access_time
                              : Icons.event,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(filter['label']!),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: widget.userId)
          .orderBy(_selectedFilter, descending: _selectedFilter == 'createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final tasks = snapshot.data?.docs ?? [];

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildTaskCard(tasks[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(DocumentSnapshot task) {
  final taskData = task.data() as Map<String, dynamic>;

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance
        .collection('rooms')
        .doc(taskData['roomId'])
        .get(),
    builder: (context, roomSnapshot) {
      final roomName = roomSnapshot.data?.get('name') ?? 'Unknown Room';
      final date = taskData['date'] as Timestamp?;

      final dateTime = date?.toDate() ?? DateTime.now();
      final dateStr = DateFormat('MMM dd').format(dateTime);
      final timeStr = DateFormat('HH:mm').format(dateTime);

      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              roomIcons[roomName] ?? roomIcons['Default'],
              color: Theme.of(context).primaryColor,
            ),
          ),
          title: Text(
            taskData['title'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (taskData['notes']?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    taskData['notes'],
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
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteTask(task.id),
          ),
        ),
      );
    },
  );
}

void _deleteTask(String taskId) {
  FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
}


  Widget _buildFloatingOvalButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        height: 56,
        width: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModernNewTaskPage(userId: widget.userId),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Task',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/error.json',
            controller: _lottieController,
            onLoaded: (composition) {
              _lottieController
                ..duration = composition.duration
                ..forward();
            },
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          const Text('Error loading tasks'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Lottie.asset(
        'assets/loading.json',
        width: 200,
        height: 200,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty_task1.json',
            controller: _lottieController,
            onLoaded: (composition) {
              _lottieController
                ..duration = composition.duration
                ..forward();
            },
            width: 250,
            height: 250,
          ),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first task!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}