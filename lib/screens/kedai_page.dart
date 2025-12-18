import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../helpers/image_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class KedaiPage extends StatefulWidget {
  const KedaiPage({super.key});

  @override
  State<KedaiPage> createState() => _KedaiPageState();
}

class _KedaiPageState extends State<KedaiPage> {
  final TextEditingController _namaKedaiController = TextEditingController();
  final TextEditingController _alamatKedaiController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();
  final TextEditingController _catatanStrukController = TextEditingController();

  File? _selectedImage;
  String? _selectedImagePath;
  String? _savedImagePath; // Path gambar yang disimpan

  @override
  void dispose() {
    _namaKedaiController.dispose();
    _alamatKedaiController.dispose();
    _nomorTeleponController.dispose();
    _catatanStrukController.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar(bool dariKamera) async {
    final imageFile = dariKamera
        ? await ImageHelper.pickImageFromCamera()
        : await ImageHelper.pickImageFromGallery();

    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        if (kIsWeb) {
          _selectedImagePath = imageFile.path;
        }
      });
    }
  }

  // Method untuk menyimpan gambar ke folder lokal
  Future<String?> _saveImageLocally(File imageFile) async {
    try {
      // Dapatkan directory untuk menyimpan gambar
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = path.join(appDir.path, 'kedai_images');

      // Buat folder jika belum ada
      final Directory imageDirFolder = Directory(imageDir);
      if (!await imageDirFolder.exists()) {
        await imageDirFolder.create(recursive: true);
      }

      // Generate nama file unik dengan timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'logo_kedai_$timestamp${path.extension(imageFile.path)}';
      final String newPath = path.join(imageDir, fileName);

      // Copy file ke lokasi baru
      final File newImage = await imageFile.copy(newPath);

      return newImage.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image: $e');
      }
      return null;
    }
  }

  // Method untuk convert gambar ke base64 untuk database
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('Error converting image to base64: $e');
      }
      return null;
    }
  }

  void _lihatStruk() {
    // TODO: Implement lihat struk functionality
    Fluttertoast.showToast(
      msg: "Fitur Lihat Struk akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  Future<void> _simpanKedai() async {
    if (_namaKedaiController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama Kedai harus diisi!",
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      String? imagePath;
      String? imageBase64;

      // Jika ada gambar yang dipilih, simpan gambar
      if (_selectedImage != null) {
        // Simpan gambar ke folder lokal
        imagePath = await _saveImageLocally(_selectedImage!);

        // Convert gambar ke base64 untuk database
        imageBase64 = await _convertImageToBase64(_selectedImage!);

        if (imagePath != null) {
          setState(() {
            _savedImagePath = imagePath;
          });
        }
      }

      // TODO: Simpan data ke database
      // Contoh data yang akan disimpan:
      final Map<String, dynamic> kedaiData = {
        'nama_kedai': _namaKedaiController.text,
        'alamat_kedai': _alamatKedaiController.text,
        'nomor_telepon': _nomorTeleponController.text,
        'catatan_struk': _catatanStrukController.text,
        'logo_path': imagePath ?? '',
        'logo_base64': imageBase64 ?? '',
      };

      if (kDebugMode) {
        print('Data Kedai: $kedaiData');
      }

      Fluttertoast.showToast(
        msg: "Data Kedai berhasil disimpan!",
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving kedai: $e');
      }
      Fluttertoast.showToast(
        msg: "Gagal menyimpan data kedai!",
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildLogoKedai() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF000000),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: _selectedImage != null && !kIsWeb
            ? Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
        )
            : _selectedImagePath != null && _selectedImagePath!.isNotEmpty
            ? Image.network(
          _selectedImagePath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildLogoPlaceholder();
          },
        )
            : _savedImagePath != null && _savedImagePath!.isNotEmpty
            ? Image.file(
          File(_savedImagePath!),
          fit: BoxFit.cover,
        )
            : _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Logo Kedai',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5B7FBD),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'pastikan background\nberwarna putih',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFFC4A853),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: 155,
      height: 45,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFA5D6A7),
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFA5D6A7),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5B7FBD)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kedaimu',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5B7FBD),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and Form Section - Horizontal Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Side - Logo and Buttons
                  Column(
                    children: [
                      _buildLogoKedai(),
                      const SizedBox(height: 12),
                      _buildImageButton('Kamera', () => _pilihGambar(true)),
                      const SizedBox(height: 8),
                      _buildImageButton('Galeri', () => _pilihGambar(false)),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // Right Side - Form Fields
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _namaKedaiController,
                          label: 'Nama Kedai',
                          hint: 'nama kedaimu',
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          controller: _alamatKedaiController,
                          label: 'Alamat Kedai',
                          hint: 'alamat lengkap kedaimu',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Nomor Telepon - Full Width
              _buildTextField(
                controller: _nomorTeleponController,
                label: 'Nomor Telepon',
                hint: '081234xxxxx',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),

              // Catatan Struk - Full Width
              _buildTextField(
                controller: _catatanStrukController,
                label: 'Catatan Struk',
                hint: 'Terima kasih sudah memesan, silakan ditunggu',
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Lihat Struk Button and Info Text
              Row(
                children: [
                  SizedBox(
                    width: 155,
                    height: 45,
                    child: OutlinedButton(
                      onPressed: _lihatStruk,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFA5D6A7),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Lihat Struk',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA5D6A7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              const SizedBox(height: 40),

              // Simpan Button - Full Width
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _simpanKedai,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DAF52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Simpan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
