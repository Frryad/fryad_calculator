import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/category.dart';
import '../models/budget.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});
  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final dbHelper = DatabaseHelper();
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Budget>> _budgetsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _categoriesFuture = dbHelper.getCategories();
      _budgetsFuture = dbHelper.getBudgets();
    });
  }

  void _showSetBudgetDialog(Category category, Budget? currentBudget) {
      final amountController = TextEditingController(text: currentBudget?.limitAmount.toString() ?? '');
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Set Budget for ${category.name}"),
              content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monthly Limit")),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                  ElevatedButton(
                      onPressed: () async {
                          final limit = double.tryParse(amountController.text) ?? 0;
                          // Allow setting a budget of 0 to remove it
                          if (limit >= 0) {
                              final newBudget = Budget(id: currentBudget?.id, categoryId: category.id!, limitAmount: limit);
                              await dbHelper.setBudget(newBudget);
                              _refreshData();
                          }
                          Navigator.pop(context);
                      },
                      child: const Text("Set"))
              ]));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Budgets")),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_categoriesFuture, _budgetsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text("Could not load data."));

          final categories = snapshot.data![0] as List<Category>;
          final budgets = snapshot.data![1] as List<Budget>;
          
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              // Don't show budget option for "Income"
              if(category.name.toLowerCase() == 'income') return const SizedBox.shrink();

              final budget = budgets.firstWhere((b) => b.categoryId == category.id, orElse: () => Budget(categoryId: category.id!, limitAmount: 0));
              
              // Here you would also fetch the actual spending for the month to show progress.
              // For simplicity, we'll just show the limit.
              
              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                subtitle: Text(budget.limitAmount > 0 ? "Limit: ${budget.limitAmount}" : "No budget set"),
                trailing: const Icon(Icons.edit),
                onTap: () => _showSetBudgetDialog(category, budget.limitAmount > 0 ? budget : null),
              );
            },
          );
        },
      ),
    );
  }
}