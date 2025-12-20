import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'kedai_page.dart';
import '../helpers/kedai_service.dart';


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
    // TODO: Navigate to Profile page
    Fluttertoast.showToast(
      msg: "Fitur Profil akan segera hadir",
      backgroundColor: Colors.blue,
    );
  }

  void _navigateToKedai() async {
    // Cek apakah user sudah punya data kedai
    try {
      final kedai = await _kedaiService.getKedaiByUserId(widget.userId);

      if (kedai != null) {
        // Jika sudah ada data, navigasi ke KedaiPage (akan load data otomatis)
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KedaiPage(userId: widget.userId),
          ),
        );

        // Jika ada perubahan data dari edit
        if (result == true && mounted) {
          if (kDebugMode) {
            print('Data kedai berhasil diupdate dari Pengaturan');
          }
          Fluttertoast.showToast(
            msg: "Data kedai berhasil diperbarui",
            backgroundColor: Colors.green,
          );
        }
      } else {
        // Jika belum ada data kedai, navigasi ke form kedai
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => KedaiPage(userId: widget.userId),
          ),
        );

        if (result == true && mounted) {
          if (kDebugMode) {
            print('Data kedai berhasil dibuat dari Pengaturan');
          }
          Fluttertoast.showToast(
            msg: "Data kedai berhasil disimpan",
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error navigating to kedai: $e');
      }
      Fluttertoast.showToast(
        msg: "Terjadi kesalahan: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
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
