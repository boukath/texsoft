// lib/core/services/csv_import_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class CsvImportService {
  // Singleton pattern
  CsvImportService._privateConstructor();
  static final CsvImportService instance = CsvImportService._privateConstructor();

  Future<String> importMenuFromCsv() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return "Annulé"; // "Cancelled" in French

      final File file = File(result.files.single.path!);
      final input = file.openRead();

      // 2. Convert CSV to List of Lists
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      // 3. Pre-load existing data to minimize DB calls (Performance)
      final db = DatabaseService.instance;

      List<Category> existingCats = await db.getCategories();
      Map<String, int> catMap = {for (var e in existingCats) e.name.toLowerCase(): e.id};

      List<Product> existingProds = await db.getAllProducts();
      // Key: "catId-prodName" -> Value: prodId
      Map<String, int> prodMap = {for (var e in existingProds) "${e.categoryId}-${e.name.toLowerCase()}": e.id};

      int addedCount = 0;

      // 4. Iterate through CSV rows
      // Expected Format: [Category, Product, Variant, Price]
      for (var row in fields) {
        if (row.length < 4) continue; // Skip invalid rows

        // Clean data
        String catName = row[0].toString().trim();
        String prodName = row[1].toString().trim();
        String varName = row[2].toString().trim();
        double price = double.tryParse(row[3].toString()) ?? 0.0;

        if (catName.isEmpty || prodName.isEmpty) continue;

        // --- A. Handle Category ---
        int catId;
        if (catMap.containsKey(catName.toLowerCase())) {
          catId = catMap[catName.toLowerCase()]!;
        } else {
          // Create new Category
          // FIXED: Added 'null' for targetPrinter
          await db.createCategory(catName, null);

          // Re-fetch to get ID
          final newCats = await db.getCategories();
          final newCat = newCats.firstWhere((c) => c.name == catName);
          catId = newCat.id;
          catMap[catName.toLowerCase()] = catId;
        }

        // --- B. Handle Product ---
        int prodId;
        String prodKey = "$catId-${prodName.toLowerCase()}";

        if (prodMap.containsKey(prodKey)) {
          prodId = prodMap[prodKey]!;
        } else {
          // Create new Product
          // FIXED: Added 'null' for imagePath
          await db.createProduct(prodName, catId, null);

          // Re-fetch to get ID
          final newProds = await db.getAllProducts();
          final newProd = newProds.firstWhere((p) => p.name == prodName && p.categoryId == catId);
          prodId = newProd.id;
          prodMap[prodKey] = prodId;
        }

        // --- C. Handle Variant ---
        await db.createVariant(prodId, varName, price);
        addedCount++;
      }

      return "Succès : $addedCount variantes ajoutées.";

    } catch (e) {
      return "Erreur : $e";
    }
  }
}