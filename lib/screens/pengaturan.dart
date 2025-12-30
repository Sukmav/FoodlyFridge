import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'kedai_page.dart';
import '../helpers/kedai_service.dart';
import 'ubah_kata_sandi.dart';
import 'profile_page.dart';

// IMPORT HALAMAN HAPUS AKUN
import 'hapus_akun_page.dart';

class PengaturanPage extends StatefulWidget {
  final String userId;

  const PengaturanPage({super.key, required this.userId});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final Color _primaryColor = const Color(0xFF7A9B3B);
  final KedaiService _kedaiService = KedaiService();

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: widget.userId),
      ),
    );
  }

  void _navigateToKedai() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KedaiPage(userId: widget.userId),
      ),
    );

    _kedaiService.getKedaiByUserId(widget.userId).then((kedai) {
      if (kDebugMode) {
        print('Background kedai check finished for user ${widget.userId}. kedai != null: ${kedai != null}');
      }
    }).catchError((e) {
      if (kDebugMode) print('Background kedai check failed: $e');
    });
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UbahKataSandiPage(userId: widget.userId),
      ),
    );
  }

  void _navigateToStruk() {
    Fluttertoast.showToast(
      msg: "Fitur Struk akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  // NEW: tampilkan konfirmasi sebelum lanjut ke halaman Hapus Akun
  void _showDeleteAccountConfirmation() async {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email ?? 'akun Anda');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Hapus Akun', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun "$display"? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Tidak', style: GoogleFonts.poppins(color: Colors.grey[700])),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Ya', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // lanjut ke halaman HapusAkunPage untuk input password & hapus
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HapusAkunPage()),
      );
    } else {
      // batal, kembali tanpa aksi
      if (kDebugMode) print('User canceled account deletion confirmation.');
    }
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? const Color(0xFF5B7FBD),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: textColor ?? const Color(0xFF5B7FBD),
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildMenuItem(
          title: 'Profil',
          onTap: _navigateToProfile,
        ),
        _buildMenuItem(
          title: 'Kedaimu',
          onTap: _navigateToKedai,
        ),
        _buildMenuItem(
          title: 'Ubah Kata Sandi',
          onTap: _navigateToChangePassword,
        ),
        _buildMenuItem(
          title: 'Struk',
          onTap: _navigateToStruk,
        ),
        _buildMenuItem(
          title: 'Hapus Akun',
          onTap: _showDeleteAccountConfirmation,
          textColor: Colors.red,
        ),
      ],
    );
  }
}