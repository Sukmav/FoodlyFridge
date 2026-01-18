import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_page.dart';
import 'home_page.dart';
import '../helpers/staff_service.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    if (!value.contains('@')) {
      return 'Email tidak valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // Show success popup after email sent
  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.surface,
          child: Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Email Terkirim!',
                  style: AppTextStyles.titleLarge.withColor(Color(0xFF667eea)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Silakan cek email Anda untuk reset password',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    _resetEmailController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            'Reset Password',
            style: AppTextStyles.titleLarge.withColor(Color(0xFF667eea)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan email Anda untuk menerima link reset password',
                style: AppTextStyles.bodySmall.withColor(
                  AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _resetEmailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: AppTextStyles.inputLabel,
                  hintText: 'nama@email.com',
                  hintStyle: AppTextStyles.inputHint,
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF667eea),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFF667eea), width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Batal',
                style: AppTextStyles.labelMedium.withColor(
                  AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                _sendPasswordResetEmail();
              },
              child: Text('Kirim', style: AppTextStyles.buttonMedium),
            ),
          ],
        );
      },
    );
  }

  // Send password reset email
  Future<void> _sendPasswordResetEmail() async {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: "Email tidak boleh kosong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
      return;
    }

    if (!email.contains('@')) {
      Fluttertoast.showToast(
        msg: "Format email tidak valid",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      Navigator.of(context).pop(); // Close reset dialog
      _showSuccessPopup();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal mengirim email reset password';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
    }
  }

  Future<void> _login() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with Firebase - works for both admin and staff
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Check if this is a staff account
      final staffDoc = await FirebaseFirestore.instance
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (staffDoc.exists) {
        // This is a staff login
        final staffData = staffDoc.data()!;

        Fluttertoast.showToast(
          msg: "Login sebagai ${staffData['jabatan']} berhasil!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.success,
          textColor: AppColors.textWhite,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                username: staffData['nama_staff'] ?? 'Staff',
                email: staffData['email'] ?? userCredential.user!.email ?? '',
                userId: staffData['user_id'] ?? userCredential.user!.uid,
                role: (staffData['jabatan'] ?? 'staff')
                    .toString()
                    .toLowerCase(),
              ),
            ),
          );
        }
        return;
      }

      // This is an admin/regular user login
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userCredential.user!.uid)
            .set({
              'email': userCredential.user!.email,
              'username': userCredential.user!.email?.split('@')[0] ?? 'User',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      final userData = userDoc.data() as Map<String, dynamic>?;

      Fluttertoast.showToast(
        msg: "Login berhasil!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.success,
        textColor: AppColors.textWhite,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              username:
                  userData?['username'] ??
                  userCredential.user!.email?.split('@')[0] ??
                  'User',
              email: userCredential.user!.email ?? '',
              userId: userCredential.user!.uid,
              role: 'admin', // Admin role
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login gagal';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          errorMessage = 'Password salah';
          break;
        case 'invalid-email':
          errorMessage = 'Format email tidak valid';
          break;
        case 'user-disabled':
          errorMessage = 'Akun telah dinonaktifkan';
          break;
        case 'invalid-credential':
          errorMessage = 'Email atau password salah';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.danger,
        textColor: AppColors.textWhite,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF667eea)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_rounded,
                              size: 45,
                              color: Colors.white,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 5,
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 15,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Foodify',
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Inventory Management System',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Login Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Text
                        Text(
                          'Selamat Datang Kembali',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masuk untuk mengelola inventori Anda',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Email Field
                        Text('Email', style: AppTextStyles.inputLabel),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _emailError != null
                                      ? AppColors.danger
                                      : Color(0xFF667eea).withOpacity(0.4),
                                  width: 1.5,
                                ),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667eea).withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTextStyles.inputText.copyWith(
                                  fontSize: 15,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _emailError = null;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'nama@gmail.com',
                                  hintStyle: AppTextStyles.inputHint.copyWith(
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_rounded,
                                    color: Color(0xFF667eea),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            if (_emailError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 6,
                                ),
                                child: Text(
                                  _emailError!,
                                  style: AppTextStyles.errorText.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        Text('Password', style: AppTextStyles.inputLabel),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _passwordError != null
                                      ? AppColors.danger
                                      : Color(0xFF667eea).withOpacity(0.4),
                                  width: 1.5,
                                ),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF667eea).withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: AppTextStyles.inputText.copyWith(
                                  fontSize: 15,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _passwordError = null;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: AppTextStyles.inputHint.copyWith(
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: Color(0xFF667eea),
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: Color(0xFF667eea).withOpacity(0.6),
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            if (_passwordError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 6,
                                ),
                                child: Text(
                                  _passwordError!,
                                  style: AppTextStyles.errorText.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            child: Text(
                              'Lupa Password?',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: Color(0xFF667eea),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Login Button dengan shadow yang lebih halus
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(
                                      0xFF764ba2,
                                    ).withOpacity(0.2), // Shadow lebih halus
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Masuk',
                                            style: AppTextStyles.buttonMedium
                                                .copyWith(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                          ),
                                          // const SizedBox(width: 10),
                                          // const Icon(
                                          //   Icons.arrow_forward_rounded,
                                          //   size: 20,
                                          //   color: Colors.white,
                                          // ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Register Section
                        Column(
                          children: [
                            Divider(
                              color: Color(0xFF667eea).withOpacity(0.2),
                              thickness: 1,
                              height: 1,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum memiliki akun? ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Daftar',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: Color(0xFF667eea),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Footer
                  Center(
                    child: Text(
                      '© 2026 Foodify',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
