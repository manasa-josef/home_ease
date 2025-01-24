import 'package:flutter/material.dart';

class NewRoomPage extends StatefulWidget {
  const NewRoomPage({Key? key}) : super(key: key);

  @override
  State<NewRoomPage> createState() => _NewRoomPageState();
}

class _NewRoomPageState extends State<NewRoomPage> {
  final TextEditingController _customRoomController = TextEditingController();
  IconData? _selectedIcon;
  bool _isCustomRoom = false;

  // Predefined rooms that don't exist in the current list
  final List<Map<String, dynamic>> additionalRooms = [
    {"icon": Icons.garage_outlined, "name": "Garage"},
    {"icon": Icons.work_outline, "name": "Home Office"},
    {"icon": Icons.weekend_outlined, "name": "Game Room"},
    {"icon": Icons.local_laundry_service_outlined, "name": "Laundry Room"},
    {"icon": Icons.storage_outlined, "name": "Storage Room"},
    {"icon": Icons.door_sliding_outlined, "name": "Balcony"},
    {"icon": Icons.stairs_outlined, "name": "Basement"},
    {"icon": Icons.sports_gymnastics_outlined, "name": "Gym"},
  ];

  // Additional icons for custom room selection
  final List<IconData> availableIcons = [
    Icons.house_outlined,
    Icons.meeting_room_outlined,
    Icons.door_front_door_outlined,
    Icons.table_restaurant_outlined,
    Icons.chair_outlined,
    Icons.bathroom_outlined,
    Icons.bed_outlined,
    Icons.tv_outlined,
    Icons.computer_outlined,
    Icons.kitchen_outlined,
    Icons.garage_outlined,
    Icons.work_outline,
    Icons.weekend_outlined,
    Icons.local_laundry_service_outlined,
    Icons.storage_outlined,
    Icons.door_sliding_outlined,
    Icons.stairs_outlined,
    Icons.sports_gymnastics_outlined,
    Icons.library_books_outlined,
    Icons.theater_comedy_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Room",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Predefined Rooms Section
            if (!_isCustomRoom) ...[
              const Text(
                "Select a Room",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: additionalRooms.length,
                itemBuilder: (context, index) {
                  return _buildRoomCard(
                    additionalRooms[index]["icon"] as IconData,
                    additionalRooms[index]["name"] as String,
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            
            // Toggle for Custom Room
            SwitchListTile(
              title: const Text(
                "Create Custom Room",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _isCustomRoom,
              onChanged: (bool value) {
                setState(() {
                  _isCustomRoom = value;
                  if (!value) {
                    _selectedIcon = null;
                    _customRoomController.clear();
                  }
                });
              },
              activeColor: Colors.green,
            ),

            // Custom Room Section
            if (_isCustomRoom) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customRoomController,
                decoration: const InputDecoration(
                  labelText: "Room Name",
                  border: OutlineInputBorder(),
                  hintText: "Enter room name",
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select an Icon",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, index) {
                    return _buildIconSelector(availableIcons[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (_isCustomRoom) {
              if (_customRoomController.text.isNotEmpty && _selectedIcon != null) {
                Navigator.pop(context, {
                  "name": _customRoomController.text,
                  "icon": _selectedIcon,
                  "isCustom": true,
                });
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Add Room",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard(IconData icon, String name) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context, {
            "name": name,
            "icon": icon,
            "isCustom": false,
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSelector(IconData icon) {
    final bool isSelected = _selectedIcon == icon;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIcon = icon;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}