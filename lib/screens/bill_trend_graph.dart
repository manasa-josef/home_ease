import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BillTrendGraph extends StatelessWidget {
  final String billName;
  final String userId;
  final FirebaseFirestore firestore;

  const BillTrendGraph({
    Key? key,
    required this.billName,
    required this.userId,
    required this.firestore,
  }) : super(key: key);

  Future<List<FlSpot>> _getBillHistory() async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final monthKey = "${sixMonthsAgo.year}-${sixMonthsAgo.month.toString().padLeft(2, '0')}";

    try {
      final querySnapshot = await firestore
          .collection('billAmounts')
          .where('userId', isEqualTo: userId)
          .where('billName', isEqualTo: billName)
          .where('monthKey', isGreaterThanOrEqualTo: monthKey)
          .orderBy('monthKey')
          .get();

      final spots = querySnapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        final amount = (data['amount'] as num).toDouble();
        return FlSpot(entry.key.toDouble(), amount);
      }).toList();

      return spots;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<FlSpot>>(
        future: _getBillHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final spots = snapshot.data!;
          if (spots.isEmpty) {
            return const Center(
              child: Text('No payment history available'),
            );
          }

          return LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < spots.length) {
                        final date = DateTime.now().subtract(
                          Duration(days: (spots.length - value.toInt() - 1) * 30),
                        );
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }
                      return const Text('');
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
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue.shade300,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.shade100.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}