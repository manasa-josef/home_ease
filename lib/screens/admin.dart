import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _currentView = 'Users'; // Default view
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'HVAC',
    'Pest Control',
    'Painting',
    'Roofing',
    'Other',
  ];

  // Inactive User Variables
  String _inactiveCategory = 'Week Inactive';
  List<Map<String, dynamic>> _inactiveUsers = [];
  final List<String> _inactiveCategories = ['Week Inactive', 'Month Inactive'];

  @override
  void initState() {
    super.initState();
    _checkAndAddDefaultTips();
    _fetchInactiveUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _checkAndAddDefaultTips() async {
    final tipsCollection = FirebaseFirestore.instance.collection('home_maintenance_tips');
    final snapshot = await tipsCollection.get();

    if (snapshot.docs.isEmpty) {
      final defaultTips = [
        {'title': 'Fix Leaky Faucets', 'description': 'Check for drips and replace washers.', 'category': 'Plumbing'},
        {'title': 'Test Smoke Alarms', 'description': 'Replace batteries twice a year.', 'category': 'Electrical'},
        {'title': 'Deep Clean Carpets', 'description': 'Vacuum and steam clean regularly.', 'category': 'Cleaning'},
        {'title': 'Change HVAC Filters', 'description': 'Replace filters every 3 months.', 'category': 'HVAC'},
        {'title': 'Seal Cracks in Walls', 'description': 'Check for cracks and use sealant.', 'category': 'Painting'},
      ];

      for (var tip in defaultTips) {
        await tipsCollection.add({
          'title': tip['title'],
          'description': tip['description'],
          'category': tip['category'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> _fetchInactiveUsers() async {
    setState(() => _isLoading = true);
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();

      DateTime now = DateTime.now();
      List<Map<String, dynamic>> weekInactive = [];
      List<Map<String, dynamic>> monthInactive = [];

      for (var doc in querySnapshot.docs) {
        Timestamp? lastActive = doc['lastActive'] as Timestamp?;
        if (lastActive != null) {
          DateTime lastActiveDate = lastActive.toDate();
          int daysInactive = now.difference(lastActiveDate).inDays;

          if (daysInactive >= 7 && daysInactive < 30) {
            weekInactive.add({
              'id': doc.id,
              'name': doc['fullName'] ?? 'No Name',
              'email': doc['email'] ?? 'No Email',
              'lastActive': lastActiveDate,
            });
          } else if (daysInactive >= 30) {
            monthInactive.add({
              'id': doc.id,
              'name': doc['fullName'] ?? 'No Name',
              'email': doc['email'] ?? 'No Email',
              'lastActive': lastActiveDate,
            });
          }
        }
      }

      setState(() {
        _inactiveUsers =
            _inactiveCategory == 'Week Inactive' ? weekInactive : monthInactive;
      });
    } catch (e) {
      print('Error fetching inactive users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String category =
          _selectedCategory == 'Other' ? _customCategoryController.text.trim() : _selectedCategory;

      await FirebaseFirestore.instance.collection('home_maintenance_tips').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descriptionController.clear();
      _customCategoryController.clear();
      setState(() => _selectedCategory = 'Plumbing');

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tip added successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmails() async {
    setState(() => _isLoading = true);
    try {
      final smtpServer = gmail('manasajosef05@gmail.com', 'hpid bgme wqvc rrgk'); // Replace with your credentials

      for (var user in _inactiveUsers) {
        final message = Message()
          ..from = Address('manasajosef05@gmail.com', 'Admin')
          ..recipients.add(user['email'])
          ..subject = _inactiveCategory == 'Week Inactive'
              ? 'We Miss You at HomeEase!'
              : 'It’s Been a While! Come Back to HomeEase'
          ..text = _inactiveCategory == 'Week Inactive'
              ? 'Hello ${user['name']},\n\nWe noticed you haven’t been active for a week. We have great home maintenance tips waiting for you. Come back now!\n\nBest Regards,\nHomeEase Team'
              : 'Hello ${user['name']},\n\nIt’s been a month since we last saw you. We’d love to have you back to explore new home maintenance tips.\n\nBest Regards,\nHomeEase Team';

        await send(message, smtpServer);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emails sent successfully!')),
      );
    } catch (e) {
      print('Error sending emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send emails: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserActivityChart(List<QueryDocumentSnapshot> users) {
    Map<DateTime, int> usersByDate = {};

    for (var user in users) {
      final timestamp = user['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
        usersByDate[date] = (usersByDate[date] ?? 0) + 1;
      }
    }

    if (usersByDate.isEmpty) {
      return const Center(child: Text('No user activity data available.'));
    }

    final sortedDates = usersByDate.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((entry) {
      final date = sortedDates[entry.key];
      return FlSpot(entry.key.toDouble(), usersByDate[date]!.toDouble());
    }).toList();

    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE3DFF2), Color(0xFFCBC3E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextButton(
        onPressed: () {
          if (_currentView == 'Users') {
            setState(() => _currentView = 'Tips');
          } else if (_currentView == 'Tips') {
            setState(() => _currentView = 'Inactive Users');
          } else {
            setState(() => _currentView = 'Users');
          }
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'Switch to ${_currentView == 'Users' ? 'Tips' : _currentView == 'Tips' ? 'Inactive Users' : 'User Activity'}',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildUsersView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No user activity found.'));
        }

        final users = snapshot.data!.docs;

        return Column(
          children: [
            _buildUserActivityChart(users),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user['fullName'] ?? 'No Name'),
                    subtitle: Text(user['email'] ?? 'No Email'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                ),
                if (_selectedCategory == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(labelText: 'Enter Category', border: OutlineInputBorder()),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addTip,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Tip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveUsersView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<String>(
            value: _inactiveCategory,
            items: _inactiveCategories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _inactiveCategory = value!;
                _fetchInactiveUsers();
              });
            },
            decoration: const InputDecoration(
              labelText: 'Select Inactive Category',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _inactiveUsers.isEmpty
                  ? const Center(child: Text('No inactive users found'))
                  : ListView.builder(
                      itemCount: _inactiveUsers.length,
                      itemBuilder: (context, index) {
                        final user = _inactiveUsers[index];
                        return ListTile(
                          title: Text(user['name']),
                          subtitle: Text('${user['email']} \nLast Active: ${user['lastActive']}'),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _inactiveUsers.isEmpty || _isLoading ? null : _sendEmails,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Send Email to $_inactiveCategory Users'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Column(
        children: [
          _buildGradientButton(),
          Expanded(
            child: _currentView == 'Users'
                ? _buildUsersView()
                : _currentView == 'Tips'
                    ? _buildTipsForm()
                    : _buildInactiveUsersView(),
          ),
        ],
      ),
    );
  }
}
