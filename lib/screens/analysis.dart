import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_ease/screens/bill_trend_graph.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'bills_analysis_page.dart';

class MonthlyBillsPage extends StatefulWidget {
  const MonthlyBillsPage({Key? key}) : super(key: key);

  @override
  State<MonthlyBillsPage> createState() => _MonthlyBillsPageState();
}

class _MonthlyBillsPageState extends State<MonthlyBillsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _newBillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addDefaultBillsForFirstTimeUser();
  }

  Future<void> _addDefaultBillsForFirstTimeUser() async {
    final defaultBills = ['Water', 'Gas', 'Electricity', 'Internet', 'Rent'];

    try {
      final existingBillsSnapshot = await _firestore.collection('bills').get();
      if (existingBillsSnapshot.docs.isEmpty) {
        for (final bill in defaultBills) {
          await _firestore.collection('bills').add({'name': bill});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing bills: ${e.toString()}')),
      );
    }
  }

  Future<void> _addNewBill() async {
    final newBillName = _newBillController.text.trim();
    if (newBillName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a bill name')),
      );
      return;
    }

    try {
      await _firestore.collection('bills').add({'name': newBillName});
      _newBillController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding bill: ${e.toString()}')),
      );
    }
  }

  Widget _buildBillBoxes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('bills').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No bills available'));
        }

        final bills = snapshot.data!.docs;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final billName = bills[index]['name'];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailPage(billName: billName),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getBillIcon(billName),
                        size: 32,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        billName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getBillIcon(String billName) {
    switch (billName.toLowerCase()) {
      case 'water':
        return Icons.water_drop;
      case 'gas':
        return Icons.local_fire_department;
      case 'electricity':
        return Icons.electric_bolt;
      case 'internet':
        return Icons.wifi;
      case 'rent':
        return Icons.home;
      default:
        return Icons.receipt;
    }
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Monthly Bills'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Bills',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillsAnalysisPage(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics),
              label: const Text('View Bills Analysis'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBillBoxes()),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newBillController,
                        decoration: const InputDecoration(
                          hintText: 'Enter new bill name',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _addNewBill,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Bill'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Previous MonthlyBillsPage code remains the same...

class BillDetailPage extends StatefulWidget {
  final String billName;

  const BillDetailPage({Key? key, required this.billName}) : super(key: key);

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  final TextEditingController _amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedMonth = DateTime.now();
  String? _existingBillDocId;
  double? _existingAmount;

  @override
  void initState() {
    super.initState();
    _checkExistingBillAmount();
  }

  

  Future<void> _checkExistingBillAmount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
    
    try {
      final querySnapshot = await _firestore
          .collection('billAmounts')
          .where('userId', isEqualTo: userId)
          .where('billName', isEqualTo: widget.billName)
          .where('monthKey', isEqualTo: monthKey)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _existingBillDocId = querySnapshot.docs.first.id;
          _existingAmount = querySnapshot.docs.first['amount'].toDouble();
          _amountController.text = _existingAmount.toString();
        });
      } else {
        setState(() {
          _existingBillDocId = null;
          _existingAmount = null;
          _amountController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking existing bill: ${e.toString()}')),
      );
    }
  }

  
  Future<bool> _showUpdateConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Update Bill Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current amount: \$${_existingAmount?.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('New amount: \$${double.tryParse(_amountController.text)?.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Do you want to update this bill amount?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    return result ?? false;  // Return false if result is null
  }

  Future<void> _addOrUpdateBillAmount() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
      final newAmount = double.parse(_amountController.text);

      if (_existingBillDocId != null) {
        // Show update confirmation dialog
        final shouldUpdate = await _showUpdateConfirmationDialog();
        if (!shouldUpdate) {
          return;  // User cancelled the update
        }

        // Update existing bill amount
        await _firestore.collection('billAmounts').doc(_existingBillDocId).update({
          'amount': newAmount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {  // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill amount updated successfully!')),
          );
        }
      } else {
        // Add new bill amount
        await _firestore.collection('billAmounts').add({
          'billName': widget.billName,
          'amount': newAmount,
          'monthKey': monthKey,
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {  // Check if widget is still mounted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill amount added successfully!')),
          );
        }
      }

      // Refresh the existing bill amount check
      if (mounted) {  // Check if widget is still mounted
        await _checkExistingBillAmount();
      }
    } catch (e) {
      if (mounted) {  // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

Future<void> _selectMonth() async {
  final DateTime? picked = await showMonthPicker(
    context: context,
    initialDate: _selectedMonth,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    setState(() {
      _selectedMonth = picked;
    });
    await _checkExistingBillAmount();
  }
}



  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.billName),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.billName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: _selectMonth,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedMonth),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      if (_existingAmount != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Existing bill amount: \$${_existingAmount?.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _existingAmount != null ? 'Update Amount' : 'Amount',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _addOrUpdateBillAmount,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _existingAmount != null ? 'Update Bill Amount' : 'Save Bill Amount',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ), 
            // Add spacing
            const SizedBox(height: 16),
            
            // Add the trend graph
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BillTrendGraph(
                      billName: widget.billName,
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      firestore: _firestore,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}