// lib/features/pos_grid/widgets/payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({Key? key, required this.totalAmount}) : super(key: key);

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _controller = TextEditingController();
  double _amountTendered = 0.0;

  @override
  void initState() {
    super.initState();
    // Default to exact amount so they can just hit Enter if needed
    _amountTendered = widget.totalAmount;
    _controller.text = _amountTendered.toStringAsFixed(2);
  }

  void _updateAmount(String value) {
    setState(() {
      _amountTendered = double.tryParse(value) ?? 0.0;
    });
  }

  double get _change => _amountTendered - widget.totalAmount;
  bool get _isValid => _amountTendered >= widget.totalAmount;

  // Helper for Quick Money Buttons
  Widget _buildQuickButton(double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _amountTendered = value;
            _controller.text = _amountTendered.toStringAsFixed(2);
          });
        },
        child: Text("${value.toInt()}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Encaissement (Espèces)", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Section: Total to Pay ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total à payer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    "${widget.totalAmount.toStringAsFixed(2)} DZD",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Input Section: Amount Received ---
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              autofocus: true, // Focus immediately so they can type
              decoration: const InputDecoration(
                labelText: "Montant Reçu (DZD)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              onChanged: _updateAmount,
            ),
            const SizedBox(height: 12),

            // --- Quick Buttons Row ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text("Rapide: ", style: TextStyle(color: Colors.grey)),
                  _buildQuickButton(widget.totalAmount), // Exact
                  if (widget.totalAmount < 500) _buildQuickButton(500),
                  if (widget.totalAmount < 1000) _buildQuickButton(1000),
                  if (widget.totalAmount < 2000) _buildQuickButton(2000),
                  if (widget.totalAmount < 5000) _buildQuickButton(5000),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Divider(),

            // --- Result Section: Change Due ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monnaie à rendre", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  Text(
                    "${_change >= 0 ? _change.toStringAsFixed(2) : '0.00'} DZD",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _isValid ? Colors.green : Colors.red
                    ),
                  ),
                ],
              ),
            ),
            if (!_isValid)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Le montant reçu est insuffisant.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Cancel
          child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.of(context).pop(true) : null, // Confirm only if valid
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text("Valider le Paiement", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}