import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../helpers/database_helper.dart';
import '../models/profile.dart';
import '../models/category.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final dbHelper = DatabaseHelper();
  Profile? _selectedProfile;
  late Future<List<Profile>> _profilesFuture;
  late Future<List<Category>> _categoriesFuture;


  @override
  void initState() {
    super.initState();
    _profilesFuture = dbHelper.getProfiles();
    _categoriesFuture = dbHelper.getCategories();

    _profilesFuture.then((profiles) {
      if (profiles.isNotEmpty) {
        setState(() => _selectedProfile = profiles.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<List<Profile>>(
              future: _profilesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Create a profile to see reports."));
                return DropdownButton<Profile>(
                  isExpanded: true,
                  value: _selectedProfile,
                  hint: const Text("Select Profile"),
                  onChanged: (p) => setState(() => _selectedProfile = p),
                  items: snapshot.data!.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            if (_selectedProfile != null) ...[
              Text("Monthly Spending by Category", style: Theme.of(context).textTheme.titleLarge),
              SizedBox(
                height: 300,
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                     dbHelper.getCategorySpending(_selectedProfile!.id!, DateTime.now()),
                     _categoriesFuture
                  ]),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || (snapshot.data![0] as Map).isEmpty) {
                      return const Center(child: Text("No spending data for this month."));
                    }
                    final spendingData = snapshot.data![0] as Map<String, double>;
                    final categories = snapshot.data![1] as List<Category>;

                    return PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: spendingData.entries.map((entry) {
                           final category = categories.firstWhere((cat) => cat.name == entry.key, orElse: () => Category(name: "Unknown", iconCodePoint: Icons.help.codePoint, colorValue: Colors.grey.value));
                           return PieChartSectionData(
                              color: category.color,
                              value: entry.value,
                              title: '${entry.key}\n(${entry.value.toStringAsFixed(0)})',
                              radius: 100,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                           );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              // You can add the Bar Chart for income vs expense here in the future
            ],
          ],
        ),
      ),
    );
  }
}