import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _handleDelete() async {
    if (_isProcessing) return; // guard double tap
    if (!_formKey.currentState!.validate()) return;

    final pwd = _passwordController.text.trim();

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        Fluttertoast.showToast(msg: 'Tidak ada user aktif.', backgroundColor: Colors.red);
        return;
      }

      // 1) Reauthenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: pwd);

      try {
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) print('Reauth failed: ${e.code} ${e.message}');
        String message = 'Gagal melakukan autentikasi ulang.';
        if (e.code == 'wrong-password') {
          message = 'Kata sandi salah. Silakan coba lagi.';
        } else if (e.code == 'user-mismatch') {
          message = 'Akun tidak cocok.';
        } else if (e.code == 'user-not-found') {
          message = 'Akun tidak ditemukan.';
        }
        Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
        return;
      }

      // 2) Hapus data terkait di Firestore (atau DB lain) terlebih dahulu
      //    Contoh: hapus dokumen 'users/{uid}' jika ada. Tambahkan koleksi lain bila perlu.
      try {
        final uid = user.uid;
        final firestore = FirebaseFirestore.instance;

        // Hapus dokumen user jika ada
        final userDocRef = firestore.collection('users').doc(uid);
        final doc = await userDocRef.get();
        if (doc.exists) {
          await userDocRef.delete();
          if (kDebugMode) print('Deleted users/$uid document from Firestore.');
        }

        // TODO: jika ada data lain (kedai, transaksi, dsb.) hapus atau tandai juga di sini.
      } catch (e) {
        // Jika penghapusan data Firestore gagal, kita terus mencoba menghapus akun,
        // tapi beri tahu developer di debug log.
        if (kDebugMode) print('Warning: failed to delete Firestore user data: $e');
      }

      // 3) Delete Firebase Auth user
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (kDebugMode) print('Delete user failed: ${e.code} ${e.message}');
        String message = 'Gagal menghapus akun: ${e.message ?? e.code}';
        if (e.code == 'requires-recent-login') {
          message = 'Sesi kadaluarsa. Silakan login ulang lalu coba hapus akun kembali.';
        }
        Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
        return;
      }

      // 4) Sign out to be safe
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      // 5) Informasi ke user & navigasi ke halaman login (hapus semua route)
      Fluttertoast.showToast(msg: 'Akun berhasil dihapus. Semua data di Firebase dihapus (jika tersedia).', backgroundColor: Colors.green);

      if (mounted) {
        // Ganti '/login' dengan route name atau widget login Anda jika berbeda.
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('FirebaseAuthException on delete flow: ${e.code} ${e.message}');
      String message = 'Terjadi kesalahan: ${e.message ?? e.code}';
      if (e.code == 'wrong-password') {
        message = 'Kata sandi salah.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Sesi Anda perlu diperbarui. Silakan login ulang dan coba lagi.';
      }
      Fluttertoast.showToast(msg: message, backgroundColor: Colors.red);
    } catch (e) {
      if (kDebugMode) print('Error deleting account: $e');
      Fluttertoast.showToast(msg: 'Terjadi kesalahan: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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