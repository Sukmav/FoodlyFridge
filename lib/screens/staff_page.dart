import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
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
  final DataService _dataService = DataService();
  final StaffService _staffService = StaffService();
  List<StaffModel> _staffList = [];
  List<StaffModel> _filteredList = [];
  bool _isLoading = false;

  // Search controller to match the example UI (does not change underlying logic)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterStaff(_searchController.text);
    });
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // _loadStaff aligned with pattern used in bahan_baku_page.dart (selectAll + parsing)
  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) print('=== LOADING STAFF DATA === for userId: ${widget.userId}');

      final response = await _data_service_selectAll();

      if (kDebugMode) print('Response: $response');

      if (response == '[]' || response.isEmpty || response == 'null') {
        if (kDebugMode) print('Data kosong atau null');
        setState(() {
          _staffList = [];
          _filteredList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map) {
        if (decodedData.containsKey('data') && decodedData['data'] is List) {
          dataList = decodedData['data'] as List<dynamic>;
        } else {
          // If it's a single object wrap it into a list
          dataList = [decodedData];
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      if (kDebugMode) print('Jumlah data yang dimuat: ${dataList.length}');

      final newList = <StaffModel>[];
      for (var item in dataList) {
        try {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            newList.add(StaffModel.fromJson(map));
          } else {
            // sometimes item might be a JSON string
            if (item is String) {
              try {
                final inner = json.decode(item);
                if (inner is Map) newList.add(StaffModel.fromJson(Map<String, dynamic>.from(inner)));
              } catch (_) {}
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing staff item: $e');
            print('Item: $item');
          }
        }
      }

      // Optionally filter client-side by user_id if backend didn't filter
      final hasUserIdField = newList.any((s) => s.user_id != null && s.user_id!.isNotEmpty);
      final finalList = hasUserIdField ? newList.where((s) => s.user_id == widget.userId).toList() : newList;

      setState(() {
        _staffList = finalList;
        _filteredList = List.from(_staffList);
        _isLoading = false;
      });

      if (kDebugMode) print('Data berhasil dimuat: ${_staffList.length} items');
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _staffList = [];
          _filteredList = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('DEBUG: _loadStaff exception: $e\n$stackTrace');
    }
  }

  // small helper to call DataService.selectAll (kept separate for clarity)
  Future<String> _data_service_selectAll() async {
    final res = await _dataService.selectAll(
      token,
      project,
      'staff',
      appid,
    );
    // Pastikan selalu mengembalikan String untuk konsistensi parsing selanjutnya
    if (res == null) return '';
    if (res is String) return res;
    try {
      return json.encode(res);
    } catch (_) {
      return res.toString();
    }
  }

  void _filterStaff(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredList = List.from(_staffList);
      });
      return;
    }

    final q = query.toLowerCase();
    setState(() {
      _filteredList = _staffList.where((s) {
        final name = s.nama_staff.toLowerCase();
        final email = s.email.toLowerCase();
        final jab = (s.jabatan ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || jab.contains(q);
      }).toList();
    });
  }

  void _navigateToAddStaff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahStaffPage(userId: widget.userId),
      ),
    );

    // Always refresh after returning to ensure newly added data is shown.
    // Keep existing behavior of waiting a short delay to allow backend to persist data.
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadStaff();

    if (result == true) {
      // success feedback handled by add page; we ensured list refresh
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

    // Always refresh after returning from edit page to reflect possible changes.
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadStaff();

    if (result == true) {
      // list refreshed
    }
  }

// Ganti fungsi _deleteStaff lama dengan fungsi ini
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

    if (confirm != true) return;

    bool success = false;
    String lastError = '';

    // Try preferred StaffService.deleteStaff first (kept for compatibility)
    try {
      if (staff.id.isNotEmpty) {
        final res = await _staffService.deleteStaff(staff.id);
        if (res == true) {
          success = true;
        } else {
          // Note result false -> will try fallbacks below
          if (kDebugMode) print('StaffService.deleteStaff returned false for id ${staff.id}');
        }
      } else {
        if (kDebugMode) print('Staff id is empty, will try fallback removals');
      }
    } catch (e) {
      lastError = 'deleteStaff error: $e';
      if (kDebugMode) print(lastError);
    }

    // Fallback 1: DataService.removeId (remove by id using restapi)
    if (!success && staff.id.isNotEmpty) {
      try {
        final resRemoveId = await _dataService.removeId(token, project, 'staff', appid, staff.id);
        if (resRemoveId == true) {
          success = true;
        } else if (resRemoveId is String) {
          final s = resRemoveId.toLowerCase();
          if (s == 'true' || s.contains('"status":"1"') || s.contains('"ok":true')) success = true;
        }
        if (kDebugMode) print('removeId result: $resRemoveId (success=$success)');
      } catch (e) {
        lastError = 'removeId error: $e';
        if (kDebugMode) print(lastError);
      }
    }

    // Fallback 2: DataService.removeWhere (remove by email)
    if (!success && staff.email.isNotEmpty) {
      try {
        final resRemoveWhere = await _data_service_removeWhereEmail(staff.email);
        if (resRemoveWhere == true) {
          success = true;
        } else if (resRemoveWhere is String) {
          final s = resRemoveWhere.toLowerCase();
          if (s == 'true' || s.contains('"status":"1"') || s.contains('"ok":true')) success = true;
        }
        if (kDebugMode) print('removeWhere(email) result: $resRemoveWhere (success=$success)');
      } catch (e) {
        lastError = 'removeWhere error: $e';
        if (kDebugMode) print(lastError);
      }
    }

    // Final UI feedback & refresh
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadStaff();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus staff. ${lastError.isNotEmpty ? lastError : ''}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Helper kecil untuk removeWhere by email dengan penanganan respons fleksibel
  Future<dynamic> _data_service_removeWhereEmail(String email) {
    return _dataService.removeWhere(
      token,
      project,
      'staff',
      appid,
      'email',
      email,
    );
  }

  // Helper to convert jabatan value to displayed label (to match image wording)
  String _displayRole(String? jabatan) {
    if (jabatan == null || jabatan.isEmpty) return 'Admin';
    final j = jabatan.toLowerCase();
    if (j.contains('inventory') || j.contains('inventaris')) return 'Staff Inventaris';
    if (j.contains('kasir')) return 'Kasir';
    // fallback
    return jabatan;
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            hintText: 'Cari Dari Nama',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffModel staff, {bool highlighted = false}) {
    // Colors to match example
    final Color cardBg = highlighted ? const Color(0xFFEFF6F2) : Colors.white;
    final Color nameColor = const Color(0xFF2E3A59); // deep blue-ish
    final borderColor = highlighted ? Colors.transparent : Colors.grey.withOpacity(0.12);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7A9B3B).withOpacity(0.1),
            border: Border.all(
              color: const Color(0xFF7A9B3B),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Color(0xFF7A9B3B),
            size: 32,
          ),
        ),
        title: Text(
          staff.nama_staff,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: nameColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              staff.email,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _displayRole(staff.jabatan),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          offset: const Offset(0, 30),
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEditStaff(staff);
            } else if (value == 'delete') {
              _deleteStaff(staff);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Ubah', style: GoogleFonts.poppins()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Hapus', style: GoogleFonts.poppins(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        // IMPORTANT: disable tap-to-edit. Edit and delete are available only via the 3-dot menu.
        onTap: null,
      ),
    );
  }

  Widget _buildEmptyState() {
    // Keep previous behavior but nicer layout matching design
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

          //Bagian halaman tambah staff
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

  Widget _buildListContent() {
    // Optionally highlight first item to match the sample image look
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final s = _filteredList[index];
        final highlighted = index == 0; // highlight the first one like image example
        return _buildStaffCard(s, highlighted: highlighted);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                ? _buildEmptyState()
                : _buildListContent(),
          ),
        ],
      ),
      // Floating action button to add staff (uses existing _navigateToAddStaff)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddStaff,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
  final DataService _dataService = DataService();

  // Controllers
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedJabatan;
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
      // password intentionally left empty (user fills to change)
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // fungsi logic yang digunakan untuk menyipan data
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
        success = await _staffService.addStaff(
          userId: widget.userId,
          namaStaff: _namaController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          jabatan: _selectedJabatan!,
          fotoProfile: null, // No photo
        );
      } else {
        // Try update by ID first; if ID empty, fallback to updateWhere
        if (widget.staff!.id.isNotEmpty) {
          // Use DataService.updateId for each field (server's update_id endpoint expects single-field updates)
          final id = widget.staff!.id;
          final futures = <Future<dynamic>>[];

          futures.add(_data_service_updateIdIfChanged('nama_staff', _namaController.text.trim(), id));
          futures.add(_data_service_updateIdIfChanged('email', _emailController.text.trim(), id));
          if (_passwordController.text.isNotEmpty) {
            futures.add(_data_service_updateIdIfChanged('kata_sandi', _passwordController.text, id));
          }
          futures.add(_data_service_updateIdIfChanged('jabatan', _selectedJabatan ?? '', id));
          // futures.add(_data_service_updateIdIfChanged('foto', _fotoProfileBase64 ?? '', id));

          final results = await Future.wait(futures);

          // A result can be bool true or string; consider success if all are true or 'true' or contain '"status":"1"'
          bool allOk = true;
          for (var r in results) {
            if (r == true) continue;
            if (r is String) {
              final s = r.toLowerCase();
              if (s == 'true' || s.contains('"status":"1"') || s.contains('"ok":true')) continue;
            }
            allOk = false;
            if (kDebugMode) print('updateId returned unexpected result: $r');
          }
          success = allOk;
        } else {
          // fallback: update by where (email or nama_staff)
          success = await _updateStaffByWhere();
        }
      }

      if (mounted) {
        if (success) {
          // Tambahkan delay untuk memastikan data tersimpan di server
          await Future.delayed(const Duration(milliseconds: 500));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.staff == null ? 'Staff berhasil ditambahkan' : 'Staff berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
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
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) {
        print('Error _simpanStaff: $e\n$stackTrace');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<dynamic> _data_service_updateIdIfChanged(String field, String value, String id) {
    // If the value didn't change and was originally empty, we still call to ensure consistency.
    return _dataService.updateId(field, value, token, project, 'staff', appid, id);
  }

  Future<bool> _updateStaffByWhere() async {
    // Update multiple fields using updateWhere keyed by previous email (or name)
    final whereField = 'email';
    final whereValue = widget.staff?.email ?? widget.staff?.nama_staff ?? '';

    if (whereValue.isEmpty) return false;

    final fields = {
      'nama_staff': _namaController.text.trim(),
      'email': _emailController.text.trim(),
      'kata_sandi': _passwordController.text.isNotEmpty ? _passwordController.text : '',
      'jabatan': _selectedJabatan ?? '',
    };

    bool allOk = true;

    for (var entry in fields.entries) {
      try {
        final res = await _dataService.updateWhere(
          whereField,
          whereValue,
          entry.key,
          entry.value,
          token,
          project,
          'staff',
          appid,
        );
        if (res != true) {
          // some endpoints return 'true' as boolean, some as string; handle common cases
          if (res is String && res.contains('"status":"1"')) {
            // ok
          } else {
            allOk = false;
            if (kDebugMode) print('updateWhere failed for ${entry.key}: $res');
          }
        }
      } catch (e) {
        allOk = false;
        if (kDebugMode) print('updateWhere exception ${entry.key}: $e');
      }
    }

    return allOk;
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
            const SizedBox(height: 8),

            // Avatar Icon Display (non-interactive)
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7A9B3B).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF7A9B3B),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 50,
                  color: Color(0xFF7A9B3B),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Jabatan Section
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
                      _buildDescriptionItem('2. Memantau stok dan tanggal kadaluarsa'),
                      _buildDescriptionItem('3. Mencatat dan mengelola sampah bahan baku'),
                    ],
                  ],
                ),
              ),
            ],
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