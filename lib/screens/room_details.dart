// RoomDetailsPage.dart
import 'package:flutter/material.dart';

class RoomDetailsPage extends StatelessWidget {
  final String roomName;
  final IconData roomIcon;

  const RoomDetailsPage({
    Key? key,
    required this.roomName,
    required this.roomIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          roomName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.green),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'No Tasks Added Yet',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '40 ready-to-use chores available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[50],
                foregroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Preset Tasks'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewTaskSheet(context);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'My Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  void _showNewTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NewTaskSheet(roomName: roomName),
    );
  }
}

class NewTaskSheet extends StatefulWidget {
  final String roomName;

  const NewTaskSheet({
    Key? key,
    required this.roomName,
  }) : super(key: key);

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  String selectedRepeatOption = 'Weekly';
  bool isReminderEnabled = false;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _showRepeatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Daily'),
                onTap: () {
                  setState(() => selectedRepeatOption = 'Daily');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Weekly'),
                onTap: () {
                  setState(() => selectedRepeatOption = 'Weekly');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Monthly'),
                onTap: () {
                  setState(() => selectedRepeatOption = 'Monthly');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Handle save functionality
                    if (titleController.text.isNotEmpty) {
                      // Save the task
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(
                    Icons.check,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.layers),
                  label: const Text('Use Preset'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            ListTile(
              title: const Text('Room'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bedroom_parent, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(widget.roomName),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            ListTile(
              title: const Text('Repeat'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedRepeatOption),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _showRepeatOptions,
                  ),
                ],
              ),
              onTap: _showRepeatOptions,
            ),
            ListTile(
              title: const Text('Date'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Today'),
              ),
            ),
            ListTile(
              title: const Text('Reminder'),
              trailing: Switch(
                value: isReminderEnabled,
                onChanged: (bool value) {
                  setState(() {
                    isReminderEnabled = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Update RoomCard widget in your existing code:
class RoomCard extends StatelessWidget {
  final IconData icon;
  final String roomName;
  final VoidCallback onTap;

  const RoomCard({
    Key? key,
    required this.icon,
    required this.roomName,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailsPage(
              roomName: roomName,
              roomIcon: icon,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            Text(
              roomName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Text(
              "NO TASKS",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}