import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';

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
        Timestamp? lastActive = doc['lastActiveDate'] as Timestamp?;
        if (lastActive != null) {
          DateTime lastActiveDate = lastActive.toDate();
          int daysInactive = now.difference(lastActiveDate).inDays;

          if (daysInactive >= 7 && daysInactive < 30) {
            weekInactive.add({
              'name': doc['fullName'] ?? 'No Name',
              'email': doc['email'] ?? 'No Email',
              'lastActive': lastActiveDate,
            });
          } else if (daysInactive >= 30) {
            monthInactive.add({
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

   Future<void> _openMailApp() async {
    if (_inactiveUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No inactive users to email.')),
      );
      return;
    }

    final String subject = _inactiveCategory == 'Week Inactive'
        ? 'We Miss You at HomeEase!'
        : 'It’s Been a While! Come Back to HomeEase';
    
    final String body = _inactiveCategory == 'Week Inactive'
        ? 'Hello,\n\nWe noticed some of you haven’t been active for a week. We have great home maintenance tips waiting for you. Come back now!\n\nBest Regards,\nHomeEase Team'
        : 'Hello,\n\nIt’s been a month since we last saw some of you. We’d love to have you back to explore new home maintenance tips.\n\nBest Regards,\nHomeEase Team';

    final List recipientEmails =
        _inactiveUsers.map((user) => user['email']).toList();

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipientEmails.join(','),
      queryParameters: {'subject': subject, 'body': body},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
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
  Widget _buildThemeContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF0E6FF),  // Light lavender
            Color(0xFFE6E6FA),  // Lavender
            Color(0xFfD8BFD8),  // Thistle
          ],
        ),
      ),
      child: child,
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
            onPressed: _isLoading || _inactiveUsers.isEmpty ? null : _openMailApp,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Send Email to All Inactive Users'),
          ),
        ),
      ],
    );
  }
  Widget _buildNavigationButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          _buildNavButton('Users', 'User Activity'),
          _buildNavButton('Tips', 'Tips'),
          _buildNavButton('Inactive Users', 'Inactive'),
        ],
      ),
    );
  }

  Widget _buildNavButton(String view, String label) {
    bool isSelected = _currentView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentView = view),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.deepPurple : Colors.deepPurple[300],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildProfileButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.account_circle),
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person),
            title: Text('Admin Profile'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'profile') {
          _showAdminProfile();
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
    );
  }

  void _showAdminProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              const Text('Name: Admin User'),
              const Text('Email: admin@homeease.com'),
              const Text('Role: System Administrator'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add your logout logic here
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/login'); // Navigate to login
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard', 
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildProfileButton()],
      ),
      extendBodyBehindAppBar: true,
      body: _buildThemeContainer(
        child: SafeArea(
          child: Column(
            children: [
              _buildNavigationButtons(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _currentView == 'Users'
                      ? _buildUsersView()
                      : _currentView == 'Tips'
                          ? _buildTipsForm()
                          : _buildInactiveUsersView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}