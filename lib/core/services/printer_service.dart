// lib/core/services/printer_service.dart
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cart_item_model.dart';
import '../models/user_model.dart';

class PrinterService {
  // Singleton
  PrinterService._init();
  static final PrinterService instance = PrinterService._init();

  // --- Configuration des Imprimantes (A mettre dans les Paramètres plus tard) ---
  // Remplacez par le nom EXACT de vos imprimantes sous Windows
  final String _clientPrinterName = "Microsoft Print to PDF";
  final String _kitchenPrinterName = "Microsoft Print to PDF";

  // --- Fonction Principale : Imprimer tout ---
  Future<void> printOrder(int orderId, List<CartItem> items, double total, User cashier) async {
    // 1. Récupérer la liste des imprimantes connectées
    final printers = await Printing.listPrinters();

    // 2. Trouver l'imprimante Client
    Printer? clientPrinter;
    try {
      clientPrinter = printers.firstWhere((p) => p.name == _clientPrinterName);
    } catch (e) {
      // Si pas trouvée, on peut utiliser l'imprimante par défaut ou ne rien faire
      print("Imprimante Client non trouvée: $_clientPrinterName");
    }

    // 3. Trouver l'imprimante Cuisine
    Printer? kitchenPrinter;
    try {
      kitchenPrinter = printers.firstWhere((p) => p.name == _kitchenPrinterName);
    } catch (e) {
      print("Imprimante Cuisine non trouvée: $_kitchenPrinterName");
    }

    // 4. Générer et Imprimer le Ticket Client
    final clientPdf = await _generateClientReceipt(orderId, items, total, cashier);
    await Printing.directPrintPdf(
      printer: clientPrinter ?? const Printer(url: 'fallback'), // Imprime sur l'imprimante trouvée ou par défaut
      onLayout: (format) async => clientPdf,
      name: 'Ticket_Client_$orderId',
      usePrinterSettings: true, // Utiliser les réglages de l'OS (coupure papier, etc.)
    );

    // 5. Générer et Imprimer le Ticket Cuisine (si des produits le nécessitent)
    // Pour l'instant on imprime tout le ticket en cuisine
    final kitchenPdf = await _generateKitchenTicket(orderId, items);
    if (kitchenPrinter != null) {
      await Printing.directPrintPdf(
        printer: kitchenPrinter,
        onLayout: (format) async => kitchenPdf,
        name: 'Ticket_Cuisine_$orderId',
        usePrinterSettings: true,
      );
    } else {
      // Optionnel: Imprimer cuisine sur l'imprimante par défaut si pas d'imprimante dédiée configurée
      // await Printing.layoutPdf(onLayout: (format) async => kitchenPdf, name: 'Ticket_Cuisine_Preview');
    }
  }

  // --- Génération PDF : Ticket Client ---
  Future<Uint8List> _generateClientReceipt(int orderId, List<CartItem> items, double total, User cashier) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Format Ticket de Caisse (80mm)
        margin: const pw.EdgeInsets.all(5), // Marges fines
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(child: pw.Text("TEXSOFT", style: pw.TextStyle(font: bold, fontSize: 20))),
              pw.Center(child: pw.Text("Fast Food & Grill", style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Center(child: pw.Text("Adresse: Kouba, Alger", style: pw.TextStyle(font: font, fontSize: 10))),
              pw.Divider(),

              // Info Commande
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Date: ${DateTime.now().toString().substring(0, 16)}", style: pw.TextStyle(font: font, fontSize: 10)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Commande #: $orderId", style: pw.TextStyle(font: bold, fontSize: 12)),
                pw.Text("Caissier: ${cashier.username}", style: pw.TextStyle(font: font, fontSize: 10)),
              ]),
              pw.Divider(),

              // Articles
              pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // Nom
                    1: const pw.FlexColumnWidth(1), // Qté
                    2: const pw.FlexColumnWidth(1), // Prix
                  },
                  children: [
                    // Header Tableau
                    pw.TableRow(children: [
                      pw.Text("Article", style: pw.TextStyle(font: bold, fontSize: 10)),
                      pw.Text("Qté", style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.right),
                      pw.Text("Total", style: pw.TextStyle(font: bold, fontSize: 10), textAlign: pw.TextAlign.right),
                    ]),
                    // Lignes
                    ...items.map((item) {
                      return pw.TableRow(children: [
                        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(item.product.name, style: pw.TextStyle(font: font, fontSize: 10)),
                          pw.Text(item.variant.name, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)),
                        ]),
                        pw.Text("x${item.quantity}", style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right),
                        pw.Text("${(item.variant.price * item.quantity).toStringAsFixed(2)}", style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right),
                      ]);
                    }).toList()
                  ]
              ),
              pw.Divider(),

              // Totaux
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("TOTAL", style: pw.TextStyle(font: bold, fontSize: 16)),
                pw.Text("${total.toStringAsFixed(2)} DZD", style: pw.TextStyle(font: bold, fontSize: 16)),
              ]),

              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("Merci de votre visite!", style: pw.TextStyle(font: font, fontSize: 12))),
              pw.Center(child: pw.Text("A bientot.", style: pw.TextStyle(font: font, fontSize: 10))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Génération PDF : Ticket Cuisine ---
  Future<Uint8List> _generateKitchenTicket(int orderId, List<CartItem> items) async {
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
              // Header Cuisine (Très gros pour être lisible de loin)
              pw.Center(child: pw.Text("CUISINE", style: pw.TextStyle(font: bold, fontSize: 24))),
              pw.Divider(thickness: 2),
              pw.Text("COMMANDE #: $orderId", style: pw.TextStyle(font: bold, fontSize: 18)),
              pw.Text("Heure: ${DateTime.now().toString().substring(11, 16)}", style: pw.TextStyle(font: font, fontSize: 14)),
              pw.Divider(thickness: 2),

              // Liste simplifiée (Nom + Quantité seulement)
              ...items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Quantité en très gros
                      pw.Text("${item.quantity} x ", style: pw.TextStyle(font: bold, fontSize: 20)),
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
              pw.Center(child: pw.Text("FIN DE COMMANDE", style: pw.TextStyle(font: font, fontSize: 10))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}