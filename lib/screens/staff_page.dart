import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../model/staff.dart';
import '../helpers/staff_service.dart';


class StaffPage extends StatefulWidget {
  final String userId;

  const StaffPage({
    super.key,
    required this.userId,
  });

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final StaffService _staffService = StaffService();
  List<StaffModel> _staffList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final staffList = await _staffService.getStaffByUserId(widget.userId);
      setState(() {
        _staffList = staffList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddStaff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahStaffPage(userId: widget.userId),
      ),
    );

    if (result == true) {
      _loadStaff(); // Refresh list
    }
  }

  void _navigateToEditStaff(StaffModel staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahStaffPage(
          userId: widget.userId,
          staff: staff,
        ),
      ),
    );

    if (result == true) {
      _loadStaff(); // Refresh list
    }
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Staff',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${staff.nama_staff}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _staffService.deleteStaff(staff.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Staff berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStaff();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus staff'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Staff',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan staff untuk memulai',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddStaff,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Tambah Staff',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A9B3B),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _staffList.length,
      itemBuilder: (context, index) {
        final staff = _staffList[index];
        return _buildStaffCard(staff);
      },
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToEditStaff(staff),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7A9B3B),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: staff.foto_profile != null
                      ? Image.memory(
                          base64Decode(staff.foto_profile!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey[400],
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Staff Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.nama_staff,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(122, 155, 59, 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            staff.jabatan,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7A9B3B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.email,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20, color: Color(0xFF7A9B3B)),
                        const SizedBox(width: 12),
                        Text(
                          'Edit',
                          style: GoogleFonts.poppins(),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        Text(
                          'Hapus',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditStaff(staff);
                  } else if (value == 'delete') {
                    _deleteStaff(staff);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffList.isEmpty
              ? _buildEmptyState()
              : _buildStaffList(),
      floatingActionButton: _staffList.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddStaff,
              backgroundColor: const Color(0xFF7A9B3B),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ==================== TAMBAH/EDIT STAFF PAGE ====================
class TambahStaffPage extends StatefulWidget {
  final String userId;
  final StaffModel? staff; // Untuk mode edit

  const TambahStaffPage({
    super.key,
    required this.userId,
    this.staff,
  });

  @override
  State<TambahStaffPage> createState() => _TambahStaffPageState();
}

class _TambahStaffPageState extends State<TambahStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final StaffService _staffService = StaffService();

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();

  String? _selectedJabatan;
  String? _fotoProfileBase64;
  File? _selectedImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final List<String> _jabatanOptions = [
    'Inventory',
    'Kasir',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      // Mode edit - populate fields
      _namaController.text = widget.staff!.nama_staff;
      _emailController.text = widget.staff!.email;
      _selectedJabatan = widget.staff!.jabatan;
      _fotoProfileBase64 = widget.staff!.foto_profile;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomorTeleponController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Convert to base64
        final bytes = await _selectedImage!.readAsBytes();
        _fotoProfileBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Convert to base64
        final bytes = await _selectedImage!.readAsBytes();
        _fotoProfileBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih Sumber Foto',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7A9B3B)),
              title: Text(
                'Kamera',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF7A9B3B)),
              title: Text(
                'Galeri',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedJabatan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih jabatan terlebih dahulu')),
      );
      return;
    }

    // Validasi password jika mode tambah
    if (widget.staff == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password harus diisi')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      if (widget.staff == null) {
        // Mode tambah
        success = await _staffService.addStaff(
          userId: widget.userId,
          namaStaff: _namaController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          nomorTelepon: _nomorTeleponController.text.trim(),
          jabatan: _selectedJabatan!,
          fotoProfile: _fotoProfileBase64,
        );
      } else {
        // Mode edit
        success = await _staffService.updateStaff(
          staffId: widget.staff!.id,
          userId: widget.userId,
          namaStaff: _namaController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          nomorTelepon: _nomorTeleponController.text.trim(),
          jabatan: _selectedJabatan,
          fotoProfile: _fotoProfileBase64,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.staff == null
                    ? 'Staff berhasil ditambahkan'
                    : 'Staff berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan data staff'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDescriptionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.staff == null ? 'Tambah Staff' : 'Edit Staff',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Nama
            Text(
              'Nama',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama staff',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7A9B3B), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            Text(
              'Email',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Masukkan email',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7A9B3B), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email harus diisi';
                }
                if (!value.contains('@')) {
                  return 'Email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Kata Sandi
            Text(
              'Kata Sandi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                hintText: widget.staff == null ? 'Masukkan kata sandi' : 'Kosongkan jika tidak diubah',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7A9B3B), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF7A9B3B),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              style: GoogleFonts.poppins(),
              validator: (value) {
                if (widget.staff == null && (value == null || value.isEmpty)) {
                  return 'Kata sandi harus diisi';
                }
                if (value != null && value.isNotEmpty && value.length < 6) {
                  return 'Kata sandi minimal 6 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Nomor Telepon
            Text(
              'Nomor Telepon',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomorTeleponController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Masukkan nomor telepon',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7A9B3B), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor telepon harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Foto Profile dan Jabatan Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Profile Section
                Column(
                  children: [
                    // Profile Photo Container
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF7A9B3B),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _fotoProfileBase64 != null
                                  ? Image.memory(
                                      base64Decode(_fotoProfileBase64!),
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        'Foto Profil',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF7A9B3B),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Kamera Button
                    OutlinedButton(
                      onPressed: _pickImageFromCamera,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7A9B3B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Kamera',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF7A9B3B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Galeri Button
                    OutlinedButton(
                      onPressed: _pickImageFromGallery,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF7A9B3B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      ),
                      child: Text(
                        'Gelari',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF7A9B3B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),

                // Jabatan Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jabatan',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dropdown Jabatan
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedJabatan,
                            isExpanded: true,
                            hint: Text(
                              'Pilih Jabatan',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF7A9B3B),
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            items: _jabatanOptions.map((String jabatan) {
                              return DropdownMenuItem<String>(
                                value: jabatan,
                                child: Text(jabatan),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedJabatan = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Display jabatan description
                      if (_selectedJabatan != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(122, 155, 59, 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromRGBO(122, 155, 59, 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deskripsi Jabatan ${_selectedJabatan!}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7A9B3B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_selectedJabatan == 'Kasir') ...[
                                _buildDescriptionItem('1. Melakukan transaksi penjualan'),
                                _buildDescriptionItem('2. Mencetak struk pembayaran'),
                                _buildDescriptionItem('3. Melihat dan memilih menu'),
                              ] else if (_selectedJabatan == 'Inventory') ...[
                                _buildDescriptionItem('1. Mengelola stok bahan baku masuk'),
                                _buildDescriptionItem('2. Memantau stok dan tanggal kedaluarsa'),
                                _buildDescriptionItem('3. Mencatat dan mengelola waste bahan baku'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A9B3B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

