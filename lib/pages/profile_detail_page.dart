import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../helpers/ocr_service.dart';
import '../models/profile.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class ProfileDetailPage extends StatefulWidget {
  final int profileId;
  const ProfileDetailPage({super.key, required this.profileId});
  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late Future<Profile?> _profileFuture;
  late Future<List<Transaction>> _transactionsFuture;
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _profileFuture = dbHelper.getProfileById(widget.profileId);
      _transactionsFuture = dbHelper.getTransactionsForProfile(widget.profileId);
    });
  }

  void _showAddTransactionDialog() async {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String currency = 'USD';
    String type = 'expense';
    List<Category> categories = await dbHelper.getCategories();
    Category? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'expense' ? "New Expense" : "New Income"),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  tooltip: "Scan Receipt",
                  onPressed: () async {
                    final result = await OcrService().pickAndProcessImage();
                    if (result.isNotEmpty) {
                      setDialogState(() {
                        amountController.text = result['amount']!;
                        descController.text = result['description']!;
                      });
                    }
                  },
                ),
                ToggleButtons(
                  isSelected: [type == 'expense', type == 'income'],
                  onPressed: (index) => setDialogState(() => type = index == 0 ? 'expense' : 'income'),
                  borderRadius: BorderRadius.circular(8),
                  children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Expense")), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Income"))],
                ),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
                DropdownButton<String>(
                  value: currency,
                  onChanged: (val) => setDialogState(() => currency = val!),
                  items: <String>['USD', 'IQD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
                DropdownButton<Category>(
                  hint: const Text("Select Category"),
                  value: selectedCategory,
                  isExpanded: true,
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                  items: categories.map((cat) => DropdownMenuItem(value: cat, child: Row(children: [Icon(cat.icon, color: cat.color), const SizedBox(width: 8), Text(cat.name)]))).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && descController.text.isNotEmpty && selectedCategory != null) {
                final newTx = Transaction(
                  profileId: widget.profileId,
                  categoryId: selectedCategory!.id!,
                  type: type,
                  description: descController.text,
                  amount: amount,
                  currency: currency,
                  date: DateTime.now().toIso8601String(),
                );
                await dbHelper.insertTransaction(newTx);
                _refreshData();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00");
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Profile?>(
          future: _profileFuture,
          builder: (context, snapshot) => Text(snapshot.hasData ? snapshot.data!.name : 'Profile Details'),
        ),
      ),
      body: Column(
        children: [
          FutureBuilder<Profile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator());
              final profile = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("USD: \$${currencyFormat.format(profile.dollarBalance)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("IQD: ${currencyFormat.format(profile.dinarBalance)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Text("Transactions", style: Theme.of(context).textTheme.titleLarge),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text("No transactions for this profile."));
                
                final transactions = snapshot.data!;
                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isIncome = tx.type == 'income';
                    return ListTile(
                      title: Text(tx.description),
                      subtitle: Text(DateFormat.yMMMd().format(DateTime.parse(tx.date))),
                      trailing: Text(
                        "${isIncome ? '+' : '-'} ${tx.currency} ${currencyFormat.format(tx.amount)}",
                        style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}