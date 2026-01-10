import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kedai_page.dart';
import '../helpers/kedai_service.dart';
import 'ubah_kata_sandi.dart';
import 'profile_page.dart';
import 'hapus_akun_page.dart';

class PengaturanPage extends StatefulWidget {
  final String userId;
  final VoidCallback? onProfileUpdated; // TAMBAHKAN callback

  const PengaturanPage({
    super.key,
    required this.userId,
    this. onProfileUpdated, // TAMBAHKAN ini
  });

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final Color _primaryColor = const Color(0xFF7A9B3B);
  final KedaiService _kedaiService = KedaiService();

  // PERBAIKAN: Method untuk navigasi ke ProfilePage dengan handle result
  Future<void> _navigateToProfile() async {
    if (kDebugMode) {
      print('========== NAVIGATING TO PROFILE FROM PENGATURAN ==========');
      print('User ID: ${widget.userId}');
    }

    // Load current username dari SharedPreferences/Firebase
    String? currentUserName;
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUserName = prefs.getString('user_name_${widget.userId}');

      if (currentUserName == null || currentUserName.isEmpty) {
        final user = FirebaseAuth.instance. currentUser;
        if (user != null && user.displayName != null) {
          currentUserName = user. displayName;
        }
      }

      if (kDebugMode) {
        print('Current Username: $currentUserName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading current username: $e');
      }
    }

    // Navigate ke ProfilePage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(
          userId: widget.userId,
          initialName: currentUserName,
        ),
      ),
    );

    if (kDebugMode) {
      print('========== RETURNED FROM PROFILE PAGE ==========');
      print('Result: $result');
    }

    // Handle result dari ProfilePage
    if (result != null && result is Map<String, dynamic>) {
      if (result['success'] == true && result['name'] != null) {
        final newName = result['name'] as String;

        if (kDebugMode) {
          print('✅ Profile updated successfully');
          print('New Username: $newName');
        }

        // Panggil callback untuk notify HomePage
        if (widget.onProfileUpdated != null) {
          if (kDebugMode) {
            print('✅ Calling onProfileUpdated callback');
          }
          widget.onProfileUpdated!();
        }

        // Show success toast
        Fluttertoast.showToast(
          msg: "Profil berhasil diperbarui! ",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );

        // Optional: Auto pop kembali ke Beranda setelah 1 detik
        await Future.delayed(const Duration(milliseconds: 1000));

        // Set flag untuk navigate ke Beranda
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('navigate_to_beranda_after_profile', true);

          if (kDebugMode) {
            print('✅ Set flag to navigate to Beranda');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error setting navigate flag: $e');
          }
        }
      }
    }
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
        print('Background kedai check finished for user ${widget.userId}.  kedai != null: ${kedai != null}');
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

  void _showDeleteAccountConfirmation() async {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?. isNotEmpty == true
        ? user! .displayName!
        : (user?.email ?? 'akun Anda');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Hapus Akun', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun "$display"?  Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Tidak', style: GoogleFonts.poppins(color: Colors.grey[700])),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Ya', style: GoogleFonts. poppins(color: Colors. red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HapusAkunPage()),
      );
    } else {
      if (kDebugMode) print('User canceled account deletion confirmation.');
    }
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    Color?  textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow:  [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          title,
          style: GoogleFonts. poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? const Color(0xFF5B7FBD),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color:  textColor ?? const Color(0xFF5B7FBD),
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 8),
          _buildMenuItem(
            title: 'Profil',
            onTap:  _navigateToProfile,
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
            title:  'Struk',
            onTap: _navigateToStruk,
          ),
          _buildMenuItem(
            title: 'Hapus Akun',
            onTap: _showDeleteAccountConfirmation,
            textColor: Colors.red,
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}