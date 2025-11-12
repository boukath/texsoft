// lib/core/services/image_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  // Singleton pattern
  ImageService._init();
  static final ImageService instance = ImageService._init();

  // Ouvre le sélecteur de fichier et retourne le fichier choisi
  Future<File?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      print('Erreur lors de la sélection du fichier: $e');
    }
    return null;
  }

  // Sauvegarde le fichier dans le dossier de l'application
  Future<String?> saveImage(File file, int productId, String? oldImagePath) async {
    try {
      // 1. Trouver le dossier de support de l'application
      final Directory appSupportDir = await getApplicationSupportDirectory();
      final String imagesDirPath = p.join(appSupportDir.path, 'images');
      final Directory imagesDir = Directory(imagesDirPath);

      // 2. Créer le sous-dossier 'images' s'il n'existe pas
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // 3. Créer un nom de fichier unique
      final String extension = p.extension(file.path);
      final String newFileName = 'product_${productId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final String newPath = p.join(imagesDirPath, newFileName);

      // 4. Copier le fichier
      await file.copy(newPath);

      // 5. Supprimer l'ancienne image si elle existe
      if (oldImagePath != null) {
        final File oldFile = File(oldImagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 6. Retourner le *nouveau* chemin complet
      return newPath;

    } catch (e) {
      print('Erreur lors de la sauvegarde de l\'image: $e');
      return null;
    }
  }

  // Supprime un fichier image du disque
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null) return;
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'image: $e');
    }
  }
}