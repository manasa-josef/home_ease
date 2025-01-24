// bills_analysis_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class BillsAnalysisPage extends StatefulWidget {
  const BillsAnalysisPage({Key? key}) : super(key: key);

  @override
  State<BillsAnalysisPage> createState() => _BillsAnalysisPageState();
}

class _BillsAnalysisPageState extends State<BillsAnalysisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _chartData = [];
  double _totalAmount = 0;
  
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<int> _years = List.generate(
    10,
    (index) => DateTime.now().year - 5 + index,
  );

  @override
  void initState() {
    super.initState();
    _fetchBillData();
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedMonth.year,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    border: OutlineInputBorder(),
                  ),
                  items: _years.map((int year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (int? year) {
                    if (year != null) {
                      setState(() {
                        _selectedMonth = DateTime(year, _selectedMonth.month);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedMonth.month,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: _months.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key + 1,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (int? month) {
                    if (month != null) {
                      setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, month);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchBillData();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchBillData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final monthKey = "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";
    
    try {
      final querySnapshot = await _firestore
          .collection('billAmounts')
          .where('userId', isEqualTo: userId)
          .where('monthKey', isEqualTo: monthKey)
          .get();

      double total = 0;
      final List<Map<String, dynamic>> data = [];
      
      for (var doc in querySnapshot.docs) {
        final amount = doc['amount'] as double;
        total += amount;
        data.add({
          'name': doc['billName'],
          'amount': amount,
        });
      }

      setState(() {
        _chartData = data;
        _totalAmount = total;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bill data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills Analysis'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      'Monthly Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _showMonthPicker,
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
                  ],
                ),
              ),
            ),
            if (_chartData.isNotEmpty) ...[
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: \$${_totalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: PieChart(
                          PieChartData(
                            sections: _chartData.map((data) {
                              final percentage = (data['amount'] as double) / _totalAmount;
                              return PieChartSectionData(
                                color: Colors.primaries[_chartData.indexOf(data) % Colors.primaries.length],
                                value: data['amount'],
                                title: '${(percentage * 100).toStringAsFixed(1)}%',
                                radius: 150,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: _chartData.map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.primaries[_chartData.indexOf(data) % Colors.primaries.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(data['name']),
                                const Spacer(),
                                Text('\$${(data['amount'] as double).toStringAsFixed(2)}'),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'No bill data available for selected month',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}