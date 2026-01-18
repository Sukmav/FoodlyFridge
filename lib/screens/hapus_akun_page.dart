import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'login_page.dart';

class HapusAkunPage extends StatefulWidget {
  const HapusAkunPage({Key? key}) : super(key: key);

  @override
  State<HapusAkunPage> createState() => _HapusAkunPageState();
}

class _HapusAkunPageState extends State<HapusAkunPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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

  Future<void> _handleDelete() async {
    if (_isProcessing) return;
    if (!_formKey.currentState!.validate()) return;

    // Show first confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Peringatan! ',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Akun Anda akan dihapus secara permanen dan tidak dapat dikembalikan.\n\nSemua data akan terhapus.\n\nApakah Anda yakin? ',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Ya, Hapus',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return;

    setState(() => _isProcessing = true);

    try {
      if (kDebugMode) {
        print('========== HAPUS AKUN ==========');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User tidak ditemukan');
      }

      final email = user.email!;
      final uid = user.uid;
      final password = _passwordController.text.trim();

      if (kDebugMode) {
        print('User Email: $email');
        print('User UID: $uid');
      }

      // STRATEGI:  Sign out → Sign in kembali untuk verify password
      if (kDebugMode) {
        print('Step 1: Verifying password...');
      }

      // Sign out
      await FirebaseAuth.instance.signOut();

      // Sign in kembali dengan password untuk verify
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (kDebugMode) {
          print('✅ Password verified');
        }
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) {
          print('❌ Password verification failed: ${e.code}');
        }

        String msg = 'Kata sandi salah';
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'INVALID_LOGIN_CREDENTIALS') {
          msg = 'Kata sandi yang Anda masukkan salah';
        } else if (e.code == 'user-not-found') {
          msg = 'Akun tidak ditemukan';
        } else if (e.code == 'network-request-failed') {
          msg = 'Koneksi internet bermasalah';
        }

        throw FirebaseAuthException(code: e.code, message: msg);
      }

      // Show second confirmation
      if (mounted) {
        final secondConfirm = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konfirmasi Terakhir',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ini adalah langkah terakhir! ',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWarningItem('Semua data Anda akan dihapus'),
                      _buildWarningItem('Akun tidak dapat dikembalikan'),
                      _buildWarningItem(
                        'Anda harus daftar ulang jika ingin kembali',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apakah Anda benar-benar yakin?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batalkan',
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Hapus Permanen',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );

        if (secondConfirm != true) {
          // User cancelled, sign out and go back
          await FirebaseAuth.instance.signOut();
          setState(() => _isProcessing = false);
          return;
        }
      }

      // Delete Firestore data
      if (kDebugMode) {
        print('Step 2: Deleting Firestore data...');
      }

      try {
        await _deleteFirestoreData(uid, email);
        if (kDebugMode) {
          print('✅ Firestore data deleted');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Firestore deletion error (continuing): $e');
        }
      }

      // Delete Firebase Auth account
      if (kDebugMode) {
        print('Step 3: Deleting Firebase Auth account...');
      }

      await userCredential.user!.delete();

      if (kDebugMode) {
        print('✅ Firebase Auth account deleted');
      }

      // Clear SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (kDebugMode) {
          print('✅ SharedPreferences cleared');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Cache clear error: $e');
        }
      }

      // Sign out
      await FirebaseAuth.instance.signOut();

      if (kDebugMode) {
        print('========== AKUN BERHASIL DIHAPUS ==========');
      }

      // Show success and navigate to login
      if (mounted) {
        _showMessage('Akun berhasil dihapus');

        await Future.delayed(const Duration(milliseconds: 800));

        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 70,
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Akun Dihapus',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akun Anda telah berhasil dihapus dari sistem',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Terima kasih telah menggunakan aplikasi kami',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
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
                        'OK',
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
        print('========== FIREBASE ERROR ==========');
        print('Error Code: ${e.code}');
        print('Error Message: ${e.message}');
      }

      String msg = e.message ?? 'Gagal menghapus akun';
      _showMessage(msg, isError: true);
    } catch (e) {
      if (kDebugMode) {
        print('========== GENERAL ERROR ==========');
        print('Error:  $e');
      }

      _showMessage('Terjadi kesalahan:  ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteFirestoreData(String uid, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (kDebugMode) {
        print('   🔄 Deleting Firestore data...');
      }

      // Check if staff
      final staffDoc = await firestore.collection('staff').doc(uid).get();

      if (staffDoc.exists) {
        if (kDebugMode) {
          print('   🔄 Staff account detected');
        }

        // Delete from GoCloud
        try {
          final selectUri = 'https://api.247go.app/v5/select/';
          final selectResponse = await http.post(
            Uri.parse(selectUri),
            body: {
              'token': token,
              'project': project,
              'collection': 'staff',
              'appid': appid,
              'email': email,
            },
          );

          if (selectResponse.statusCode == 200) {
            final responseData = json.decode(selectResponse.body);
            if (responseData is List && responseData.isNotEmpty) {
              final staffId = responseData.first['_id'];

              final deleteUri = 'https://api.247go.app/v5/delete/';
              await http.post(
                Uri.parse(deleteUri),
                body: {
                  'token': token,
                  'project': project,
                  'collection': 'staff',
                  'appid': appid,
                  '_id': staffId,
                },
              );

              if (kDebugMode) {
                print('   ✅ Deleted from GoCloud');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ⚠️ GoCloud deletion error: $e');
          }
        }

        // Delete from Firestore
        await staffDoc.reference.delete();
        if (kDebugMode) {
          print('   ✅ Deleted staff/$uid from Firestore');
        }
      } else {
        // Regular user
        await firestore.collection('user').doc(uid).delete();
        if (kDebugMode) {
          print('   ✅ Deleted user/$uid from Firestore');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ⚠️ Firestore deletion error: $e');
      }
      // Don't throw, just log
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close, color: Colors.red[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF7A9B3B);
    return WillPopScope(
      onWillPop: () async {
        return !_isProcessing;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.red),
            ),
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Hapus Akun',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Penghapusan akun bersifat permanen dan tidak dapat dibatalkan',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info
                Text(
                  'Masukkan kata sandi untuk konfirmasi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),

                // Password Field
                Text(
                  'Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure1,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kata sandi',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kata sandi harus diisi';
                            }
                            if (v.trim().length < 6) {
                              return 'Kata sandi minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscure1 ? Icons.visibility_off : Icons.visibility,
                          color: accent,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                Text(
                  'Konfirmasi Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _confirmController,
                          obscureText: _obscure2,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Masukkan ulang kata sandi',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Konfirmasi kata sandi harus diisi';
                            }
                            if (v.trim() != _passwordController.text.trim()) {
                              return 'Kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _obscure2 ? Icons.visibility_off : Icons.visibility,
                          color: accent,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFff6b6b), Color(0xFFff5252)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isProcessing ? null : _handleDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 55,
                    alignment: Alignment.center,
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                'Menghapus.. .',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hapus Akun Permanen',
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
