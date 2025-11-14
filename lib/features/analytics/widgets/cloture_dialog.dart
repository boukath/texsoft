// lib/features/analytics/widgets/cloture_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/analytics/sales_summary.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/printer_service.dart';
import '../../../common/theme/app_theme.dart';

class ClotureDialog extends StatefulWidget {
  final User adminUser;

  const ClotureDialog({Key? key, required this.adminUser}) : super(key: key);

  @override
  State<ClotureDialog> createState() => _ClotureDialogState();
}

class _ClotureDialogState extends State<ClotureDialog> {
  final _controller = TextEditingController();
  late Future<SalesSummary> _summaryFuture;

  double _montantCompte = 0.0;
  double _totalAttendu = 0.0;
  double get _difference => _montantCompte - _totalAttendu;

  @override
  void initState() {
    super.initState();
    _summaryFuture = DatabaseService.instance.getTodaySalesSummary();
  }

  void _onMontantChange(String value) {
    setState(() {
      _montantCompte = double.tryParse(value) ?? 0.0;
    });
  }

  void _handlePrint() async {
    // 1. Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Préparer le rapport
    final summary = SalesSummary(
      totalRevenue: _totalAttendu,
      totalOrders: 0, // Le nbre de commandes n'est pas affiché, on peut mettre 0
    );

    // 3. Appeler le service d'impression
    try {
      await PrinterService.instance.printClotureReport(
        summary,
        _montantCompte,
        _difference,
        widget.adminUser,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le chargement
      Navigator.of(context).pop(); // Fermer la boîte de dialogue Cloture

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rapport de clôture envoyé à l'imprimante."), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fermer le chargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'impression: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Clôture de Caisse (Rapport Z)", style: TextStyle(fontWeight: FontWeight.bold)),
      content: FutureBuilder<SalesSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(width: 400, height: 100, child: Center(child: CircularProgressIndicator()));
          }

          _totalAttendu = snapshot.data!.totalRevenue;

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRow("Total Ventes Attendu (DB)", "${_totalAttendu.toStringAsFixed(2)} DZD", AppTheme.primaryColor, 18),
                const Divider(height: 24),
                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Montant Compté (Espèces)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  onChanged: _onMontantChange,
                ),
                const SizedBox(height: 24),
                _buildRow("Différence", "${_difference.toStringAsFixed(2)} DZD", _difference == 0 ? Colors.green : Colors.red, 20),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Annuler"),
        ),
        ElevatedButton.icon(
          onPressed: _handlePrint,
          icon: const Icon(Icons.print),
          label: const Text("Valider et Imprimer"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String titre, String valeur, Color couleur, double taillePolice) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titre, style: TextStyle(fontSize: 16, color: AppTheme.textLight)),
          Text(
            valeur,
            style: TextStyle(
              fontSize: taillePolice,
              fontWeight: FontWeight.bold,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }
}