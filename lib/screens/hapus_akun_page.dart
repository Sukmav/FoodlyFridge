import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

    final pwd = _passwordController.text.trim();

    // Quick validation: Check if user exists
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showMessage('Tidak ada user aktif.', isError: true);
      return;
    }

    // Quick reauthentication check (to verify password is correct)
    setState(() => _isProcessing = true);

    try {
      if (kDebugMode) print('🔍 Quick password verification for: ${user.email}');

      final cred = EmailAuthProvider.credential(email: user.email!, password: pwd);
      await user.reauthenticateWithCredential(cred).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'Koneksi timeout.',
          );
        },
      );

      if (kDebugMode) print('✅ Password verified');
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('❌ Verification failed: ${e.code}');
      String message = 'Gagal verifikasi password.';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Kata sandi salah. Silakan coba lagi.';
      } else if (e.code == 'user-not-found') {
        message = 'Akun tidak ditemukan.';
      } else if (e.code == 'timeout' || e.code == 'network-request-failed') {
        message = 'Koneksi internet bermasalah. Silakan coba lagi.';
      }

      _showMessage(message, isError: true);
      setState(() => _isProcessing = false);
      return;
    } catch (e) {
      if (kDebugMode) print('❌ Unexpected error: $e');
      _showMessage('Terjadi kesalahan. Silakan coba lagi.', isError: true);
      setState(() => _isProcessing = false);
      return;
    }

    // Show final confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Hapus Akun',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Akun Anda akan dihapus secara permanen. Anda akan langsung diarahkan ke halaman login.\n\nLanjutkan?',
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
            child: Text('Ya, Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) {
      setState(() => _isProcessing = false);
      return;
    }

    // Immediately navigate to login page
    if (kDebugMode) print('🚀 Navigating to login page...');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }

    // Delete account in background (fire and forget)
    _deleteAccountInBackground(user, pwd);
  }

  // Background deletion method
  void _deleteAccountInBackground(User user, String password) async {
    try {
      if (kDebugMode) print('🗑️ Background deletion started for: ${user.email}');

      final prefs = await SharedPreferences.getInstance();
      final cred = EmailAuthProvider.credential(email: user.email!, password: password);

      // Reauthenticate
      try {
        await user.reauthenticateWithCredential(cred).timeout(const Duration(seconds: 10));
        if (kDebugMode) print('✅ Background reauth successful');
      } catch (e) {
        if (kDebugMode) print('⚠️ Background reauth failed: $e');
        // Continue anyway since we already verified password
      }

      // Delete Firestore data (non-blocking)
      try {
        await _deleteFirestoreData(user.uid, user.email!).timeout(const Duration(seconds: 10));
      } catch (e) {
        if (kDebugMode) print('⚠️ Firestore deletion error: $e');
      }

      // Delete Firebase Auth account
      try {
        await user.delete().timeout(const Duration(seconds: 10));
        if (kDebugMode) print('✅ Firebase Auth account deleted');
      } catch (e) {
        if (kDebugMode) print('⚠️ Auth deletion error: $e');
      }

      // Cleanup local data
      try {
        await prefs.clear();
        await FirebaseAuth.instance.signOut();
        if (kDebugMode) print('✅ Local data cleared');
      } catch (e) {
        if (kDebugMode) print('⚠️ Cleanup error: $e');
      }

      if (kDebugMode) print('🎉 Background deletion completed');
    } catch (e) {
      if (kDebugMode) print('❌ Background deletion error: $e');
    }
  }

  // Helper method for Firestore deletion with timeout
  Future<void> _deleteFirestoreData(String uid, String email) async {
    try {
      final firestore = FirebaseFirestore.instance;

      if (kDebugMode) print('   🔄 Deleting Firestore data...');

      // Check if this is a staff account
      final staffDoc = await firestore.collection('staff').doc(uid).get().timeout(const Duration(seconds: 3));

      if (staffDoc.exists) {
        // This is a staff account - delete from GoCloud too
        if (kDebugMode) print('   🔄 Detected staff account, deleting from GoCloud...');
        try {
          // Get staff data to find the GoCloud _id
          final staffQuery = await firestore
              .collection('staff')
              .where('email', isEqualTo: email)
              .get()
              .timeout(const Duration(seconds: 3));

          if (staffQuery.docs.isNotEmpty) {
            // Delete from GoCloud using email to find the record
            final uri = 'https://api.247go.app/v5/select/';
            final selectResponse = await http.post(
              Uri.parse(uri),
              body: {
                'token': token,
                'project': project,
                'collection': 'staff',
                'appid': appid,
                'email': email,
              },
            ).timeout(const Duration(seconds: 3));

            if (selectResponse.statusCode == 200) {
              final responseData = json.decode(selectResponse.body);
              if (responseData is List && responseData.isNotEmpty) {
                final staffId = responseData.first['_id'];

                // Delete from GoCloud
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
                ).timeout(const Duration(seconds: 3));

                if (kDebugMode) print('   ✅ Deleted staff from GoCloud');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('   ⚠️ GoCloud staff deletion error: $e (continuing...)');
        }

        // Delete staff document from Firestore
        await staffDoc.reference.delete().timeout(const Duration(seconds: 2));
        if (kDebugMode) print('   ✅ Deleted staff/$uid from Firestore');
      } else {
        // This is a regular user account - delete user document from Firestore
        final userDocRef = firestore.collection('user').doc(uid);
        await userDocRef.delete().timeout(const Duration(seconds: 3));
        if (kDebugMode) print('   ✅ Deleted user/$uid from Firestore');
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