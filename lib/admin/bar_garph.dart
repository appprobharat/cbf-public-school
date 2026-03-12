import 'dart:convert';

import 'package:cbf/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EarningExpenseChart extends StatefulWidget {
  const EarningExpenseChart({super.key});

  @override
  State<EarningExpenseChart> createState() => _EarningExpenseChartState();

  static Widget _legendChip(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningExpenseChartState extends State<EarningExpenseChart> {
  List<double> income = List.filled(12, 0);
  List<double> expense = List.filled(12, 0);

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await ApiService.post(context, "/admin/report/analysis");

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List incomeApi = data["income"] ?? [];
      List expenseApi = data["expenses"] ?? [];

      income = List.generate(
        12,
        (i) => (incomeApi.length > i ? incomeApi[i] : 0).toDouble(),
      );

      // expense ko negative banana zaroori hai chart ke liye
      expense = List.generate(
        12,
        (i) => -(expenseApi.length > i ? expenseApi[i] : 0).toDouble(),
      );

      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Heading with icon
          Row(
            children: const [
              Icon(Icons.analytics, size: 20, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                "Earning / Expenses Analytics",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),

          // 🔹 Legend chips
          Row(
            children: [
              EarningExpenseChart._legendChip(Colors.deepPurple, "Income"),
              const SizedBox(width: 12),
              EarningExpenseChart._legendChip(Colors.teal, "Expenses"),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 Chart
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: 50000,
                minY: -180000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: value == 0 ? Colors.black26 : Colors.grey.shade200,
                      strokeWidth: value == 0 ? 1.2 : 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          "Apr",
                          "May",
                          "Jun",
                          "Jul",
                          "Aug",
                          "Sep",
                          "Oct",
                          "Nov",
                          "Dec",
                          "Jan",
                          "Feb",
                          "Mar",
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[value.toInt()],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups: _barGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Bar Data
  List<BarChartGroupData> _barGroups() {
    return List.generate(12, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 6,
        barRods: [
          BarChartRodData(toY: income[i], color: Colors.deepPurple, width: 9),
          BarChartRodData(toY: expense[i], color: Colors.teal, width: 9),
        ],
      );
    });
  }
}
