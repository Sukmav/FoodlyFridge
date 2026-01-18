//lib/helpers/image_helper.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Method untuk menampilkan dialog pilihan sumber gambar
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickImageFromCamera();
                if (context.mounted) {
                  Navigator.pop(context, file);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                final file = await pickImageFromGallery();
                if (context.mounted) {
                  Navigator.pop(context, file);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk mengambil gambar dari kamera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from camera: $e');
      }
      return null;
    }
  }

  // Method untuk mengambil gambar dari galeri
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image from gallery: $e');
      }
      return null;
    }
  }

  // Method untuk menyimpan gambar ke folder assets lokal
  static Future<String?> saveImageToAssets(File imageFile, String fileName) async {
    try {
      // Dapatkan directory untuk menyimpan gambar
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = path.join(appDir.path, 'bahan_baku_images');

      // Buat folder jika belum ada
      final Directory imageDirFolder = Directory(imageDir);
      if (!await imageDirFolder.exists()) {
        await imageDirFolder.create(recursive: true);
      }

      // Generate nama file unik dengan timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '${fileName}_$timestamp${path.extension(imageFile.path)}';
      final String newPath = path.join(imageDir, newFileName);

      // Copy file ke lokasi baru
      final File newImage = await imageFile.copy(newPath);

      if (kDebugMode) {
        print('✓ Gambar disimpan di: ${newImage.path}');
      }

      return newImage.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image to assets: $e');
      }
      return null;
    }
  }

  // Method untuk convert gambar ke base64
  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      // Tambahkan prefix data URI untuk gambar
      final extension = path.extension(imageFile.path).toLowerCase();
      String mimeType = 'image/jpeg';

      if (extension == '.png') {
        mimeType = 'image/png';
      } else if (extension == '.jpg' || extension == '.jpeg') {
        mimeType = 'image/jpeg';
      } else if (extension == '.gif') {
        mimeType = 'image/gif';
      }

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      if (kDebugMode) {
        print('Error converting image to base64: $e');
      }
      return null;
    }
  }

  // Method untuk upload gambar ke GoCloud
  static Future<String?> uploadImageToGoCloud({
    required File imageFile,
    required String token,
    required String project,
    required String fileName,
  }) async {
    try {
      if (kDebugMode) {
        print('=== UPLOAD TO GOCLOUD ===');
        print('File: ${imageFile.path}');
        print('FileName: $fileName');
      }

      // Endpoint API GoCloud untuk upload file
      final uri = Uri.parse('https://gocloud.my.id/api/upload');

      // Buat multipart request
      final request = http.MultipartRequest('POST', uri);

      // Tambahkan headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'X-Project': project,
      });

      // Tambahkan file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName,
      );

      request.files.add(multipartFile);

      // Kirim request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Sesuaikan dengan struktur response API GoCloud
        if (jsonResponse['status'] == 'success' || jsonResponse['status'] == 1) {
          final imageUrl = jsonResponse['url'] ?? jsonResponse['data']?['url'];

          if (imageUrl != null && imageUrl.isNotEmpty) {
            if (kDebugMode) {
              print('✓ Upload berhasil: $imageUrl');
            }
            return imageUrl;
          }
        }
      }

      if (kDebugMode) {
        print('✗ Upload gagal atau response tidak valid');
      }
      return null;

    } catch (e) {
      if (kDebugMode) {
        print('Error uploading to GoCloud: $e');
      }
      return null;
    }
  }
}
