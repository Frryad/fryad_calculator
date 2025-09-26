import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/profile.dart';
import '../models/wishlist_item.dart';
import '../models/transaction.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Profile> _profiles = [];
  Profile? _selectedProfile;
  List<WishlistItem> _wishlistItems = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await dbHelper.getProfiles();
    setState(() {
      _profiles = profiles;
      if (_profiles.isNotEmpty) {
        _selectedProfile = _profiles.first;
        _loadWishlist();
      }
    });
  }

  Future<void> _loadWishlist() async {
    if (_selectedProfile == null) return;
    final items = await dbHelper.getWishlistForProfile(_selectedProfile!.id!);
    setState(() {
      _wishlistItems = items;
    });
  }

  void _showWishlistDialog() {
    if (_selectedProfile == null) return;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String currency = 'USD';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add to Wishlist"),
        content: StatefulBuilder(builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
            DropdownButton<String>(
              value: currency,
              onChanged: (val) => setDialogState(() => currency = val!),
              items: <String>['USD', 'IQD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            ),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if(nameController.text.isEmpty || priceController.text.isEmpty) return;
              final newItem = WishlistItem(
                profileId: _selectedProfile!.id!,
                name: nameController.text,
                price: double.tryParse(priceController.text) ?? 0,
                currency: currency,
              );
              await dbHelper.insertWishlistItem(newItem);
              _loadWishlist();
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _buyItem(WishlistItem item) async {
    final newTx = Transaction(
      profileId: item.profileId,
      // Default to the "Shopping" category, ID 3
      categoryId: 3, 
      type: 'expense',
      description: "Bought: ${item.name}",
      amount: item.price,
      currency: item.currency,
      date: DateTime.now().toIso8601String(),
    );
    await dbHelper.insertTransaction(newTx);
    await dbHelper.deleteWishlistItem(item.id!);
    await _loadProfiles();
    _loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wishlist")),
      body: Column(
        children: [
          if (_profiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<Profile>(
                isExpanded: true,
                value: _selectedProfile,
                hint: const Text("Select a Profile"),
                onChanged: (Profile? newValue) {
                  setState(() {
                    _selectedProfile = newValue;
                    _loadWishlist();
                  });
                },
                items: _profiles.map((Profile profile) {
                  return DropdownMenuItem<Profile>(
                    value: profile,
                    child: Text(profile.name),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _wishlistItems.isEmpty
                ? const Center(child: Text("No items in wishlist for this profile."))
                : ListView.builder(
                    itemCount: _wishlistItems.length,
                    itemBuilder: (context, index) {
                      final item = _wishlistItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text("${item.currency} ${item.price}"),
                        trailing: ElevatedButton(
                          onPressed: () => _buyItem(item),
                          child: const Text("Buy"),
                        ),
                      );
},
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedProfile == null ? null : _showWishlistDialog,
        backgroundColor: _selectedProfile == null ? Colors.grey : Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}