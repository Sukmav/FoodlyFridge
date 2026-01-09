import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Helper method to show message (with fallback to SnackBar if Toast fails)
  void _showMessage(String message, {bool isError = false}) {
    try {
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: isError ? Colors.red : Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      // Fallback to SnackBar if Fluttertoast fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    if (_isProcessing) return; // guard double tap
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus Akun',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan dihapus secara permanen.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final pwd = _passwordController.text.trim();

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        _showMessage('Tidak ada user aktif.', isError: true);
        return;
      }

      if (kDebugMode) print('🗑️ Starting Firebase account deletion for: ${user.email}');
      if (kDebugMode) print('   Firebase UID: ${user.uid}');

      // Get SharedPreferences for cleanup
      final prefs = await SharedPreferences.getInstance();

      // Step 1: Reauthenticate user
      final cred = EmailAuthProvider.credential(email: user.email!, password: pwd);

      try {
        if (kDebugMode) print('🔄 Step 1: Reauthenticating user...');
        await user.reauthenticateWithCredential(cred).timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw FirebaseAuthException(
              code: 'timeout',
              message: 'Koneksi timeout saat autentikasi.',
            );
          },
        );
        if (kDebugMode) print('   ✅ Reauthentication successful');
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) print('   ❌ Reauth failed: ${e.code}');
        String message = 'Gagal melakukan autentikasi ulang.';

        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Kata sandi salah. Silakan coba lagi.';
        } else if (e.code == 'user-mismatch') {
          message = 'Akun tidak cocok.';
        } else if (e.code == 'user-not-found') {
          message = 'Akun tidak ditemukan.';
        } else if (e.code == 'timeout') {
          message = 'Koneksi timeout. Periksa koneksi internet Anda.';
        } else if (e.code == 'network-request-failed') {
          message = 'Tidak ada koneksi internet.';
        }

        _showMessage(message, isError: true);
        return;
      } catch (e) {
        if (kDebugMode) print('   ❌ Unexpected error: $e');
        _showMessage('Gagal autentikasi: ${e.toString()}', isError: true);
        return;
      }

      // Step 2: Delete Firestore data (non-blocking)
      if (kDebugMode) print('🔄 Step 2: Deleting Firestore data...');
      try {
        await _deleteFirestoreData(user.uid, user.email!).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            if (kDebugMode) print('   ⚠️ Firestore deletion timeout, continuing...');
          },
        );
      } catch (e) {
        if (kDebugMode) print('   ⚠️ Firestore deletion error: $e, continuing...');
      }

      // Step 3: Delete Firebase Auth user (CRITICAL)
      try {
        if (kDebugMode) print('🔄 Step 3: Deleting Firebase Auth account...');
        await user.delete().timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw FirebaseAuthException(
              code: 'timeout',
              message: 'Timeout saat menghapus akun.',
            );
          },
        );
        if (kDebugMode) print('   ✅ Firebase Auth account deleted successfully!');
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) print('   ❌ Delete auth failed: ${e.code}');
        String message = 'Gagal menghapus akun: ${e.message ?? e.code}';

        if (e.code == 'requires-recent-login') {
          message = 'Sesi kadaluarsa. Silakan login ulang lalu coba lagi.';
        } else if (e.code == 'timeout') {
          message = 'Koneksi timeout. Periksa koneksi internet Anda.';
        } else if (e.code == 'network-request-failed') {
          message = 'Tidak ada koneksi internet.';
        }

        _showMessage(message, isError: true);
        return;
      }

      // Step 4: Cleanup local data
      if (kDebugMode) print('🔄 Step 4: Cleaning up local data...');
      try {
        await prefs.clear().timeout(const Duration(seconds: 2));
        await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 2));
        if (kDebugMode) print('   ✅ Local data cleared');
      } catch (e) {
        if (kDebugMode) print('   ⚠️ Cleanup error (non-critical): $e');
      }

      // Step 5: Success!
      if (kDebugMode) print('🎉 Account deletion completed successfully!');
      _showMessage('Akun berhasil dihapus.');

      // Step 6: Navigate to Login
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('❌ FirebaseAuthException: ${e.code}');
      String message = 'Terjadi kesalahan: ${e.message ?? e.code}';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Kata sandi salah.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Sesi kadaluarsa. Silakan login ulang.';
      } else if (e.code == 'network-request-failed') {
        message = 'Tidak ada koneksi internet.';
      }

      _showMessage(message, isError: true);
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected error: $e');
      _showMessage('Terjadi kesalahan: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Helper method for Firestore deletion with timeout
  Future<void> _deleteFirestoreData(String uid, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (kDebugMode) print('   🔄 Deleting Firestore data...');

      // Delete user document
      final userDocRef = firestore.collection('users').doc(uid);
      await userDocRef.delete().timeout(const Duration(seconds: 3));
      if (kDebugMode) print('   ✅ Deleted users/$uid from Firestore');

      // Delete staff document if exists
      final staffQuery = await firestore
          .collection('staff')
          .where('email', isEqualTo: email)
          .get()
          .timeout(const Duration(seconds: 3));

      for (var doc in staffQuery.docs) {
        await doc.reference.delete().timeout(const Duration(seconds: 2));
        if (kDebugMode) print('   ✅ Deleted staff/${doc.id} from Firestore');
      }
    } catch (e) {
      if (kDebugMode) print('   ⚠️ Firestore deletion error: $e');
      // Don't throw, just log
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = const Color(0xFF7A9B3B);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Hapus Akun',
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text(
              'Masukkan kata sandi untuk konfirmasi penghapusan akun.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            Text(
              'Kata Sandi',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure1,
              decoration: InputDecoration(
                hintText: 'Masukkan Kata Sandi',
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility, color: accent),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Kata sandi harus diisi';
                if (v.trim().length < 6) return 'Kata sandi minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Konfirmasi Kata Sandi',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure2,
              decoration: InputDecoration(
                hintText: 'Masukkan Konfirmasi Kata Sandi',
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility, color: accent),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Konfirmasi kata sandi harus diisi';
                if (v.trim() != _passwordController.text.trim()) return 'Kata sandi tidak cocok';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Perhatian: Tindakan ini akan menghapus akun Anda secara permanen.',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.red[700]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Hapus Akun', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}