import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_ease/screens/analysis.dart';
import 'package:home_ease/screens/schedule_page.dart';
import 'package:home_ease/screens/service_contact.dart';
import 'package:home_ease/screens/settings.dart';
import 'package:home_ease/screens/tasklist.dart';
import 'package:home_ease/screens/taskmanagement.dart';
import 'package:home_ease/screens/tips_and_tricks.dart';
class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  String _fullName = ''; // Add this to store the user's full name

  @override
  void initState() {
    super.initState();
    _initializeDefaultRooms();
    _loadUserData(); // Add this to load user data
  }

  // Add this method to load user data
  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          _fullName = userDoc.data()?['fullName'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  Future<void> _initializeDefaultRooms() async {
    try {
      // Check if user has any rooms
      final userRoomsSnapshot = await _firestore
          .collection('rooms')
          .where('userId', isEqualTo: widget.userId)
          .get();

      // If no rooms exist, create default rooms
      if (userRoomsSnapshot.docs.isEmpty) {
        final defaultRooms = [
          {"name": "Living Room", "icon": Icons.living_outlined.codePoint.toString()},
          {"name": "Bedroom", "icon": Icons.bed.codePoint.toString()},
          {"name": "Kitchen", "icon": Icons.kitchen.codePoint.toString()},
          {"name": "Bathroom", "icon": Icons.bathtub_outlined.codePoint.toString()},
          {"name": "Laundry Room", "icon": Icons.local_laundry_service_outlined.codePoint.toString()},
        ];

        // Create each default room
        for (var room in defaultRooms) {
          await _addRoom(room['name']!, room['icon']!);
        }
      }
    } catch (e) {
      print('Error initializing rooms: $e');
    }
  }

  Future<void> _addRoom(String name, String icon) async {
    try {
      // Create room document
      DocumentReference roomRef = await _firestore.collection('rooms').add({
        'name': name,
        'icon': icon,
        'userId': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Created room: ${roomRef.id}');
    } catch (e) {
      print('Error adding room: $e');
    }
  }


  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "My Home",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const Text(
              "Welcome back!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                CategoryCard(
                  icon: Icons.task_outlined,
                  title: "Task Management",
                  subtitle: "Manage tasks",
                  color: Colors.purple.shade100,
                  onTap: () => Navigator.push(
                    context,
                   MaterialPageRoute(
                     builder: (context) => TaskManagementPage(
                            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                          ),
                        ),
                  ),
                ),
                CategoryCard(
                  icon: Icons.contact_phone,
                  title: "Service Contact",
                  subtitle: "Get help",
                  color: Colors.blue.shade100,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServiceContactPage()),
                  ),
                ),
                CategoryCard(
                  icon: Icons.tips_and_updates,
                  title: "Tips & Tricks",
                  subtitle: "Learn more",
                  color: Colors.orange.shade100,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TipsPage()),
                  ),
                ),
                CategoryCard(
                  icon: Icons.analytics,
                  title: "Bill ",
                  subtitle: "View Bill stats",
                  color: Colors.green.shade100,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MonthlyBillsPage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),


            // Rooms Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rooms",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddRoomDialog(),
                  icon: const Icon(Icons.add, color: Colors.purple),
                  label: const Text("Add", style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rooms List from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('rooms')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final room = snapshot.data!.docs[index];
                    final roomData = room.data() as Map<String, dynamic>;
                    return RoomCard(
                      icon: IconData(
                        int.parse(roomData['icon']),
                        fontFamily: 'MaterialIcons',
                      ),
                      roomName: roomData['name'],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskListPage(
                            roomId: room.id,
                            roomName: roomData['name'],
                            userId: widget.userId,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoomDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String roomName = '';
        return AlertDialog(
          title: const Text('Add New Room'),
          content: TextField(
            onChanged: (value) => roomName = value,
            decoration: const InputDecoration(hintText: "Room name"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (roomName.isNotEmpty) {
                  _addRoom(roomName, Icons.room.codePoint.toString());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      children: [
        _buildHomeContent(),
        SchedulePage(userId: widget.userId), // Replace the Text widget with the actual SchedulePage
        SettingsPage(userId: widget.userId, fullName: _fullName),
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );
}
}
// Keep the CategoryCard and RoomCard widgets unchanged

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: color.withRed(100)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.purple),
        ),
        title: Text(
          roomName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}