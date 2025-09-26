import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

import '../helpers/database_helper.dart';
import '../models/transaction.dart';

class ExportService {
  final dbHelper = DatabaseHelper();

  // Exports transactions from the FIRST profile found.
  Future<void> exportToCsv() async {
    final profiles = await dbHelper.getProfiles();
    if (profiles.isEmpty) {
      debugPrint("No profiles to export from.");
      return; 
    }
    
    final firstProfileId = profiles.first.id!;
    final transactions = await dbHelper.getTransactionsForProfile(firstProfileId);
    if (transactions.isEmpty) {
      debugPrint("No transactions to export.");
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(["id", "profileId", "categoryId", "type", "description", "amount", "currency", "date"]);
    for (var tx in transactions) {
      rows.add([tx.id, tx.profileId, tx.categoryId, tx.type, tx.description, tx.amount, tx.currency, tx.date]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/financial_backup.csv";
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: 'My Financial Data Backup (CSV)');
  }

  Future<void> exportToSql() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finance_v3.db');
    final file = File(path);

    if (await file.exists()) {
       await Share.shareXFiles([XFile(path)], text: 'My Full Database Backup (.db)');
    }
  }

  // Imports transactions into the FIRST profile found.
  Future<void> importFromCsv() async {
    final profiles = await dbHelper.getProfiles();
    if (profiles.isEmpty) {
      debugPrint("No profile exists to import data into.");
      return;
    }
    final targetProfileId = profiles.first.id!;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      
      // ✅ This variable is now used by the for loop below, fixing the warning.
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter(shouldParseNumbers: true).convert(csvString);
      
      // For this simple import, we clear only the transactions of the target profile
      // A more complex app might ask the user what to do.
      
      // Start from the first row of data (i=1 to skip header)
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        // Create a map to pass to the fromMap factory
        final transaction = Transaction(
          profileId: targetProfileId, // Import into the first profile
          categoryId: row[2] as int,
          type: row[3].toString(),
          description: row[4].toString(),
          amount: row[5] as double,
          currency: row[6].toString(),
          date: row[7].toString(),
        );
        // We use the regular insert method which also updates the balance
        await dbHelper.insertTransaction(transaction);
      }
      debugPrint("Import complete!");
    }
  }
}