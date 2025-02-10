import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing bills: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _addNewBill() async {
    final newBillName = _newBillController.text.trim();
    if (newBillName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a bill name'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      await _firestore.collection('bills').add({'name': newBillName});
      _newBillController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$newBillName added successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding bill: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Get gradient colors based on bill type
  List<Color> _getBillGradient(String billName) {
    switch (billName.toLowerCase()) {
      case 'water':
        return [const Color(0xFF48CAE4), const Color(0xFF023E8A)];
      case 'gas':
        return [const Color(0xFFFFB703), const Color(0xFFFB8500)];
      case 'electricity':
        return [const Color(0xFFFFAFCC), const Color(0xFFFF006E)];
      case 'internet':
        return [const Color(0xFF80FFDB), const Color(0xFF2EC4B6)];
      case 'rent':
        return [const Color(0xFFBDB2FF), const Color(0xFF7371FC)];
      default:
        return [const Color(0xFF9381FF), const Color(0xFF593C8F)];
    }
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
        return Icons.receipt_long;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No bills available',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Add your first bill below',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final bills = snapshot.data!.docs;

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final billName = bills[index]['name'];
            final gradientColors = _getBillGradient(billName);

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getBillIcon(billName),
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        billName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Monthly Bills',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text(
              'Your Bills',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Analysis Button
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BillsAnalysisPage(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bills Analysis',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'View detailed expense reports',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Bills Grid
            Expanded(child: _buildBillBoxes()),
            
            // Add New Bill Section
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newBillController,
                        decoration: InputDecoration(
                          hintText: 'Enter new bill name',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _addNewBill,
                      icon: const Icon(Icons.add),
                      label: Text(
                        'Add Bill',
                        style: GoogleFonts.poppins(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
  List<FlSpot> _billHistory = [];

  @override
  void initState() {
    super.initState();
    _checkExistingBillAmount();
    _loadBillHistory();
  }
Future<void> _loadBillHistory() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    print('DEBUG: No user ID found');
    return;
  }

  try {
    print('DEBUG: Starting to load bill history for ${widget.billName}');
    
    // First, let's just get ALL documents for this bill and user to see what we have
    final querySnapshot = await _firestore
        .collection('billAmounts')
        .where('userId', isEqualTo: userId)
        .where('billName', isEqualTo: widget.billName)
        .get();

    print('DEBUG: Found ${querySnapshot.docs.length} total documents');
    
    // Print all documents to see what we have
    querySnapshot.docs.forEach((doc) {
      final data = doc.data();
      print('DEBUG: Document data: ${data.toString()}');
    });

    if (querySnapshot.docs.isEmpty) {
      print('DEBUG: No documents found in query');
      setState(() {
        _billHistory = [];
      });
      return;
    }

    // Convert documents to graph points
    final spots = querySnapshot.docs.asMap().entries.map((entry) {
      final data = entry.value.data();
      final amount = (data['amount'] as num).toDouble();
      final spot = FlSpot(entry.key.toDouble(), amount);
      print('DEBUG: Created spot: x=${spot.x}, y=${spot.y}');
      return spot;
    }).toList();

    print('DEBUG: Created ${spots.length} spots for the graph');

    if (mounted) {
      setState(() {
        _billHistory = spots;
        print('DEBUG: Set _billHistory with ${_billHistory.length} spots');
      });
    }
  } catch (e, stackTrace) {
    print('DEBUG: Error loading bill history: $e');
    print('DEBUG: Stack trace: $stackTrace');
    if (mounted) {
      setState(() {
        _billHistory = [];
      });
    }
  }
}

// Add this debug method to your widget
void _debugPrintCurrentState() {
  print('DEBUG: Current state:');
  print('DEBUG: _billHistory length: ${_billHistory.length}');
  print('DEBUG: _billHistory contents: $_billHistory');
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
              Text('Current amount: \₹${_existingAmount?.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('New amount: \₹${double.tryParse(_amountController.text)?.toStringAsFixed(2)}'),
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
    return result ?? false;
  }

  Future<void> _addOrUpdateBillAmount() async {
  if (_amountController.text.isEmpty) {
    print('DEBUG: No amount entered');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter an amount')),
    );
    return;
  }

  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('DEBUG: No user ID found when adding/updating bill');
      return;
    }

    final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
    final newAmount = double.parse(_amountController.text);
    
    print('DEBUG: Adding/updating bill amount:');
    print('DEBUG: Month Key: $monthKey');
    print('DEBUG: Amount: $newAmount');
    print('DEBUG: Bill Name: ${widget.billName}');
    print('DEBUG: User ID: $userId');

    if (_existingBillDocId != null) {
      print('DEBUG: Updating existing bill document: $_existingBillDocId');
      final shouldUpdate = await _showUpdateConfirmationDialog();
      if (!shouldUpdate) {
        print('DEBUG: Update cancelled by user');
        return;
      }

      await _firestore.collection('billAmounts').doc(_existingBillDocId).update({
        'amount': newAmount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Bill amount updated successfully');
    } else {
      print('DEBUG: Creating new bill document');
      final docRef = await _firestore.collection('billAmounts').add({
        'billName': widget.billName,
        'amount': newAmount,
        'monthKey': monthKey,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('DEBUG: Created new document with ID: ${docRef.id}');
    }

    if (mounted) {
      print('DEBUG: Reloading data after update');
      await _checkExistingBillAmount();
      // Add a longer delay to ensure Firestore update is complete
      await Future.delayed(const Duration(seconds: 1));
      await _loadBillHistory();
      _debugPrintCurrentState();
    }
  } catch (e, stackTrace) {
    print('DEBUG: Error in _addOrUpdateBillAmount: $e');
    print('DEBUG: Stack trace: $stackTrace');
    if (mounted) {
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
Widget _buildGraph() {
  print('DEBUG: Building graph');
  print('DEBUG: _billHistory length: ${_billHistory.length}');
  
  if (_billHistory.isEmpty) {
    print('DEBUG: No bill history available for graph');
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No payment history available'),
      ),
    );
  }

  // Print each point being plotted
  _billHistory.forEach((spot) {
    print('DEBUG: Plotting point: x=${spot.x}, y=${spot.y}');
  });

  // Find min and max values for better Y axis scaling
  double maxY = _billHistory.map((spot) => spot.y).reduce(max);
  double minY = _billHistory.map((spot) => spot.y).reduce(min);
  double yPadding = (maxY - minY) * 0.1; // Add 10% padding

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        minX: 0,
        maxX: (_billHistory.length - 1).toDouble(),
        minY: max(0, minY - yPadding), // Ensure we don't go below 0
        maxY: maxY + yPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '\$${value.toInt()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _billHistory.length) {
                  final date = DateTime.now().subtract(
                    Duration(days: (_billHistory.length - index - 1) * 30),
                  );
                  return Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            left: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _billHistory,
            isCurved: true,
            color: Colors.blue[400],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.blue[400]!,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[400]!.withOpacity(0.3),
                  Colors.blue[400]!.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipBorder: BorderSide(
              color: Colors.blue[400]!,
              width: 1,
            ),
            tooltipRoundedRadius: 8,
            tooltipMargin: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final date = DateTime.now().subtract(
                  Duration(days: (_billHistory.length - barSpot.x.toInt() - 1) * 30),
                );
                return LineTooltipItem(
                  '${DateFormat('MMM yyyy').format(date)}\n',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '\$${barSpot.y.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    ),
  );
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
              const SizedBox(height: 16),
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
                      _buildGraph(),
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