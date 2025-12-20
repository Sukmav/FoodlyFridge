import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../helpers/image_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/kedai.dart';
import '../helpers/kedai_service.dart';

class KedaiPage extends StatefulWidget {
  final String userId;

  const KedaiPage({super.key, required this.userId});

  @override
  State<KedaiPage> createState() => _KedaiPageState();
}

class _KedaiPageState extends State<KedaiPage> {
  final TextEditingController _namaKedaiController = TextEditingController();
  final TextEditingController _alamatKedaiController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();
  final TextEditingController _catatanStrukController = TextEditingController();

  final KedaiService _kedaiService = KedaiService();
  bool _isLoading = false;
  bool _isSaving = false;

  File? _selectedImage;
  String? _selectedImagePath;
  String? _savedImagePath; // Path gambar yang disimpan

  @override
  void initState() {
    super.initState();
    _loadExistingKedaiData();
  }

  // Load existing kedai data if available
  Future<void> _loadExistingKedaiData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);
      if (kedai != null && mounted) {
        setState(() {
          _namaKedaiController.text = kedai.nama_kedai;
          _alamatKedaiController.text = kedai.alamat_kedai;
          _nomorTeleponController.text = kedai. nomor_telepon;
          _catatanStrukController. text = kedai.catatan_struk;
          // Load gambar jika ada
          if (kedai.logo_kedai. isNotEmpty) {
            _savedImagePath = kedai.logo_kedai;
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading kedai data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        : await ImageHelper. pickImageFromGallery();

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
  Future<String? > _saveImageLocally(File imageFile) async {
    try {
      // Dapatkan directory untuk menyimpan gambar
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imageDir = path.join(appDir.path, 'kedai_images');

      // Buat folder jika belum ada
      final Directory imageDirFolder = Directory(imageDir);
      if (!await imageDirFolder.exists()) {
        await imageDirFolder. create(recursive: true);
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
  Future<String? > _convertImageToBase64(File imageFile) async {
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
      backgroundColor: Colors. blue,
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

    setState(() {
      _isSaving = true;
    });

    try {
      if (kDebugMode) {
        print('========== KEDAI PAGE: PREPARING TO SAVE ==========');
        print('User ID: ${widget.userId}');
        print('Nama Kedai: ${_namaKedaiController.text}');
        print('Alamat: ${_alamatKedaiController.text}');
        print('Nomor Telepon: ${_nomorTeleponController.text}');
        print('Catatan Struk: ${_catatanStrukController.text}');
      }

      String logoKedai = '';

      // Jika ada gambar yang dipilih, simpan gambar
      if (_selectedImage != null) {
        if (kDebugMode) {
          print('Processing selected image...');
        }

        // Convert gambar ke base64 untuk database
        final imageBase64 = await _convertImageToBase64(_selectedImage!);

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          logoKedai = imageBase64;

          if (kDebugMode) {
            print('✅ Image converted to base64, length: ${logoKedai.length}');
          }

          // Simpan gambar ke folder lokal untuk backup
          final imagePath = await _saveImageLocally(_selectedImage!);
          if (imagePath != null) {
            _savedImagePath = imagePath;
            if (kDebugMode) {
              print('✅ Image also saved locally at: $imagePath');
            }
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Failed to convert image to base64');
          }
        }
      } else if (_savedImagePath != null && _savedImagePath!.isNotEmpty) {
        // Jika tidak ada gambar baru dipilih tapi ada gambar lama
        if (kDebugMode) {
          print('Using existing logo from previous save');
        }

        // Jika _savedImagePath adalah path lokal, convert ke base64
        if (_savedImagePath!.startsWith('/') || _savedImagePath!.contains('\\')) {
          try {
            final existingFile = File(_savedImagePath!);
            if (await existingFile.exists()) {
              final existingBase64 = await _convertImageToBase64(existingFile);
              logoKedai = existingBase64 ?? '';
              if (kDebugMode) {
                print('✅ Converted existing image to base64, length: ${logoKedai.length}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error converting existing image: $e');
            }
          }
        } else {
          // Sudah dalam format base64
          logoKedai = _savedImagePath!;
          if (kDebugMode) {
            print('Using existing base64 logo, length: ${logoKedai.length}');
          }
        }
      } else {
        if (kDebugMode) {
          print('No image selected');
        }
      }

      // Buat objek KedaiModel
      final kedaiModel = KedaiModel(
        id: '', // ID akan di-set oleh GoCloud
        logo_kedai: logoKedai,
        nama_kedai: _namaKedaiController.text.trim(),
        alamat_kedai: _alamatKedaiController.text.trim(),
        nomor_telepon: _nomorTeleponController.text.trim(),
        catatan_struk: _catatanStrukController.text.trim(),
      );

      if (kDebugMode) {
        print('KedaiModel created with logo length: ${logoKedai.length}');
        print('Calling saveKedai...');
      }

      // Simpan ke GoCloud
      final docId = await _kedaiService.saveKedai(kedaiModel, widget.userId);

      if (kDebugMode) {
        print('SaveKedai completed with document ID: $docId');
      }

      // ✅ PERBAIKAN: Simpan SEMUA data kedai ke SharedPreferences dengan user_id sebagai key
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nama_kedai_${widget.userId}', _namaKedaiController.text.trim());
      await prefs.setString('alamat_kedai_${widget.userId}', _alamatKedaiController.text.trim());
      await prefs.setString('nomor_telepon_${widget.userId}', _nomorTeleponController.text.trim());
      await prefs.setString('catatan_struk_${widget.userId}', _catatanStrukController.text.trim());
      await prefs.setString('logo_kedai_${widget.userId}', logoKedai);
      await prefs.setBool('has_kedai_${widget.userId}', true);
      if (docId != null) {
        await prefs.setString('kedai_id_${widget.userId}', docId);
      }

      if (kDebugMode) {
        print('✅ ALL kedai data saved to SharedPreferences cache');
        print('Data saved with key prefix: ${widget.userId}');
        print('========== SAVE COMPLETED SUCCESSFULLY ==========');
      }

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Data Kedai berhasil disimpan!",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );

        // Tunggu sebentar agar toast muncul, lalu navigasi kembali ke HomePage
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true); // Return true untuk indicate success
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('========== ERROR IN KEDAI PAGE ==========');
        print('Error: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Gagal menyimpan data kedai: ${e.toString()}",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildLogoKedai() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape. circle,
        border: Border.all(
          color: const Color(0xFF000000),
          width: 2,
        ),
      ),
      child: ClipOval(
        child:  _buildLogoContent(),
      ),
    );
  }

  Widget _buildLogoContent() {
    // Prioritas 1: Gambar yang baru dipilih
    if (_selectedImage != null && ! kIsWeb) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    }

    // Prioritas 2: Gambar dari web
    if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty && kIsWeb) {
      return Image.network(
        _selectedImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildLogoPlaceholder();
        },
      );
    }

    // Prioritas 3: Gambar yang sudah tersimpan (base64 atau path)
    if (_savedImagePath != null && _savedImagePath!. isNotEmpty) {
      // Cek apakah base64 atau path
      if (_savedImagePath!. startsWith('data:image') ||
          (_savedImagePath!.length > 100 && ! _savedImagePath!.contains('/'))) {
        // Ini adalah base64 string
        try {
          // Hapus prefix jika ada
          String base64String = _savedImagePath! ;
          if (base64String. contains(',')) {
            base64String = base64String.split(',').last;
          }

          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (kDebugMode) {
                print('Error decoding base64 image: $error');
              }
              return _buildLogoPlaceholder();
            },
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error displaying base64 image: $e');
          }
          return _buildLogoPlaceholder();
        }
      } else {
        // Ini adalah file path
        final file = File(_savedImagePath!);
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              print('Error loading image from path: $error');
            }
            return _buildLogoPlaceholder();
          },
        );
      }
    }

    // Default:  Placeholder
    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Logo Kedai',
            style:  GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5B7FBD),
            ),
          ),
          const SizedBox(height:  8),
          Text(
            'pastikan background\nberwarna putih',
            textAlign: TextAlign.center,
            style: GoogleFonts. poppins(
              fontSize:  10,
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
        style:  OutlinedButton.styleFrom(
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
    TextInputType?  keyboardType,
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
                color: Colors.grey. shade400,
              ),
              border:  InputBorder.none,
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
          icon:  const Icon(Icons.arrow_back, color: Color(0xFF5B7FBD)),
          onPressed: (_isLoading || _isSaving) ? null : () => Navigator.pop(context),
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
      body: _isLoading
          ? const Center(
        child:  CircularProgressIndicator(),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            child:  Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
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
                              hint:  'nama kedaimu',
                            ),
                            const SizedBox(height:  40),
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
                    controller:  _nomorTeleponController,
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
                    maxLines:  5,
                  ),
                  const SizedBox(height: 20),

                  // Lihat Struk Button and Info Text
                  Row(
                    children: [
                      SizedBox(
                        width:  155,
                        height: 45,
                        child: OutlinedButton(
                          onPressed: _lihatStruk,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFA5D6A7),
                              width: 2,
                            ),
                            shape:  RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Lihat Struk',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:  FontWeight.w500,
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
                    width:  double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _simpanKedai,
                      style:  ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DAF52),
                        disabledBackgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:  CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Simpan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight:  FontWeight.w600,
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
          if (_isSaving)
            Container(
              color: Colors. black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

