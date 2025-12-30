import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final old = _oldController.text.trim();
    final neu = _newController.text.trim();
    final conf = _confirmController.text.trim();

    if (old.isEmpty) return 'Kata sandi lama harus diisi';
    if (neu.isEmpty) return 'Kata sandi baru harus diisi';
    if (neu.length < 6) return 'Kata sandi baru minimal 6 karakter';
    if (conf.isEmpty) return 'Konfirmasi kata sandi harus diisi';
    if (neu != conf) return 'Konfirmasi kata sandi tidak cocok';
    if (neu == old) {
      return 'Kata sandi baru harus berbeda dari kata sandi lama';
    }
    return null;
  }

  Future<void> _save() async {
    final validationError = _validateInputs();
    if (validationError != null) {
      Fluttertoast.showToast(
        msg: validationError,
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User tidak ditemukan, silakan login kembali');
      }

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('Email pengguna tidak tersedia');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: _oldController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newController.text.trim());

      try {
        await _firestore.collection('user').doc(user.uid).set({
          'password_updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to update Firestore marker: $e');
        }
      }

      Fluttertoast.showToast(
        msg: 'Kata sandi berhasil diperbarui',
        backgroundColor: Colors.green,
      );

      if (Navigator.canPop(context)) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Gagal memperbarui kata sandi';

      if (e.code == 'wrong-password') {
        msg = 'Kata sandi lama salah';
      } else if (e.code == 'weak-password') {
        msg = 'Kata sandi baru terlalu lemah';
      } else if (e.code == 'requires-recent-login') {
        msg = 'Sesi kadaluarsa. Silakan login ulang';
      } else {
        msg = e.message ?? msg;
      }

      Fluttertoast.showToast(
        msg: msg,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Change password error: $e');
      Fluttertoast.showToast(
        msg: 'Terjadi kesalahan: ${e.toString()}',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
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
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kata Sandi Lama'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _oldController,
              hint: 'Masukkan Kata Sandi Lama',
              obscure: _obscureOld,
              onToggle: () =>
                  setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),

            const Text('Kata Sandi Baru'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _newController,
              hint: 'Masukkan Kata Sandi Baru',
              obscure: _obscureNew,
              onToggle: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),

            const Text('Konfirmasi Kata Sandi Baru'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmController,
              hint: 'Masukkan Konfirmasi Kata Sandi Baru',
              obscure: _obscureConfirm,
              onToggle: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A9B3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Simpan',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
