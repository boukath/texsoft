// lib/core/services/printer_service.dart
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/store_settings.dart';
import '../models/analytics/sales_summary.dart'; // <-- IMPORTÉ
import 'database_service.dart';
import 'settings_service.dart';

class PrinterService {
  PrinterService._init();
  static final PrinterService instance = PrinterService._init();

  // --- NOUVELLE FONCTION ---
  Future<void> printClotureReport(
      SalesSummary summary,
      double montantCompte,
      double difference,
      User adminUser,
      ) async {
    final settings = await SettingsService.instance.loadSettings();
    final pdf = await _generateCloturePdf(summary, montantCompte, difference, adminUser, settings);

    // Utilise la même imprimante que le reçu client
    Printer? printer;
    if (settings.imprimanteClient != null) {
      try {
        printer = (await Printing.listPrinters()).firstWhere((p) => p.name == settings.imprimanteClient);
      } catch (e) {
        printer = null;
      }
    }

    if (printer != null) {
      await Printing.directPrintPdf(printer: printer, onLayout: (_) => pdf);
    } else {
      await Printing.layoutPdf(onLayout: (_) => pdf); // Ouvre le dialogue
    }
  }

  Future<void> printOrder(int orderId, List<CartItem> items, double total, User cashier) async {
    final settings = await SettingsService.instance.loadSettings();
    final printers = await Printing.listPrinters();

    // --- Ticket Client ---
    final clientPdf = await _generateClientReceipt(orderId, items, total, cashier, settings);
    Printer? clientPrinter;
    if (settings.imprimanteClient != null) {
      try {
        clientPrinter = printers.firstWhere((p) => p.name == settings.imprimanteClient);
      } catch (e) { /* non trouvé */ }
    }
    if (clientPrinter != null) {
      await Printing.directPrintPdf(printer: clientPrinter, onLayout: (_) => clientPdf);
    } else {
      await Printing.layoutPdf(onLayout: (_) => clientPdf);
    }

    // --- Routage Cuisine ---
    final categories = await DatabaseService.instance.getCategories();
    final Map<String, List<CartItem>> kitchenGroups = {};
    for (var item in items) {
      final category = categories.firstWhere((c) => c.id == item.product.categoryId);
      if (category.targetPrinter != null && category.targetPrinter!.isNotEmpty) {
        final printerName = category.targetPrinter!;
        if (!kitchenGroups.containsKey(printerName)) kitchenGroups[printerName] = [];
        kitchenGroups[printerName]!.add(item);
      }
    }
    for (var entry in kitchenGroups.entries) {
      final printerName = entry.key;
      final groupItems = entry.value;
      Printer? targetPrinter;
      try {
        targetPrinter = printers.firstWhere((p) => p.name == printerName);
      } catch (e) { continue; }
      final kitchenPdf = await _generateKitchenTicket(orderId, groupItems, printerName);
      await Printing.directPrintPdf(printer: targetPrinter, onLayout: (_) => kitchenPdf);
    }
  }

  // --- GENERATE CLIENT RECEIPT ---
  Future<Uint8List> _generateClientReceipt(int orderId, List<CartItem> items, double total, User cashier, StoreSettings settings) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(settings.nomMagasin, style: pw.TextStyle(font: bold, fontSize: 20))),
              pw.Center(child: pw.Text(settings.adresseMagasin, style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Center(child: pw.Text(settings.telephoneMagasin, style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("CMD #: $orderId", style: pw.TextStyle(font: bold, fontSize: 12)),
                pw.Text(DateTime.now().toString().substring(0, 16), style: pw.TextStyle(font: font, fontSize: 10)),
              ]),
              pw.Text("Caissier: ${cashier.username}", style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(),
              ...items.map((item) {
                return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text("${item.product.name} (${item.variant.name})", style: pw.TextStyle(font: font, fontSize: 10))),
                      pw.Text("x${item.quantity}", style: pw.TextStyle(font: bold, fontSize: 10)),
                      pw.SizedBox(width: 10),
                      pw.Text("${(item.variant.price * item.quantity).toStringAsFixed(2)}", style: pw.TextStyle(font: font, fontSize: 10)),
                    ]
                );
              }).toList(),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("TOTAL", style: pw.TextStyle(font: bold, fontSize: 16)),
                pw.Text("${total.toStringAsFixed(2)} DZD", style: pw.TextStyle(font: bold, fontSize: 16)),
              ]),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Merci de votre visite!", style: pw.TextStyle(font: font, fontSize: 12))),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- GENERATE KITCHEN TICKET ---
  Future<Uint8List> _generateKitchenTicket(int orderId, List<CartItem> items, String stationName) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("CUISINE", style: pw.TextStyle(font: bold, fontSize: 24))),
              pw.Center(child: pw.Text("($stationName)", style: pw.TextStyle(font: font, fontSize: 12))),
              pw.Divider(thickness: 2),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("CMD #: $orderId", style: pw.TextStyle(font: bold, fontSize: 18)),
                pw.Text(DateTime.now().toString().substring(11, 16), style: pw.TextStyle(font: font, fontSize: 14)),
              ]),
              pw.Divider(thickness: 2),
              ...items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("${item.quantity}", style: pw.TextStyle(font: bold, fontSize: 24)),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(item.product.name, style: pw.TextStyle(font: bold, fontSize: 16)),
                            pw.Text(item.variant.name, style: pw.TextStyle(font: font, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              pw.Divider(thickness: 2),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // --- NOUVELLE FONCTION PDF : RAPPORT Z ---
  Future<Uint8List> _generateCloturePdf(
      SalesSummary summary,
      double montantCompte,
      double difference,
      User adminUser,
      StoreSettings settings,
      ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(5),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text("Rapport de Clôture (Z)", style: pw.TextStyle(font: bold, fontSize: 16))),
              pw.Center(child: pw.Text(settings.nomMagasin, style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),
              pw.Text("Date: ${now.toString().substring(0, 16)}", style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text("Opérateur: ${adminUser.username}", style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(thickness: 2),

              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Total Ventes (Attendu):", style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("${summary.totalRevenue.toStringAsFixed(2)} DZD", style: pw.TextStyle(font: bold, fontSize: 12)),
              ]),
              pw.SizedBox(height: 10),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Montant Compté (Caisse):", style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("${montantCompte.toStringAsFixed(2)} DZD", style: pw.TextStyle(font: bold, fontSize: 12)),
              ]),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Différence:", style: pw.TextStyle(font: bold, fontSize: 16)),
                pw.Text("${difference.toStringAsFixed(2)} DZD", style: pw.TextStyle(font: bold, fontSize: 16)),
              ]),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              pw.Center(child: pw.Text("--- Fin du Rapport ---", style: pw.TextStyle(font: font, fontSize: 10))),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}