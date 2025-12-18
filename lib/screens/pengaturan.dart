import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'kedai_page.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final Color _primaryColor = const Color(0xFF7A9B3B);

  void _navigateToProfile() {
    // TODO: Navigate to Profile page
    Fluttertoast.showToast(
      msg: "Fitur Profil akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  void _navigateToKedai() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KedaiPage()),
    );
  }

  void _navigateToChangePassword() {
    // TODO: Navigate to Change Password page
    Fluttertoast.showToast(
      msg: "Fitur Ubah Kata Sandi akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  void _navigateToStruk() {
    // TODO: Navigate to Struk page
    Fluttertoast.showToast(
      msg: "Fitur Struk akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Hapus Akun',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.delete();
                    if (mounted) {
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(
                        msg: "Akun berhasil dihapus",
                        backgroundColor: Colors.green,
                      );
                    }
                  }
                } catch (e) {
                  Navigator.of(context).pop();
                  Fluttertoast.showToast(
                    msg: "Gagal menghapus akun: ${e.toString()}",
                    backgroundColor: Colors.red,
                  );
                }
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          onTap: _showDeleteAccountDialog,
          textColor: Colors.red,
        ),
      ],
    );
  }
}
