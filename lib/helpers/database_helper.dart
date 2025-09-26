import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/transaction.dart';
import '../models/profile.dart';
import '../models/wishlist_item.dart';
import '../models/category.dart';
import '../models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'finance_v3.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, description TEXT, dollarBalance REAL, dinarBalance REAL)
    ''');
    await db.execute('''
      CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, iconCodePoint INTEGER, colorValue INTEGER)
    ''');
    await db.execute('''
      CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, limitAmount REAL, FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE)
    ''');
    await db.execute('''
      CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, categoryId INTEGER, type TEXT, description TEXT, amount REAL, currency TEXT, date TEXT,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL)
    ''');
    await db.execute('''
      CREATE TABLE wishlist_items(id INTEGER PRIMARY KEY AUTOINCREMENT, profileId INTEGER, name TEXT, price REAL, currency TEXT,
        FOREIGN KEY (profileId) REFERENCES profiles (id) ON DELETE CASCADE)
    ''');

    // Add some default categories
    await _createDefaultCategory(db, 'Food', Icons.fastfood, Colors.orange);
    await _createDefaultCategory(db, 'Transport', Icons.directions_car, Colors.blue);
    await _createDefaultCategory(db, 'Shopping', Icons.shopping_bag, Colors.pink);
    await _createDefaultCategory(db, 'Bills', Icons.receipt, Colors.red);
    await _createDefaultCategory(db, 'Income', Icons.attach_money, Colors.green);
    await _createDefaultCategory(db, 'Other', Icons.category, Colors.grey);
  }

  Future<void> _createDefaultCategory(Database db, String name, IconData icon, Color color) async {
    await db.insert('categories', Category(name: name, iconCodePoint: icon.codePoint, colorValue: color.value).toMap());
  }

  // --- Profile Methods ---
  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    return await db.insert('profiles', profile.toMap());
  }
  Future<List<Profile>> getProfiles() async {
    final db = await database;
    final maps = await db.query('profiles');
    return List.generate(maps.length, (i) => Profile.fromMap(maps[i]));
  }
  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }
  Future<Profile?> getProfileById(int id) async {
    final db = await database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Profile.fromMap(maps.first);
    return null;
  }

  // --- Transaction Methods ---
  Future<void> insertTransaction(Transaction tx) async {
    final db = await database;
    await db.insert('transactions', tx.toMap());
    Profile? profile = await getProfileById(tx.profileId);
    if (profile != null) {
      double amount = tx.amount;
      if (tx.type == 'expense') {
        amount = -amount; // Subtract for expense
      }

      if (tx.currency == 'USD') {
        profile.dollarBalance += amount;
      } else {
        profile.dinarBalance += amount;
      }
      await updateProfile(profile);
    }
  }
  Future<List<Transaction>> getTransactionsForProfile(int profileId) async {
    final db = await database;
    final maps = await db.query('transactions', where: 'profileId = ?', whereArgs: [profileId], orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }
   Future<void> clearAllData() async {
     final db = await database;
     await db.delete('transactions');
     // This part should be updated to handle multiple profiles if needed,
     // for now it resets a specific profile as an example.
     // await updateProfile(Profile(id: 1, name: 'Default', description: '', dollarBalance: 0, dinarBalance: 0));
  }

  // --- Category & Budget Methods ---
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }
  Future<void> setBudget(Budget budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final maps = await db.query('budgets');
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // --- Wishlist Methods ---
  Future<void> insertWishlistItem(WishlistItem item) async {
    final db = await database;
    await db.insert('wishlist_items', item.toMap());
  }
  Future<List<WishlistItem>> getWishlistForProfile(int profileId) async {
    final db = await database;
    final maps = await db.query('wishlist_items', where: 'profileId = ?', whereArgs: [profileId]);
    return List.generate(maps.length, (i) => WishlistItem.fromMap(maps[i]));
  }
  Future<void> deleteWishlistItem(int id) async {
    final db = await database;
    await db.delete('wishlist_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- Charting Queries ---
  Future<Map<String, double>> getCategorySpending(int profileId, DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1).toIso8601String();
    final endDate = DateTime(month.year, month.month + 1, 0).toIso8601String();

    final result = await db.rawQuery('''
      SELECT c.name, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.categoryId = c.id
      WHERE t.profileId = ? AND t.type = 'expense' AND t.date BETWEEN ? AND ?
      GROUP BY c.name
    ''', [profileId, startDate, endDate]);

    return { for (var row in result) row['name'] as String : row['total'] as double };
  }
}