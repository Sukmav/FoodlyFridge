import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String? initialName;

  const ProfilePage({
    super.key,
    required this.userId,
    this.initialName,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _imageFile;
  String? _imageBase64;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
        final bytes = await _imageFile!.readAsBytes();
        _imageBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (kDebugMode) print('Camera pick error: $e');
      Fluttertoast.showToast(msg: 'Gagal mengambil foto: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
        final bytes = await _imageFile!.readAsBytes();
        _imageBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (kDebugMode) print('Gallery pick error: $e');
      Fluttertoast.showToast(msg: 'Gagal memilih gambar: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Nama tidak boleh kosong', backgroundColor: Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Tidak mengubah logika existing — di sini hanya menampilkan toast.
      // Tempat untuk memanggil API update profil jika diperlukan.
      await Future.delayed(const Duration(milliseconds: 400));
      Fluttertoast.showToast(msg: 'Profil berhasil disimpan', backgroundColor: Colors.green);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Gagal menyimpan profil: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatar() {
    final avatar = _imageFile != null
        ? ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover),
    )
        : Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: const Icon(Icons.person, size: 72, color: Colors.grey),
    );

    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF7A9B3B);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top area: avatar left, name field right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + buttons column
                  Column(
                    children: [
                      _buildAvatar(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _pickFromCamera,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Kamera', style: GoogleFonts.poppins(color: accent)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _pickFromGallery,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Galeri', style: GoogleFonts.poppins(color: accent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Name field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nama', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Nama',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // (optional) additional profile fields can go here without changing existing logic
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Text('Simpan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}