import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import '../restapi.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import '../model/vendor.dart';

class StokMasukPage extends StatefulWidget {
  const StokMasukPage({super.key});

  @override
  State<StokMasukPage> createState() => _StokMasukPageState();
}

class _StokMasukPageState extends State<StokMasukPage> {
  final DataService _dataService = DataService();
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _qtyPembelianController = TextEditingController();
  final TextEditingController _hargaSatuanController = TextEditingController();

  BahanBakuModel? _selectedBahanBaku;
  VendorModel? _selectedVendor;
  DateTime _tanggalMasuk = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    _qtyPembelianController.dispose();
    _hargaSatuanController.dispose();
    super.dispose();
  }

  // Navigasi ke halaman pilih bahan baku
  Future<void> _navigateToPilihBahanBaku() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PilihBahanBakuPage(),
      ),
    );

    if (result != null && result is BahanBakuModel) {
      setState(() {
        _selectedBahanBaku = result;
        // Set harga satuan default dari harga per unit bahan baku
        _hargaSatuanController.text = result.harga_per_unit;
      });
    }
  }

  // Navigasi ke halaman pilih vendor
  Future<void> _navigateToPilihVendor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PilihVendorPage(),
      ),
    );

    if (result != null && result is VendorModel) {
      setState(() {
        _selectedVendor = result;
      });
    }
  }

  // Hitung total qty dan total harga
  String _calculateTotalQty() {
    if (_selectedBahanBaku == null || _qtyPembelianController.text.isEmpty) {
      return '0';
    }
    try {
      double qtyPembelian = double.parse(_qtyPembelianController.text);
      double grossQty = double.parse(_selectedBahanBaku!.gross_qty.isEmpty ? '1' : _selectedBahanBaku!.gross_qty);
      double totalQty = qtyPembelian * grossQty;
      return totalQty.toStringAsFixed(2);
    } catch (e) {
      return '0';
    }
  }

  String _calculateTotalHarga() {
    if (_qtyPembelianController.text.isEmpty || _hargaSatuanController.text.isEmpty) {
      return '0';
    }
    try {
      double qty = double.parse(_qtyPembelianController.text);
      double harga = double.parse(_hargaSatuanController.text);
      double total = qty * harga;
      return total.toStringAsFixed(0);
    } catch (e) {
      return '0';
    }
  }

  // Simpan data stok masuk
  Future<void> _buatPesanan() async {
    // Validasi
    if (_selectedBahanBaku == null) {
      Fluttertoast.showToast(
        msg: "Pilih bahan baku terlebih dahulu!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_selectedVendor == null) {
      Fluttertoast.showToast(
        msg: "Pilih vendor terlebih dahulu!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_qtyPembelianController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Masukkan qty pembelian!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_hargaSatuanController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Masukkan harga satuan!",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String tanggalMasukStr = '${_tanggalMasuk.year}-${_tanggalMasuk.month.toString().padLeft(2, '0')}-${_tanggalMasuk.day.toString().padLeft(2, '0')}';
      String totalQty = _calculateTotalQty();
      String totalHarga = _calculateTotalHarga();

      // Insert data ke database
      final result = await _dataService.insertStokMasuk(
        appid,
        _selectedBahanBaku!.id,
        tanggalMasukStr,
        _qtyPembelianController.text,
        totalQty,
        _hargaSatuanController.text,
        totalHarga,
        _selectedVendor!.id,
        _catatanController.text,
      );

      print('Result insert stok masuk: $result');

      // Update stok tersedia bahan baku
      if (_selectedBahanBaku!.id.isNotEmpty) {
        double stokSebelumnya = double.parse(_selectedBahanBaku!.stok_tersedia.isEmpty ? '0' : _selectedBahanBaku!.stok_tersedia);
        double stokBaru = stokSebelumnya + double.parse(totalQty);

        await _dataService.updateId(
          'stok_tersedia',
          stokBaru.toStringAsFixed(2),
          token,
          project,
          'bahan_baku',
          appid,
          _selectedBahanBaku!.id,
        );
      }

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Pesanan stok masuk berhasil dibuat!",
        backgroundColor: Colors.green,
      );

      // Kembali ke halaman sebelumnya
      Navigator.pop(context, true);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error membuat pesanan: $e');
      Fluttertoast.showToast(
        msg: "Gagal membuat pesanan: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Vendor
                  GestureDetector(
                    onTap: _navigateToPilihVendor,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A9B3B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Vendor',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B6D5B),
                                  ),
                                ),
                                if (_selectedVendor != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _selectedVendor!.nama_vendor,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pilih Bahan Baku
                  GestureDetector(
                    onTap: _navigateToPilihBahanBaku,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7A9B3B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pilih Bahan Baku',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5B6D5B),
                                  ),
                                ),
                                if (_selectedBahanBaku != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _selectedBahanBaku!.nama_bahan,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Form Input
                  if (_selectedBahanBaku != null) ...[
                    // Qty Pembelian
                    _buildInputField(
                      label: 'Qty Pembelian (${_selectedBahanBaku!.unit})',
                      controller: _qtyPembelianController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Total Qty (calculated)
                    _buildReadOnlyField(
                      label: 'Total Qty (${_selectedBahanBaku!.unit})',
                      value: _calculateTotalQty(),
                    ),
                    const SizedBox(height: 16),

                    // Harga Satuan
                    _buildInputField(
                      label: 'Harga Satuan',
                      controller: _hargaSatuanController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Total Harga (calculated)
                    _buildReadOnlyField(
                      label: 'Total Harga',
                      value: 'Rp ${_calculateTotalHarga()}',
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Masuk
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggalMasuk,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _tanggalMasuk = picked;
                          });
                        }
                      },
                      child: IgnorePointer(
                        child: _buildInputField(
                          label: 'Tanggal Masuk',
                          controller: TextEditingController(
                            text: '${_tanggalMasuk.day.toString().padLeft(2, '0')}/${_tanggalMasuk.month.toString().padLeft(2, '0')}/${_tanggalMasuk.year}',
                          ),
                          suffixIcon: Icons.calendar_today,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Catatan
                  const Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4A574),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _catatanController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Tambah Catatan',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFD4A574)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFFD4A574)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tombol Batal dan Buat Pesanan (tampil jika vendor dan bahan baku sudah dipilih)
                  if (_selectedVendor != null && _selectedBahanBaku != null) ...[
                    Row(
                      children: [
                        // Tombol Batal
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reset form atau kembali ke halaman sebelumnya
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: Color(0xFF7A9B3B),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A9B3B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tombol Buat Pesanan
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _buatPesanan,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF7A9B3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Buat Pesanan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: const Color(0xFFD4A574))
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== HALAMAN PILIH BAHAN BAKU ====================
class PilihBahanBakuPage extends StatefulWidget {
  const PilihBahanBakuPage({super.key});

  @override
  State<PilihBahanBakuPage> createState() => _PilihBahanBakuPageState();
}

class _PilihBahanBakuPageState extends State<PilihBahanBakuPage> {
  final DataService _dataService = DataService();
  List<BahanBakuModel> _bahanBakuList = [];
  List<BahanBakuModel> _filteredList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBahanBaku() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _dataService.selectAll(
        token,
        project,
        'bahan_baku',
        appid,
      );

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _bahanBakuList = [];
          _filteredList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map) {
        if (decodedData.containsKey('data')) {
          dataList = decodedData['data'] as List<dynamic>;
        } else {
          dataList = [decodedData];
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      final newList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();

      setState(() {
        _bahanBakuList = newList;
        _filteredList = List.from(_bahanBakuList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _bahanBakuList = [];
        _filteredList = [];
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal memuat data: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  void _filterBahanBaku(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _bahanBakuList;
      } else {
        _filteredList = _bahanBakuList
            .where((bahan) =>
                bahan.nama_bahan.toLowerCase().contains(query.toLowerCase()) ||
                bahan.kategori.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5B6D5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Bahan Baku',
          style: TextStyle(
            color: Color(0xFF5B6D5B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBahanBaku,
              decoration: InputDecoration(
                hintText: 'Cari bahan baku...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5A3C), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Tidak ada data bahan baku', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final bahan = _filteredList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5A3C).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Color(0xFF8B5A3C),
                                ),
                              ),
                              title: Text(
                                bahan.nama_bahan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Stok: ${bahan.stok_tersedia} ${bahan.unit}'),
                                  Text('Harga: Rp ${bahan.harga_per_unit}/${bahan.unit}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context, bahan);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ==================== HALAMAN PILIH VENDOR ====================
class PilihVendorPage extends StatefulWidget {
  const PilihVendorPage({super.key});

  @override
  State<PilihVendorPage> createState() => _PilihVendorPageState();
}

class _PilihVendorPageState extends State<PilihVendorPage> {
  final DataService _dataService = DataService();
  List<VendorModel> _vendorList = [];
  List<VendorModel> _filteredList = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendor() async {
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
          _filteredList = [];
          _isLoading = false;
        });
        return;
      }

      final dynamic decodedData = json.decode(response);
      List<dynamic> dataList;

      if (decodedData is Map) {
        if (decodedData.containsKey('data')) {
          dataList = decodedData['data'] as List<dynamic>;
        } else {
          dataList = [decodedData];
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      } else {
        dataList = [];
      }

      final newList = dataList.map((json) => VendorModel.fromJson(json)).toList();

      setState(() {
        _vendorList = newList;
        _filteredList = List.from(_vendorList);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _vendorList = [];
        _filteredList = [];
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal memuat data: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  void _filterVendor(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _vendorList;
      } else {
        _filteredList = _vendorList
            .where((vendor) =>
                vendor.nama_vendor.toLowerCase().contains(query.toLowerCase()) ||
                vendor.nama_pic.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5B6D5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Vendor',
          style: TextStyle(
            color: Color(0xFF5B6D5B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterVendor,
              decoration: InputDecoration(
                hintText: 'Cari vendor...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5A3C), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Tidak ada data vendor', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final vendor = _filteredList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5A3C).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: Color(0xFF8B5A3C),
                                ),
                              ),
                              title: Text(
                                vendor.nama_vendor,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('PIC: ${vendor.nama_pic}'),
                                  Text('Telp: ${vendor.nomor_tlp}'),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.pop(context, vendor);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

