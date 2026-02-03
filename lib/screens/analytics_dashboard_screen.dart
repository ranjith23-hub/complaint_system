import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/complaint_model.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4A148C);

    return Scaffold(
      appBar: AppBar(
        title: const Text("City Analytics"),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No data available for analytics."));

          // Data Processing
          Map<String, int> categoryCounts = {};
          int resolvedCount = 0;
          int inProgressCount = 0;
          int assignedCount = 0;
          int classifiedCount = 0; // New attribute count

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String cat = data['category'] ?? 'General';
            String status = (data['status'] ?? 'submitted').toString().toLowerCase();

            categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;

            if (status == 'resolved') {
              resolvedCount++;
            } else if (status == 'pending' || status == 'in progress') {
              inProgressCount++;
            } else if (status == 'classified') {
              classifiedCount++; // Increment classified count
            } else {
              assignedCount++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSectionTitle("Complaints by Category"),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: _buildBarChart(categoryCounts),
                ),
                const SizedBox(height: 40),
                _buildSectionTitle("Resolution Status"),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: _buildPieChart(resolvedCount, inProgressCount, assignedCount, classifiedCount),
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(docs.length, resolvedCount, classifiedCount),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildBarChart(Map<String, int> data) {
    List<String> categories = data.keys.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.isEmpty ? 10 : (data.values.reduce((a, b) => a > b ? a : b).toDouble() + 1),
        barGroups: List.generate(categories.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[categories[index]]!.toDouble(),
                color: Colors.indigo,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              )
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= categories.length) return const Text("");
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(categories[value.toInt()], style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildPieChart(int resolved, int progress, int assigned, int classified) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: resolved.toDouble(), color: Colors.green, title: 'Done', radius: 50),
          PieChartSectionData(value: progress.toDouble(), color: Colors.orange, title: 'Active', radius: 50),
          PieChartSectionData(value: assigned.toDouble(), color: Colors.blue, title: 'New', radius: 50),
          // Added Classified Section
          PieChartSectionData(value: classified.toDouble(), color: Colors.redAccent, title: 'Classified', radius: 50),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildSummaryCard(int total, int resolved, int classified) {
    double rate = total == 0 ? 0 : (resolved / total) * 100;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _columnData("Total Issues", total.toString()),
            _columnData("Classified", classified.toString()), // Added to summary card
            _columnData("Resolution Rate", "${rate.toStringAsFixed(1)}%"),
          ],
        ),
      ),
    );
  }

  Widget _columnData(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
      ],
    );
  }
}