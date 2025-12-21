import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../restapi.dart';
import '../config.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menu;
  final VoidCallback? onMenuUpdated;
  final VoidCallback? onMenuDeleted;

  const MenuDetailPage({
    super.key,
    required this.menu,
    this.onMenuUpdated,
    this.onMenuDeleted,
  });

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  final DataService _dataService = DataService();
  bool _isLoading = false;

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  List<Map<String, dynamic>> _parseBahanBaku() {
    List<Map<String, dynamic>> result = [];

    try {
      String bahanStr = widget.menu['bahan']?.toString() ?? '';
      String jumlahStr = widget.menu['jumlah']?.toString() ?? '';
      String satuanStr = widget.menu['satuan']?.toString() ?? '';
      String biayaStr = widget.menu['biaya']?.toString() ?? '';

      if (bahanStr.isEmpty) return result;

      List<String> bahanList = bahanStr.split(',');
      List<String> jumlahList = jumlahStr.split(',');
      List<String> satuanList = satuanStr.split(',');
      List<String> biayaList = biayaStr.split(',');

      for (int i = 0; i < bahanList.length; i++) {
        result.add({
          'nama': bahanList[i].trim(),
          'jumlah': i < jumlahList.length ? jumlahList[i].trim() : '0',
          'satuan': i < satuanList.length ? satuanList[i].trim() : '',
          'biaya': i < biayaList.length ? biayaList[i].trim() : '0',
        });
      }
    } catch (e) {
      print('Error parsing bahan baku: $e');
    }

    return result;
  }

  double _calculateTotalRecipeCost() {
    double total = 0.0;
    List<Map<String, dynamic>> bahanList = _parseBahanBaku();

    for (var bahan in bahanList) {
      double biaya = double.tryParse(bahan['biaya']) ?? 0.0;
      total += biaya;
    }

    return total;
  }

  double _calculateFoodCost() {
    double hargaJual = double.tryParse(widget.menu['harga_jual']?.toString() ?? '0') ?? 0.0;
    double totalRecipeCost = _calculateTotalRecipeCost();

    if (hargaJual > 0 && totalRecipeCost > 0) {
      return (totalRecipeCost / hargaJual) * 100;
    }

    return 0.0;
  }

  Future<void> _deleteMenu() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hapus Menu?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin menghapus "${widget.menu['nama_menu']}"? Data yang dihapus tidak dapat dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== MULAI DELETE MENU ===');
      print('ID Menu: ${widget.menu['_id']}');
      print('Nama Menu: ${widget.menu['nama_menu']}');

      // Gunakan removeWhere berdasarkan nama menu
      final result = await _dataService.removeWhere(
        token,
        project,
        'menu',
        appid,
        'nama_menu',
        widget.menu['nama_menu'],
      );

      print('Result delete: $result');

      if (result == true || result == 'true' || result.toString().contains('"status":"1"')) {
        Fluttertoast.showToast(
          msg: "Menu '${widget.menu['nama_menu']}' berhasil dihapus!",
          backgroundColor: Colors.green,
        );

        // Callback
        widget.onMenuDeleted?.call();

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        throw Exception('Delete gagal: $result');
      }

    } catch (e) {
      print('Error delete menu: $e');
      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Gagal menghapus menu: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> bahanBakuList = _parseBahanBaku();
    double totalRecipeCost = _calculateTotalRecipeCost();
    double foodCostPercentage = _calculateFoodCost();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.menu['nama_menu'] ?? '',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.green[300]!, width: 3),
              ),
              child: widget.menu['foto_menu'] != null && widget.menu['foto_menu'].toString().isNotEmpty
                  ? Image.network(
                widget.menu['foto_menu'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.grey,
                  );
                },
              )
                  : const Icon(
                Icons.restaurant,
                size: 80,
                color: Colors.grey,
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.green[700]!,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        'Detail',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        'Riwayat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Menu
                  _buildDetailSection(
                    'Informasi Menu',
                    Colors.green[700]!,
                    [
                      _buildDetailRow('Kode Menu', widget.menu['id_menu'] ?? '-', Colors.green[700]!),
                      _buildDetailRow('Nama Menu', widget.menu['nama_menu'] ?? '-', Colors.green[700]!),
                      _buildDetailRow('Kategori', widget.menu['kategori'] ?? '-', Colors.green[700]!),
                      _buildDetailRow('Harga Jual', 'Rp ${_formatNumber(double.tryParse(widget.menu['harga_jual']?.toString() ?? '0') ?? 0)}', Colors.green[700]!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Barcode Section
                  if (widget.menu['barcode'] != null && widget.menu['barcode'].toString().isNotEmpty) ...[
                    Text(
                      'Barcode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data: widget.menu['barcode'],
                            width: 500,
                            height: 100,
                            drawText: false,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.menu['barcode'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Ringkasan Perhitungan
                  _buildDetailSection(
                    'Ringkasan Perhitungan',
                    Colors.green[700]!,
                    [
                      _buildDetailRow('Total Recipe Cost', 'Rp ${_formatNumber(totalRecipeCost)}', Colors.green[700]!),
                      _buildDetailRow('Food Cost %', '${foodCostPercentage.toStringAsFixed(1)}%', Colors.green[700]!),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Daftar Bahan Baku
                  Text(
                    'Daftar Bahan Baku',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const Divider(thickness: 1),
                  const SizedBox(height: 12),

                  if (bahanBakuList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Tidak ada bahan baku',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange[300]!, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Table Header
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'No',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Nama Bahan',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Jumlah',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Biaya',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Table Rows
                          ...bahanBakuList.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> bahan = entry.value;
                            bool isEven = index % 2 == 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : Colors.grey[50],
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${index + 1}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      bahan['nama'],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${bahan['jumlah']} ${bahan['satuan']}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rp${_formatNumber(double.tryParse(bahan['biaya']) ?? 0)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement edit functionality
                              Fluttertoast.showToast(
                                msg: "Fitur edit sedang dalam pengembangan",
                                backgroundColor: Colors.blue,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Ubah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _deleteMenu,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hapus',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Color titleColor, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const Divider(thickness: 1),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}