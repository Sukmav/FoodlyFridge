import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
import '../model/vendor.dart';

class VendorPage extends StatefulWidget {
  const VendorPage({super.key});

  @override
  State<VendorPage> createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {
  final DataService _dataService = DataService();
  List<VendorModel> _vendorList = [];
  List<VendorModel> _filteredVendorList = [];
  bool _isLoading = false;

  final _searchController = TextEditingController();
  final _namaVendorController = TextEditingController();
  final _namaPicController = TextEditingController();
  final _nomorTlpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _bahanBakuController = TextEditingController();
  final _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _namaVendorController.dispose();
    _namaPicController.dispose();
    _nomorTlpController.dispose();
    _alamatController.dispose();
    _bahanBakuController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'vendor',
        appid,
      );

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _vendorList = [];
          _filteredVendorList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map && decodedData.containsKey('data')) {
        dataList = decodedData['data'] as List<dynamic>;
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      final newList = dataList.map((json) => VendorModel.fromJson(json)).toList();

      setState(() {
        _vendorList = newList;
        _filteredVendorList = newList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: "Error loading vendors: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _filterVendors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVendorList = _vendorList;
      } else {
        _filteredVendorList = _vendorList.where((vendor) {
          return vendor.nama_vendor.toLowerCase().contains(query.toLowerCase()) ||
                 vendor.nama_pic.toLowerCase().contains(query.toLowerCase()) ||
                 vendor.bahan_baku.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _saveVendor() async {
    if (_namaVendorController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama Vendor harus diisi",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      final response = await _dataService.insertVendor(
        appid,
        _namaVendorController.text,
        _namaPicController.text,
        _nomorTlpController.text,
        _alamatController.text,
        _bahanBakuController.text,
        _catatanController.text,
      );

      if (response != '[]') {
        // Clear form
        _namaVendorController.clear();
        _namaPicController.clear();
        _nomorTlpController.clear();
        _alamatController.clear();
        _bahanBakuController.clear();
        _catatanController.clear();

        Fluttertoast.showToast(
          msg: "Vendor berhasil ditambahkan",
          backgroundColor: Colors.green,
        );

        // Don't reload here, will reload after page closes
      } else {
        Fluttertoast.showToast(
          msg: "Gagal menambahkan vendor",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showVendorDetail(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Detail Vendor',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Vendor
                _buildDetailTextField(
                  label: 'Nama Vendor',
                  value: vendor.nama_vendor,
                ),
                const SizedBox(height: 16),

                // PIC
                _buildDetailTextField(
                  label: 'PIC',
                  value: vendor.nama_pic.isEmpty ? '' : vendor.nama_pic,
                ),
                const SizedBox(height: 16),

                // Nomor Kontak
                _buildDetailTextField(
                  label: 'Nomor Kontak',
                  value: vendor.nomor_tlp.isEmpty ? '' : vendor.nomor_tlp,
                ),
                const SizedBox(height: 16),

                // Alamat
                _buildDetailTextField(
                  label: 'Alamat',
                  value: vendor.alamat.isEmpty ? '' : vendor.alamat,
                ),
                const SizedBox(height: 16),

                // Bahan Baku
                _buildDetailTextField(
                  label: 'Bahan Baku',
                  value: vendor.bahan_baku.isEmpty ? '' : vendor.bahan_baku,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Catatan
                _buildDetailTextField(
                  label: 'Catatan',
                  value: vendor.catatan.isEmpty ? '' : vendor.catatan,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditVendorDialog(vendor);
                        },
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6D4C41),
                          side: const BorderSide(color: Color(0xFF6D4C41), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDeleteVendor(vendor);
                        },
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTextField({
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFB8860B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFB8860B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _showEditVendorDialog(VendorModel vendor) {
    // Pre-fill controllers with existing data
    _namaVendorController.text = vendor.nama_vendor;
    _namaPicController.text = vendor.nama_pic;
    _nomorTlpController.text = vendor.nomor_tlp;
    _alamatController.text = vendor.alamat;
    _bahanBakuController.text = vendor.bahan_baku;
    _catatanController.text = vendor.catatan;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Edit Vendor',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ...existing form fields from _showAddVendorDialog...
                // Nama Vendor
                const Text(
                  'Nama Vendor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaVendorController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nama Vendor',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PIC
                const Text(
                  'PIC',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaPicController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nama PIC',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nomor Kontak
                const Text(
                  'Nomor Kontak',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomorTlpController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+621234567890',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alamat
                const Text(
                  'Alamat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _alamatController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Alamat Vendor',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bahan Baku
                const Text(
                  'Bahan Baku',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bahanBakuController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Masukkan list bahan baku yang biasa dibeli',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Catatan
                const Text(
                  'Catatan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tambah Catatan',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateVendor(vendor);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4C41),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _loadVendors();
    });
  }

  Future<void> _updateVendor(VendorModel vendor) async {
    if (_namaVendorController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Nama Vendor harus diisi",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      // Show loading
      Fluttertoast.showToast(
        msg: "Memproses update...",
        backgroundColor: Colors.blue,
      );

      // Update all fields using the original vendor name as identifier
      // Update nama_pic
      bool success1 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'nama_pic',
        _namaPicController.text,
        token,
        project,
        'vendor',
        appid,
      );

      // Update nomor_tlp
      bool success2 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'nomor_tlp',
        _nomorTlpController.text,
        token,
        project,
        'vendor',
        appid,
      );

      // Update alamat
      bool success3 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'alamat',
        _alamatController.text,
        token,
        project,
        'vendor',
        appid,
      );

      // Update bahan_baku
      bool success4 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'bahan_baku',
        _bahanBakuController.text,
        token,
        project,
        'vendor',
        appid,
      );

      // Update catatan
      bool success5 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'catatan',
        _catatanController.text,
        token,
        project,
        'vendor',
        appid,
      );

      // Update nama_vendor last (after all other fields)
      bool success6 = await _dataService.updateWhere(
        'nama_vendor',
        vendor.nama_vendor,
        'nama_vendor',
        _namaVendorController.text,
        token,
        project,
        'vendor',
        appid,
      );

      if (success1 && success2 && success3 && success4 && success5 && success6) {
        Fluttertoast.showToast(
          msg: "Vendor berhasil diupdate",
          backgroundColor: Colors.green,
        );

        // Clear form
        _namaVendorController.clear();
        _namaPicController.clear();
        _nomorTlpController.clear();
        _alamatController.clear();
        _bahanBakuController.clear();
        _catatanController.clear();

        // Reload vendors
        await _loadVendors();
      } else {
        Fluttertoast.showToast(
          msg: "Gagal update vendor. Silakan coba lagi.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDeleteVendor(VendorModel vendor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Hapus Vendor',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus vendor "${vendor.nama_vendor}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteVendor(vendor);
    }
  }

  Future<void> _deleteVendor(VendorModel vendor) async {
    try {
      // Show loading
      Fluttertoast.showToast(
        msg: "Menghapus vendor...",
        backgroundColor: Colors.blue,
      );

      final result = await _dataService.removeWhere(
        token,
        project,
        'vendor',
        appid,
        'nama_vendor',
        vendor.nama_vendor,
      );

      if (result == true) {
        Fluttertoast.showToast(
          msg: "Vendor berhasil dihapus",
          backgroundColor: Colors.green,
        );

        // Reload vendors
        await _loadVendors();
      } else {
        Fluttertoast.showToast(
          msg: "Gagal menghapus vendor. Silakan coba lagi.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  void _showAddVendorDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Tambah Vendor',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Vendor
                const Text(
                  'Nama Vendor',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaVendorController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nama Vendor',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // PIC
                const Text(
                  'PIC',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _namaPicController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nama PIC',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Nomor Kontak
                const Text(
                  'Nomor Kontak',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomorTlpController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: '+621234567890',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alamat
                const Text(
                  'Alamat',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _alamatController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan Alamat Vendor',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bahan Baku
                const Text(
                  'Bahan Baku',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bahanBakuController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Masukkan list bahan baku yang biasa dibeli',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Catatan
                const Text(
                  'Catatan',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _catatanController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Tambah Catatan',
                    hintStyle: const TextStyle(color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFB8860B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Simpan Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _saveVendor();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4C41),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Reload vendors when returning from add page
      _loadVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 5,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVendors,
              decoration: InputDecoration(
                hintText: 'Cari Dari Nama',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF5B6D5B), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // Vendor List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendorList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              _vendorList.isEmpty
                                  ? 'Belum ada data vendor.\nTambahkan vendor baru!'
                                  : 'Tidak ada vendor yang sesuai pencarian',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        itemCount: _filteredVendorList.length,
                        itemBuilder: (context, index) {
                          final vendor = _filteredVendorList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!, width: 1),
                            ),
                            child: InkWell(
                              onTap: () => _showVendorDetail(vendor),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar Icon
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF5B6D5B),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Vendor Name
                                    Expanded(
                                      child: Text(
                                        vendor.nama_vendor,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5B6D5B),
                                        ),
                                      ),
                                    ),

                                    // Arrow icon
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVendorDialog,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Vendor'),
      ),
    );
  }
}
