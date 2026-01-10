import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class UbahKataSandiPage extends StatefulWidget {
  final String userId;

  const UbahKataSandiPage({super.key, required this.userId});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSaving = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _oldController. dispose();
    _newController. dispose();
    _confirmController. dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String?  _validateInputs() {
    final old = _oldController.text. trim();
    final neu = _newController.text.trim();
    final conf = _confirmController.text.trim();

    if (old.isEmpty) return 'Kata sandi lama harus diisi';
    if (neu.isEmpty) return 'Kata sandi baru harus diisi';
    if (neu. length < 6) return 'Kata sandi baru minimal 6 karakter';
    if (conf.isEmpty) return 'Konfirmasi kata sandi harus diisi';
    if (neu != conf) return 'Konfirmasi kata sandi tidak cocok';
    if (neu == old) return 'Kata sandi baru harus berbeda dari kata sandi lama';
    return null;
  }

  Future<void> _changePassword() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (kDebugMode) {
        print('========== UBAH KATA SANDI ==========');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan, silakan login kembali');
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('Email pengguna tidak tersedia');
      }

      if (kDebugMode) {
        print('User Email: $email');
      }

      // STRATEGI BARU: Sign out dulu, lalu sign in dengan password lama untuk verify
      if (kDebugMode) {
        print('Step 1: Verifying password.. .');
      }

      // Simpan data user dulu
      final userUid = user.uid;

      // Sign out
      await _auth.signOut();

      // Sign in kembali dengan password lama untuk verify
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: _oldController.text.trim(),
        );

        if (kDebugMode) {
          print('✅ Password verification successful');
        }
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print('❌ Verification failed: ${e.code}');
        }

        // Sign in failed = password salah
        throw FirebaseAuthException(
          code:  'wrong-password',
          message: 'Kata sandi lama yang Anda masukkan salah',
        );
      }

      // Update password
      if (kDebugMode) {
        print('Step 2: Updating password...');
      }

      await userCredential.user! .updatePassword(_newController.text.trim());

      if (kDebugMode) {
        print('✅ Password updated successfully');
      }

      // Update Firestore
      if (kDebugMode) {
        print('Step 3: Updating Firestore...');
      }

      try {
        await _firestore. collection('user').doc(userUid).set({
          'password_updated_at': FieldValue.serverTimestamp(),
          'email': email,
          'uid': userUid,
          'last_password_change': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        if (kDebugMode) {
          print('✅ Firestore updated');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Firestore update failed (but password changed): $e');
        }
      }

      // Clear cache
      try {
        final prefs = await SharedPreferences. getInstance();
        await prefs. remove('user_name_${widget.userId}');
        await prefs.remove('navigate_to_beranda');
        await prefs. remove('navigate_to_beranda_after_profile');

        if (kDebugMode) {
          print('✅ Cache cleared');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cache clear failed: $e');
        }
      }

      // Sign out final
      await _auth.signOut();

      if (kDebugMode) {
        print('✅ Signed out');
        print('========== SUCCESS ==========');
      }

      // Show success
      if (mounted) {
        _showMessage('Kata sandi berhasil diubah! ');

        await Future.delayed(const Duration(milliseconds: 800));

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:  BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 70,
                      color: Colors. green[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Berhasil! ',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors. black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    'Kata sandi Anda telah berhasil diubah',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors. grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Silakan login kembali dengan kata sandi baru Anda',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors. blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // OK Button
                  SizedBox(
                    width:  double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7A9B3B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'OK, Mengerti',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );

        // Navigate to login
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
          );

          if (kDebugMode) {
            print('✅ Navigated to LoginPage');
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('========== FIREBASE AUTH ERROR ==========');
        print('Error Code: ${e.code}');
        print('Error Message: ${e.message}');
      }

      String msg = 'Gagal mengubah kata sandi';

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          msg = 'Kata sandi lama yang Anda masukkan salah';
          break;
        case 'weak-password':
          msg = 'Kata sandi baru terlalu lemah (minimal 6 karakter)';
          break;
        case 'user-not-found':
          msg = 'User tidak ditemukan';
          break;
        case 'user-disabled':
          msg = 'Akun telah dinonaktifkan';
          break;
        case 'too-many-requests':
          msg = 'Terlalu banyak percobaan.  Coba lagi dalam beberapa menit';
          break;
        case 'network-request-failed':
          msg = 'Koneksi internet bermasalah. Periksa jaringan Anda';
          break;
        default:
          msg = e.message ?? msg;
      }

      _showMessage(msg, isError:  true);
    } catch (e) {
      if (kDebugMode) {
        print('========== GENERAL ERROR ==========');
        print('Error: $e');
      }

      _showMessage('Terjadi kesalahan:  ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey. shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts. poppins(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border:  InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF7A9B3B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return ! _isSaving;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Ubah Kata Sandi',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF7A9B3B)),
          leading: IconButton(
            icon:  Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7A9B3B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:  const Icon(
                Icons.arrow_back,
                color: Color(0xFF7A9B3B),
              ),
            ),
            onPressed: _isSaving ? null : () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding:  const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A9B3B).withOpacity(0.1),
                  borderRadius: BorderRadius. circular(12),
                  border: Border.all(
                    color: const Color(0xFF7A9B3B).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF7A9B3B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kata sandi baru minimal 6 karakter dan harus berbeda dari kata sandi lama',
                        style: GoogleFonts. poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kata Sandi Lama
              Text(
                'Kata Sandi Lama',
                style: GoogleFonts.poppins(
                  fontSize:  14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _oldController,
                hint: 'Masukkan kata sandi lama',
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 20),

              // Kata Sandi Baru
              Text(
                'Kata Sandi Baru',
                style:  GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _newController,
                hint: 'Masukkan kata sandi baru (min.  6 karakter)',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),

              // Konfirmasi Kata Sandi Baru
              Text(
                'Konfirmasi Kata Sandi Baru',
                style: GoogleFonts.poppins(
                  fontSize:  14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height:  8),
              _buildPasswordField(
                controller: _confirmController,
                hint: 'Masukkan ulang kata sandi baru',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 32),

              // Security Tips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors. blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border. all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.blue[700],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tips:  Gunakan kombinasi huruf besar, huruf kecil, angka, dan simbol untuk kata sandi yang lebih aman',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors. blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child:  Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7A9B3B), Color(0xFF5D7A2C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7A9B3B).withOpacity(0.3),
                    blurRadius:  10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSaving ? null : _changePassword,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 55,
                    alignment: Alignment.center,
                    child: _isSaving
                        ?  Row(
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Memproses...',
                          style: GoogleFonts.poppins(
                            fontSize:  14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment:  MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}