// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:printing/printing.dart'; // Pour lister les imprimantes
import '../../../core/models/store_settings.dart';
import '../../../core/services/settings_service.dart';
import '../../../common/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<Printer>> _printersFuture;
  late Future<StoreSettings> _settingsFuture;

  // Controllers pour les champs de texte
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Valeur sélectionnée pour le dropdown
  String? _selectedPrinter;

  @override
  void initState() {
    super.initState();
    _printersFuture = Printing.listPrinters();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsFuture = SettingsService.instance.loadSettings();
    final settings = await _settingsFuture;

    // Pré-remplir les champs avec les valeurs sauvegardées
    _nomController.text = settings.nomMagasin;
    _adresseController.text = settings.adresseMagasin;
    _telephoneController.text = settings.telephoneMagasin;
    setState(() {
      _selectedPrinter = settings.imprimanteClient;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final settings = StoreSettings(
        nomMagasin: _nomController.text,
        adresseMagasin: _adresseController.text,
        telephoneMagasin: _telephoneController.text,
        imprimanteClient: _selectedPrinter,
      );

      await SettingsService.instance.saveSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Paramètres sauvegardés !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Paramètres",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<List<Printer>>(
                future: _printersFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final printers = snapshot.data!;

                  return Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        // Section 1: Informations Magasin
                        _buildSectionCard(
                          "Informations du Magasin",
                          Icons.store,
                          [
                            TextFormField(
                              controller: _nomController,
                              decoration: const InputDecoration(labelText: "Nom du Magasin"),
                              validator: (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _adresseController,
                              decoration: const InputDecoration(labelText: "Adresse"),
                              validator: (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telephoneController,
                              decoration: const InputDecoration(labelText: "Téléphone / NIF"),
                              validator: (v) => v!.isEmpty ? "Champ requis" : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section 2: Configuration Imprimantes
                        _buildSectionCard(
                          "Configuration des Imprimantes",
                          Icons.print,
                          [
                            DropdownButtonFormField<String?>(
                              value: _selectedPrinter,
                              decoration: const InputDecoration(
                                labelText: 'Imprimante Reçu Client (Caisse)',
                                helperText: 'Laissez vide pour utiliser celle par défaut.',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text("Utiliser l'imprimante par défaut")
                                ),
                                ...printers.map((p) => DropdownMenuItem<String?>(
                                  value: p.name,
                                  child: Text(p.name),
                                )).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPrinter = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Pour configurer les imprimantes cuisine (Pizza, Sandwich...), modifiez les catégories dans l'onglet 'Gestion des Produits'.",
                              style: TextStyle(color: AppTheme.textLight),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Bouton Sauvegarder
                        ElevatedButton.icon(
                          onPressed: _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text("Sauvegarder les Paramètres"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour un design de carte propre
  Widget _buildSectionCard(String titre, IconData icone, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppTheme.textDark),
              const SizedBox(width: 8),
              Text(
                titre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}