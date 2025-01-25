import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_ease/screens/ai.dart';

class TipsPage extends StatefulWidget {
  @override
  _TipsPageState createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  List<Map<String, dynamic>> tips = [];
  List<bool> _isVisible = [];
  bool _isLoading = true;
  String _selectedCategory = 'All'; // Default category

  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'Cleaning',
    'HVAC',
    'Pest Control',
    'Painting',
    'Roofing'
  ];

  @override
  void initState() {
    super.initState();
    _fetchTipsFromFirestore();
  }

  Future<void> _fetchTipsFromFirestore() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('home_maintenance_tips')
          .get();

      setState(() {
        tips = querySnapshot.docs.map((doc) {
          return {
            'title': doc['title'] ?? 'No Title',
            'details': doc['description'] ?? 'No Description',
            'category': doc['category'] ?? 'General',
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tips: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filteredTips() {
    if (_selectedCategory == 'All') {
      return tips;
    }
    return tips.where((tip) => tip['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTips = _filteredTips();
    if (_isVisible.length != filteredTips.length) {
      _isVisible = List.filled(filteredTips.length, false);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Maintenance Tips'),
      ),
      body: Column(
        children: [
          // Category Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredTips.isEmpty
                    ? Center(child: Text('No tips available for this category'))
                    : ListView.builder(
                        itemCount: filteredTips.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          filteredTips[index]['title'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isVisible[index] ? Icons.remove : Icons.add,
                                          color: const Color.fromARGB(255, 65, 136, 78),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isVisible[index] = !_isVisible[index];
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_isVisible[index])
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        filteredTips[index]['details'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AIChat()),
          );
        },
        child: Icon(Icons.chat),
        backgroundColor: const Color.fromARGB(255, 65, 136, 78),
      ),
    );
  }
}
