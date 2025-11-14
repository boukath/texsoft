// lib/core/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_settings.dart';

class SettingsService {
  // Singleton
  SettingsService._init();
  static final SettingsService instance = SettingsService._init();

  static const _nomMagasinKey = 'nomMagasin';
  static const _adresseMagasinKey = 'adresseMagasin';
  static const _telephoneMagasinKey = 'telephoneMagasin';
  static const _imprimanteClientKey = 'imprimanteClient';

  // Sauvegarder les paramètres
  Future<void> saveSettings(StoreSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nomMagasinKey, settings.nomMagasin);
    await prefs.setString(_adresseMagasinKey, settings.adresseMagasin);
    await prefs.setString(_telephoneMagasinKey, settings.telephoneMagasin);

    if (settings.imprimanteClient != null) {
      await prefs.setString(_imprimanteClientKey, settings.imprimanteClient!);
    } else {
      await prefs.remove(_imprimanteClientKey);
    }
  }

  // Charger les paramètres
  Future<StoreSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return StoreSettings(
      nomMagasin: prefs.getString(_nomMagasinKey) ?? "Mon Magasin",
      adresseMagasin: prefs.getString(_adresseMagasinKey) ?? "Mon Adresse",
      telephoneMagasin: prefs.getString(_telephoneMagasinKey) ?? "0123 456 789",
      imprimanteClient: prefs.getString(_imprimanteClientKey),
    );
  }
}