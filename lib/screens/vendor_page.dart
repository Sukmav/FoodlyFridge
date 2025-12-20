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
  bool _isLoading = false;

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
        '',
        appid,
      );

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _vendorList = [];
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
        title: const Text('Vendor'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vendorList.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada data vendor.\nTambahkan vendor baru!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _vendorList.length,
                  itemBuilder: (context, index) {
                    final vendor = _vendorList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.nama_vendor,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB8860B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (vendor.nama_pic.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('PIC: ${vendor.nama_pic}'),
                                ],
                              ),
                            if (vendor.nomor_tlp.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(vendor.nomor_tlp),
                                ],
                              ),
                            if (vendor.alamat.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(vendor.alamat)),
                                ],
                              ),
                            if (vendor.bahan_baku.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(vendor.bahan_baku)),
                                ],
                              ),
                            if (vendor.catatan.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.note, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('Catatan: ${vendor.catatan}')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
