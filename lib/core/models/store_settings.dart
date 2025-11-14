// lib/core/models/store_settings.dart

class StoreSettings {
  final String nomMagasin;
  final String adresseMagasin;
  final String telephoneMagasin;
  final String? imprimanteClient; // Nom de l'imprimante pour les reçus

  StoreSettings({
    this.nomMagasin = "Mon Magasin", // Défaut
    this.adresseMagasin = "Mon Adresse", // Défaut
    this.telephoneMagasin = "0123 456 789", // Défaut
    this.imprimanteClient,
  });

  // Convertit notre objet en Map pour le sauvegarder
  Map<String, String?> toMap() {
    return {
      'nomMagasin': nomMagasin,
      'adresseMagasin': adresseMagasin,
      'telephoneMagasin': telephoneMagasin,
      'imprimanteClient': imprimanteClient,
    };
  }

  // Crée notre objet à partir d'une Map (chargée depuis le disque)
  factory StoreSettings.fromMap(Map<String, dynamic> map) {
    return StoreSettings(
      nomMagasin: map['nomMagasin'] ?? "Mon Magasin",
      adresseMagasin: map['adresseMagasin'] ?? "Mon Adresse",
      telephoneMagasin: map['telephoneMagasin'] ?? "0123 456 789",
      imprimanteClient: map['imprimanteClient'],
    );
  }
}