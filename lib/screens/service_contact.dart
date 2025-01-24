import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceContactPage extends StatefulWidget {
  const ServiceContactPage({super.key});

  @override
  _ServiceContactPageState createState() => _ServiceContactPageState();
}

class _ServiceContactPageState extends State<ServiceContactPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController serviceNameController = TextEditingController();
  final TextEditingController servicePhoneController = TextEditingController();
  final TextEditingController servicerNameController = TextEditingController();
  final TextEditingController customServiceController = TextEditingController();

  Map<String, IconData> serviceIcons = {
    'Plumbing': Icons.plumbing,
    'Electrician': Icons.electric_bolt,
    'Carpenter': Icons.handyman,
    'Painter': Icons.format_paint,
    'Cleaner': Icons.cleaning_services,
    'Gardener': Icons.yard,
    'Security': Icons.security,
    'Internet': Icons.wifi,
    'Other': Icons.miscellaneous_services,
  };

  void showAddServiceDialog() {
    String? selectedService;
    bool showCustomField = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Add New Service",
                style: TextStyle(color: Color(0xFF9575CD)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedService,
                      decoration: InputDecoration(
                        labelText: "Service Type",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(
                          selectedService != null 
                            ? serviceIcons[selectedService] 
                            : Icons.home_repair_service,
                          color: const Color(0xFF9575CD),
                        ),
                      ),
                      items: serviceIcons.keys.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedService = newValue;
                          showCustomField = newValue == 'Other';
                          if (!showCustomField) {
                            serviceNameController.text = newValue ?? '';
                          }
                        });
                      },
                    ),
                    if (showCustomField) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: customServiceController,
                        decoration: InputDecoration(
                          labelText: "Custom Service Name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(
                            Icons.miscellaneous_services,
                            color: Color(0xFF9575CD),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: servicerNameController,
                      decoration: InputDecoration(
                        labelText: "Servicer Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Color(0xFF9575CD),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: servicePhoneController,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Color(0xFF9575CD),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Color(0xFF9575CD)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _addServiceToDatabase(selectedService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9575CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Add Service"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addServiceToDatabase(String? selectedService) async {
    String serviceName = selectedService == 'Other' 
        ? customServiceController.text.trim()
        : (selectedService ?? '');

    if ((selectedService != 'Other' || customServiceController.text.isNotEmpty) &&
        servicerNameController.text.isNotEmpty &&
        servicePhoneController.text.length == 10) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please login to add services")),
          );
          return;
        }

        await _firestore.collection('services').add({
          'userId': userId,
          'serviceName': serviceName,
          'servicerName': servicerNameController.text,
          'servicePhone': servicePhoneController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Service added successfully!")),
          );
        }

        serviceNameController.clear();
        servicerNameController.clear();
        servicePhoneController.clear();
        customServiceController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding service: ${e.toString()}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9575CD), Color(0xFFB39DDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Service Contacts",
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color(0xFFF3E5F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddServiceDialog,
        backgroundColor: const Color(0xFF9575CD),
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9575CD), Color(0xFFB39DDB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Text(
              "Keep all your service contacts organized in one place",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('services')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.contact_phone_outlined,
                          size: 64,
                          color: Color(0xFF9575CD),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No services added yet",
                          style: TextStyle(
                            color: Color(0xFF9575CD),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return ServiceCard(
                      service: doc.data() as Map<String, dynamic>,
                      serviceId: doc.id,
                      firestore: _firestore,
                      serviceIcons: serviceIcons,
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
}

// ServiceCard widget remains the same but update the color values
class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final String serviceId;
  final FirebaseFirestore firestore;
  final Map<String, IconData> serviceIcons;

  const ServiceCard({
    required this.service,
    required this.serviceId,
    required this.firestore,
    required this.serviceIcons,
    Key? key,
  }) : super(key: key);

  Future<void> _deleteService(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        await firestore.collection('services').doc(serviceId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting service: ${e.toString()}')),
        );
      }
    }
  }

  void _callService(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE1BEE7),
            child: Icon(
              serviceIcons[service['serviceName']] ?? Icons.miscellaneous_services,
              color: const Color(0xFF9575CD),
            ),
          ),
          title: Text(
            service['servicerName'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                service['serviceName'],
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                service['servicePhone'],
                style: const TextStyle(
                  color: Color(0xFF9575CD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.phone),
                color: const Color(0xFF9575CD),
                onPressed: () => _callService(service['servicePhone']),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () => _deleteService(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}