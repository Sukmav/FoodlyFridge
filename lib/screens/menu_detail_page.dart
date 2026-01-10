import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../config.dart';
import '../restapi.dart';
import 'add_menu_form.dart';

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

  // Gradient Colors
  static const LinearGradient priceTagGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9C4DFF), Color(0xFF7B2CBF), Color(0xFF5A189A)],
    stops: [0.0, 0.5, 1.0],
  );

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  List<Map<String, dynamic>> _parseBahanBaku() {
    final List<Map<String, dynamic>> result = [];
    try {
      final rawStructured = widget.menu['bahan_baku'];
      if (rawStructured != null) {
        if (rawStructured is List) {
          for (var it in rawStructured) {
            result.add({
              'nama':
                  it['nama_bahan']?.toString() ?? it['nama']?.toString() ?? '',
              'jumlah':
                  it['jumlah']?.toString() ?? it['qty']?.toString() ?? '0',
              'satuan': it['unit']?.toString() ?? '',
              'biaya': it['biaya']?.toString() ?? '0',
            });
          }
          return result;
        } else if (rawStructured is String && rawStructured.isNotEmpty) {
          try {
            final decoded = json.decode(rawStructured);
            if (decoded is List) {
              for (var it in decoded) {
                result.add({
                  'nama':
                      it['nama_bahan']?.toString() ??
                      it['nama']?.toString() ??
                      '',
                  'jumlah':
                      it['jumlah']?.toString() ?? it['qty']?.toString() ?? '0',
                  'satuan': it['unit']?.toString() ?? '',
                  'biaya': it['biaya']?.toString() ?? '0',
                });
              }
              return result;
            }
          } catch (_) {}
        }
      }

      final bahanStr = widget.menu['bahan']?.toString() ?? '';
      if (bahanStr.isEmpty) return result;

      final bahanList = bahanStr.split(',');
      final jumlahList = (widget.menu['jumlah']?.toString() ?? '').split(',');
      final satuanList = (widget.menu['satuan']?.toString() ?? '').split(',');
      final biayaList = (widget.menu['biaya']?.toString() ?? '').split(',');

      for (int i = 0; i < bahanList.length; i++) {
        result.add({
          'nama': bahanList[i].trim(),
          'jumlah': i < jumlahList.length ? jumlahList[i].trim() : '0',
          'satuan': i < satuanList.length ? satuanList[i].trim() : '',
          'biaya': i < biayaList.length ? biayaList[i].trim() : '0',
        });
      }
    } catch (e) {
      debugPrint('Error parsing bahan baku: $e');
    }
    return result;
  }

  double _calculateTotalRecipeCost() {
    double total = 0.0;
    final list = _parseBahanBaku();
    for (var item in list) {
      final biaya = double.tryParse(item['biaya']?.toString() ?? '0') ?? 0.0;
      total += biaya;
    }
    return total;
  }

  double _calculateFoodCost() {
    final hargaJual =
        double.tryParse(
          widget.menu['harga_jual']?.toString() ??
              widget.menu['harga']?.toString() ??
              '0',
        ) ??
        0.0;
    final totalRecipe = _calculateTotalRecipeCost();
    if (hargaJual > 0 && totalRecipe > 0) {
      return (totalRecipe / hargaJual) * 100;
    }
    return 0.0;
  }

  Future<void> _deleteMenu() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Hapus Menu? '),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${widget.menu['nama_menu']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      debugPrint('Dialog result: $confirm');

      if (confirm != true) {
        debugPrint('User cancelled delete');
        return;
      }

      setState(() => _isLoading = true);

      final id =
          widget.menu['_id']?.toString() ?? widget.menu['id']?.toString() ?? '';
      debugPrint('Attempting to delete menu with ID: $id');

      if (id.isEmpty) {
        Fluttertoast.showToast(
          msg: "ID menu tidak ditemukan",
          backgroundColor: Colors.red,
        );
        setState(() => _isLoading = false);
        return;
      }

      final success = await _data_service_removeIdSafe(id);
      debugPrint('Delete result: $success');

      if (success) {
        Fluttertoast.showToast(
          msg: "Menu '${widget.menu['nama_menu']}' berhasil dihapus! ",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        widget.onMenuDeleted?.call();
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: "Gagal menghapus menu",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } catch (e, stack) {
      debugPrint('Error in _deleteMenu: $e');
      debugPrint('Stack trace: $stack');

      Fluttertoast.showToast(
        msg: "Terjadi kesalahan:  ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _data_service_removeIdSafe(String id) async {
    try {
      final res = await _dataService.removeId(
        token,
        project,
        'menu',
        appid,
        id,
      );
      return res == true;
    } catch (e) {
      debugPrint('removeId error: $e');
      return false;
    }
  }

  void _openEditForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuForm(
          initialData: widget.menu,
          isEditing: true,
          onMenuUpdated: () {
            debugPrint('Menu updated via callback');
            widget.onMenuUpdated?.call();

            if (mounted) {
              setState(() {});
            }

            Fluttertoast.showToast(
              msg: "Menu telah diperbarui! ",
              backgroundColor: Colors.green,
              toastLength: Toast.LENGTH_SHORT,
            );
          },
        ),
      ),
    ).then((value) {
      debugPrint('Edit form closed');
    });
  }

  // Helper method untuk menampilkan foto menu
  Widget _buildMenuImage(String? fotoMenu) {
    // Jika foto kosong atau null
    if (fotoMenu == null || fotoMenu.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
        ),
      );
    }

    // Jika foto adalah URL (dimulai dengan http)
    if (fotoMenu.startsWith('http')) {
      return Image.network(
        fotoMenu,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, st) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    // Jika foto adalah base64 (string panjang)
    if (fotoMenu.length > 100) {
      try {
        // Handle base64 dengan atau tanpa prefix
        final base64String = fotoMenu.contains(',')
            ? fotoMenu.split(',').last
            : fotoMenu;

        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error decoding base64 image: $error');
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
            );
          },
        );
      } catch (e) {
        debugPrint('Error displaying base64 image: $e');
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, size: 60, color: Colors.grey),
          ),
        );
      }
    }

    // Default jika tidak cocok dengan format apapun
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bahanList = _parseBahanBaku();
    final totalRecipe = _calculateTotalRecipeCost();
    final foodCost = _calculateFoodCost();
    final hargaJual =
        double.tryParse(
          widget.menu['harga_jual']?.toString() ??
              widget.menu['harga']?.toString() ??
              '0',
        ) ??
        0.0;
    final fotoMenu = widget.menu['foto_menu']?.toString();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Menu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMenuImage(fotoMenu),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Informasi Menu Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informasi Menu',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: priceTagGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Rp ${_formatNumber(hargaJual)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            'Kode Menu',
                            widget.menu['id_menu'] ?? '-',
                          ),
                          _buildInfoRow(
                            'Nama Menu',
                            widget.menu['nama_menu'] ?? '-',
                          ),
                          _buildInfoRow(
                            'Kategori',
                            widget.menu['kategori'] ?? '-',
                          ),
                          Divider(height: 32),

                          // Cost Summary
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Total Recipe Cost',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rp ${_formatNumber(totalRecipe)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Food Cost',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${foodCost.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: foodCost > 50
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Barcode Section
                  if (widget.menu['barcode'] != null &&
                      widget.menu['barcode'].toString().isNotEmpty)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barcode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: widget.menu['barcode'],
                                      width: 250,
                                      height: 80,
                                      drawText: false,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    widget.menu['barcode'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Bahan Baku Section
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_basket_rounded,
                                color: Colors.orange[700],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Daftar Bahan Baku',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),

                          if (bahanList.isEmpty)
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Tidak ada bahan baku',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Nama Bahan',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Jumlah',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Biaya',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8),
                                ...bahanList.asMap().entries.map((e) {
                                  final idx = e.key;
                                  final item = e.value;
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: idx < bahanList.length - 1
                                          ? Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[200]!,
                                              ),
                                            )
                                          : null,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${idx + 1}. ${item['nama']}',
                                            maxLines: 2,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${item['jumlah']} ${item['satuan']}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Rp${_formatNumber(double.tryParse(item['biaya']?.toString() ?? '0') ?? 0)}',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 80), // Spacer untuk floating buttons
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openEditForm,
                icon: Icon(Icons.edit_rounded, size: 20),
                label: Text('Ubah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _deleteMenu,
                icon: Icon(Icons.delete_rounded, size: 20),
                label: Text('Hapus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
