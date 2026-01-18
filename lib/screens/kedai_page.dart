import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/kedai.dart';
import '../helpers/kedai_service.dart';
import '../theme/app_colors.dart';
import '../screens/struk_preview_page.dart';

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
  String? _logoBase64; // UBAH:  Gunakan base64 langsung

  @override
  void initState() {
    super.initState();
    _loadExistingKedaiData();
  }

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
          _nomorTeleponController.text = kedai.nomor_telepon;
          _catatanStrukController.text = kedai.catatan_struk;
          if (kedai.logo_kedai.isNotEmpty) {
            _logoBase64 = kedai.logo_kedai;
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

  // PERBAIKAN: Method untuk pick image dari kamera
  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();

        setState(() {
          _selectedImage = imageFile;
          _logoBase64 = base64Encode(bytes);
        });

        Fluttertoast.showToast(
          msg: "Foto berhasil diambil",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error mengambil foto: $e');
      }
      Fluttertoast.showToast(
        msg: "Gagal mengambil foto:  $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // PERBAIKAN: Method untuk pick image dari galeri
  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();

        setState(() {
          _selectedImage = imageFile;
          _logoBase64 = base64Encode(bytes);
        });

        Fluttertoast.showToast(
          msg: "Foto berhasil dipilih",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error memilih gambar: $e');
      }
      Fluttertoast.showToast(
        msg: "Gagal memilih gambar: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _lihatStruk() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StrukPreviewPage(userId: widget.userId),
      ),
    );
  }

  Future<void> _simpanKedai() async {
    if (_namaKedaiController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama Kedai harus diisi! ",
        backgroundColor: AppColors.danger,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (kDebugMode) {
        print('========== KEDAI PAGE:  PREPARING TO SAVE ==========');
        print('User ID: ${widget.userId}');
        print('Nama Kedai: ${_namaKedaiController.text}');
        print('Logo Base64 Length: ${_logoBase64?.length ?? 0}');
      }

      // Gunakan logo base64 yang sudah ada
      String logoKedai = _logoBase64 ?? '';

      final kedaiModel = KedaiModel(
        id: '',
        logo_kedai: logoKedai,
        nama_kedai: _namaKedaiController.text.trim(),
        alamat_kedai: _alamatKedaiController.text.trim(),
        nomor_telepon: _nomorTeleponController.text.trim(),
        catatan_struk: _catatanStrukController.text.trim(),
      );

      if (kDebugMode) {
        print('KedaiModel created with logo length: ${logoKedai.length}');
        print('Calling saveKedai.. .');
      }

      final docId = await _kedaiService.saveKedai(kedaiModel, widget.userId);

      if (kDebugMode) {
        print('SaveKedai completed with document ID: $docId');
      }

      // Simpan ke SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'nama_kedai_${widget.userId}',
        _namaKedaiController.text.trim(),
      );
      await prefs.setString(
        'alamat_kedai_${widget.userId}',
        _alamatKedaiController.text.trim(),
      );
      await prefs.setString(
        'nomor_telepon_${widget.userId}',
        _nomorTeleponController.text.trim(),
      );
      await prefs.setString(
        'catatan_struk_${widget.userId}',
        _catatanStrukController.text.trim(),
      );
      await prefs.setString('logo_kedai_${widget.userId}', logoKedai);
      await prefs.setBool('has_kedai_${widget.userId}', true);
      if (docId != null) {
        await prefs.setString('kedai_id_${widget.userId}', docId);
      }

      if (kDebugMode) {
        print('✅ ALL kedai data saved to SharedPreferences cache');
        print('========== SAVE COMPLETED SUCCESSFULLY ==========');
      }

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Data Kedai berhasil disimpan! ",
          backgroundColor: AppColors.success,
          toastLength: Toast.LENGTH_SHORT,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('========== ERROR IN KEDAI PAGE ==========');
        print('Error:  $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Gagal menyimpan data kedai:  ${e.toString()}",
          backgroundColor: AppColors.danger,
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

  // PERBAIKAN: Widget untuk menampilkan logo
  Widget _buildLogoKedai() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: _buildLogoContent()),
    );
  }

  // PERBAIKAN: Method untuk menampilkan konten logo
  Widget _buildLogoContent() {
    // Jika ada gambar yang baru dipilih (belum disimpan)
    if (_selectedImage != null && !kIsWeb) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Error loading selected image: $error');
          }
          return _buildLogoPlaceholder();
        },
      );
    }

    // Jika ada logo base64 (sudah disimpan atau baru dipilih)
    if (_logoBase64 != null && _logoBase64!.isNotEmpty) {
      try {
        // Handle base64 dengan atau tanpa prefix
        String base64String = _logoBase64!;
        if (base64String.contains(',')) {
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
    }

    // Default placeholder
    return _buildLogoPlaceholder();
  }

  Widget _buildLogoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storefront_rounded,
            size: 50,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'Logo Kedai',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(
      String label,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppColors.primary, width: 1.5),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDisabled,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary)
                  : null,
              filled: true,
              fillColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: (_isLoading || _isSaving)
              ? null
              : () => Navigator.pop(context),
        ),
        title: Text(
          'Kedaimu',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Memuat data kedai...',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Lengkapi informasi kedai Anda untuk pengalaman yang lebih baik',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logo & Identitas Kedai
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo & Identitas Kedai',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Logo Section - Di Tengah
                          Center(
                            child: Column(
                              children: [
                                _buildLogoKedai(),
                                const SizedBox(height: 20),
                                Text(
                                  'Logo Kedai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ukuran optimal:  400x400px',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Upload Buttons - Horizontal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildImageButton(
                                  'Kamera',
                                  Icons.camera_alt,
                                  _pickImageFromCamera, // UBAH:  Gunakan method baru
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildImageButton(
                                  'Galeri',
                                  Icons.photo_library,
                                  _pickImageFromGallery, // UBAH: Gunakan method baru
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Nama dan Alamat Section
                          Column(
                            children: [
                              _buildTextField(
                                controller: _namaKedaiController,
                                label: 'Nama Kedai',
                                hint: 'Contoh: Kedai Makan Padang',
                                prefixIcon: Icons.storefront,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _alamatKedaiController,
                                label: 'Alamat Kedai',
                                hint: 'Jl. Contoh No. 123, Kota',
                                prefixIcon: Icons.location_on,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contact Information Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Kontak',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _nomorTeleponController,
                            label: 'Nomor Telepon',
                            hint: '081234xxxxx',
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Catatan Struk Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Struk',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pesan ini akan muncul di bagian bawah struk pembelian',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _catatanStrukController,
                            label: '',
                            hint:
                            'Contoh: Terima kasih sudah memesan, silakan ditunggu',
                            prefixIcon: Icons.note,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _lihatStruk,
                              icon: const Icon(
                                Icons.preview,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Lihat Pratinjau Struk',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isSaving ? null : _simpanKedai,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save_alt,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Simpan Data Kedai',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Menyimpan data...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
