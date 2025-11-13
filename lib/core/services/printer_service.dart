// lib/core/services/printer_service.dart
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item_model.dart';
import '../models/user_model.dart';
import '../models/category_model.dart';
import 'database_service.dart'; // Needed to fetch categories

class PrinterService {
  // Singleton
  PrinterService._init();
  static final PrinterService instance = PrinterService._init();

  // --- MAIN PRINT FUNCTION ---
  Future<void> printOrder(int orderId, List<CartItem> items, double total, User cashier) async {
    // 1. Get list of connected printers in Windows
    final printers = await Printing.listPrinters();

    // ---------------------------------------------------------
    // STEP A: PRINT CLIENT TICKET (Everything)
    // ---------------------------------------------------------
    // We use the default printer for the client ticket
    // In a real app, you could also make this configurable in Settings
    final clientPdf = await _generateClientReceipt(orderId, items, total, cashier);

    await Printing.layoutPdf(
      onLayout: (format) async => clientPdf,
      name: 'Ticket_Client_$orderId',
      // format: PdfPageFormat.roll80, // Force roll format if needed
    );

    // ---------------------------------------------------------
    // STEP B: SMART KITCHEN ROUTING
    // ---------------------------------------------------------

    // 1. Fetch Categories to check Printer Routing logic
    final categories = await DatabaseService.instance.getCategories();

    // 2. Group items by Printer Name
    // Map Structure: { "EPSON TM-T20": [Burger, Fries], "STAR TSP": [Pizza], "null": [Coke] }
    final Map<String, List<CartItem>> kitchenGroups = {};

    for (var item in items) {
      // Find the category of this item to see its targetPrinter
      final category = categories.firstWhere(
            (c) => c.id == item.product.categoryId,
        orElse: () => Category(id: 0, name: 'Unknown'),
      );

      // Only process if a target printer is set (not null, not empty)
      if (category.targetPrinter != null && category.targetPrinter!.isNotEmpty) {
        final printerName = category.targetPrinter!;

        if (!kitchenGroups.containsKey(printerName)) {
          kitchenGroups[printerName] = [];
        }
        kitchenGroups[printerName]!.add(item);
      }
    }

    // 3. Send jobs to specific Kitchen Printers
    for (var entry in kitchenGroups.entries) {
      final printerName = entry.key;
      final groupItems = entry.value;

      // Find the actual printer object in the system list
      Printer? targetPrinter;
      try {
        targetPrinter = printers.firstWhere((p) => p.name == printerName);
      } catch (e) {
        print("ERREUR: Imprimante '$printerName' introuvable ou éteinte.");
        continue; // Skip this group if printer is missing
      }

      // Generate PDF specifically for this station (e.g., "Poste Pizza")
      final kitchenPdf = await _generateKitchenTicket(orderId, groupItems, printerName);

      // Direct Print (No popup dialog, goes straight to the specific printer)
      await Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (format) async => kitchenPdf,
        name: 'Ticket_Cuisine_${printerName}_$orderId',
        usePrinterSettings: true, // Use cutter/drawer settings if available
      );
    }
  }

  // --- GENERATE CLIENT RECEIPT (Prices included) ---
  Future<Uint8List> _generateClientReceipt(int orderId, List<CartItem> items, double total, User cashier) async {
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
              pw.Center(child: pw.Text("TEXSOFT", style: pw.TextStyle(font: bold, fontSize: 20))),
              pw.Center(child: pw.Text("Fast Food & Grill", style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("CMD #: $orderId", style: pw.TextStyle(font: bold, fontSize: 12)),
                pw.Text(DateTime.now().toString().substring(0, 16), style: pw.TextStyle(font: font, fontSize: 10)),
              ]),
              pw.Text("Caissier: ${cashier.username}", style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Divider(),

              // Items Table
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

  // --- GENERATE KITCHEN TICKET (No prices, Big Fonts) ---
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
              // Header showing which printer this is (e.g. "Epson Kitchen")
              pw.Center(child: pw.Text("CUISINE", style: pw.TextStyle(font: bold, fontSize: 24))),
              pw.Center(child: pw.Text("($stationName)", style: pw.TextStyle(font: font, fontSize: 12))),
              pw.Divider(thickness: 2),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("CMD #: $orderId", style: pw.TextStyle(font: bold, fontSize: 18)),
                pw.Text(DateTime.now().toString().substring(11, 16), style: pw.TextStyle(font: font, fontSize: 14)),
              ]),
              pw.Divider(thickness: 2),

              // List items with BIG Quantity
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
                            pw.Text(item.product.name, style: pw.TextStyle(font: bold, fontSize: 18)),
                            pw.Text(item.variant.name, style: pw.TextStyle(font: font, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 2),
              pw.Center(child: pw.Text("--- FIN ---", style: pw.TextStyle(font: font, fontSize: 10))),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}