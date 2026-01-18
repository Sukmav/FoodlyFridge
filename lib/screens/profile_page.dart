import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String? initialName;
  final VoidCallback? onProfileUpdated; // <-- TAMBAHKAN INI

  const ProfilePage({
    super.key,
    required this.userId,
    this.initialName,
    this.onProfileUpdated, // <-- TAMBAHKAN INI
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load username dari berbagai sumber
  Future<void> _loadUserName() async {
    try {
      // 1. Coba dari widget. initialName
      if (widget.initialName != null && widget.initialName!.isNotEmpty) {
        setState(() {
          _nameController.text = widget.initialName!;
        });
        return;
      }

      // 2. Coba dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('user_name_${widget.userId}');
      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          _nameController.text = savedName;
        });
        return;
      }

      // 3. Coba dari FirebaseAuth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null &&
          user.displayName != null &&
          user.displayName!.isNotEmpty) {
        setState(() {
          _nameController.text = user.displayName!;
        });
        return;
      }

      // 4. Default kosong
      setState(() {
        _nameController.text = '';
      });
    } catch (e) {
      if (kDebugMode) print('Error loading user name: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Nama tidak boleh kosong',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();

      if (kDebugMode) {
        print('========== SAVING PROFILE ==========');
        print('User ID: ${widget.userId}');
        print('New Name: $newName');
      }

      // 1. Update displayName di Firebase Auth (jika user login via Firebase)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(newName);
          await user.reload(); // Reload untuk memastikan perubahan tersimpan
          if (kDebugMode) print('✅ Firebase Auth displayName updated');
        } catch (e) {
          if (kDebugMode) print('⚠️ Failed updating firebase profile: $e');
        }
      }

      // 2. Simpan ke SharedPreferences untuk cache lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name_${widget.userId}', newName);
      if (kDebugMode) print('✅ Username saved to SharedPreferences');

      // 3. Tunda kecil untuk UX
      await Future.delayed(const Duration(milliseconds: 400));

      Fluttertoast.showToast(
        msg: 'Profil berhasil disimpan',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );

      // 4. Kembalikan data yang baru ke pemanggil (sidebar/beranda)
      final result = {'name': newName, 'success': true};

      if (kDebugMode) {
        print('✅ Returning result to caller');
        print('========== SAVE COMPLETED ==========');
      }

      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (kDebugMode) {
        print('========== ERROR SAVING PROFILE ==========');
        print('Error: $e');
      }
      Fluttertoast.showToast(
        msg: 'Gagal menyimpan profil:  $e',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      if (mounted) Navigator.of(context).pop(null);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF7A9B3B);
    final Color primary = const Color(0xFF7C4585);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ubah nama Anda yang akan ditampilkan di aplikasi',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Icon (Static - tidak bisa diubah)
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, accent],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Nama Field
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Informasi Pengguna',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Nama',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama Anda',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.edit_outlined,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber[700],
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nama ini akan ditampilkan di Beranda dan Sidebar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary, accent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _saveProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.save_alt,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Simpan Perubahan',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
