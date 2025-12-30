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

  String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }

  // Robust parser for bahan_baku supporting structured list and legacy comma-separated fields.
  List<Map<String, dynamic>> _parseBahanBaku() {
    final List<Map<String, dynamic>> result = [];

    try {
      // 1) structured 'bahan_baku' (List or JSON string)
      final rawStructured = widget.menu['bahan_baku'];
      if (rawStructured != null) {
        if (rawStructured is List) {
          for (var it in rawStructured) {
            result.add({
              'nama': it['nama_bahan']?.toString() ?? it['nama']?.toString() ?? '',
              'jumlah': it['jumlah']?.toString() ?? it['qty']?.toString() ?? '0',
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
                  'nama': it['nama_bahan']?.toString() ?? it['nama']?.toString() ?? '',
                  'jumlah': it['jumlah']?.toString() ?? it['qty']?.toString() ?? '0',
                  'satuan': it['unit']?.toString() ?? '',
                  'biaya': it['biaya']?.toString() ?? '0',
                });
              }
              return result;
            }
          } catch (_) {
            // fallthrough to legacy parsing
          }
        }
      }

      // 2) legacy comma-separated fields
      final bahanStr = widget.menu['bahan']?.toString() ?? '';
      if (bahanStr.isEmpty) return result;

      final jumlahStr = widget.menu['jumlah']?.toString() ?? '';
      final satuanStr = widget.menu['satuan']?.toString() ?? '';
      final biayaStr = widget.menu['biaya']?.toString() ?? '';

      final bahanList = bahanStr.split(',');
      final jumlahList = jumlahStr.split(',');
      final satuanList = satuanStr.split(',');
      final biayaList = biayaStr.split(',');

      for (int i = 0; i < bahanList.length; i++) {
        result.add({
          'nama': bahanList[i].trim(),
          'jumlah': i < jumlahList.length ? jumlahList[i].trim() : '0',
          'satuan': i < satuanList.length ? satuanList[i].trim() : '',
          'biaya': i < biayaList.length ? biayaList[i].trim() : '0',
        });
      }
    } catch (e) {
      // If parse fails, return empty list (defensive)
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
    final hargaJual = double.tryParse(widget.menu['harga_jual']?.toString() ?? widget.menu['harga']?.toString() ?? '0') ?? 0.0;
    final totalRecipe = _calculateTotalRecipeCost();
    if (hargaJual > 0 && totalRecipe > 0) {
      return (totalRecipe / hargaJual) * 100;
    }
    return 0.0;
  }

  Future<void> _deleteMenu() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Hapus Menu?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Apakah Anda yakin ingin menghapus "${widget.menu['nama_menu']}"? Data yang dihapus tidak dapat dikembalikan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal'))),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final id = widget.menu['_id']?.toString() ?? widget.menu['id']?.toString() ?? '';
      if (id.isEmpty) throw Exception('ID menu tidak ditemukan');

      // Use DataService.removeId to delete by id
      final success = await _data_service_removeIdSafe(id);
      if (success) {
        Fluttertoast.showToast(msg: "Menu '${widget.menu['nama_menu']}' berhasil dihapus!", backgroundColor: Colors.green);
        widget.onMenuDeleted?.call();
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        throw Exception('Hapus gagal');
      }
    } catch (e) {
      debugPrint('Error delete menu: $e');
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Gagal menghapus menu: ${e.toString()}", backgroundColor: Colors.red);
    }
  }

  Future<bool> _data_service_removeIdSafe(String id) async {
    try {
      final res = await _dataService.removeId(token, project, 'menu', appid, id);
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
          onMenuAdded: null,
          initialData: widget.menu,
          isEditing: true,
          onMenuUpdated: () {
            widget.onMenuUpdated?.call();
            // refresh UI if needed
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bahanList = _parseBahanBaku();
    final totalRecipe = _calculateTotalRecipeCost();
    final foodCost = _calculateFoodCost();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(widget.menu['nama_menu'] ?? '', style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image Header
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.green[300]!, width: 3)),
            child: widget.menu['foto_menu'] != null && widget.menu['foto_menu'].toString().isNotEmpty
                ? Image.network(widget.menu['foto_menu'], fit: BoxFit.cover, errorBuilder: (ctx, err, st) => const Icon(Icons.restaurant, size: 80, color: Colors.grey))
                : const Icon(Icons.restaurant, size: 80, color: Colors.grey),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.green[700]!, width: 3))),
                  child: Text('Detail', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                ),
              ),
              Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16), child: const Text('Riwayat', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)))),
            ]),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildDetailSection('Informasi Menu', Colors.green[700]!, [
                _buildDetailRow('Kode Menu', widget.menu['id_menu'] ?? '-', Colors.green[700]!),
                _buildDetailRow('Nama Menu', widget.menu['nama_menu'] ?? '-', Colors.green[700]!),
                _buildDetailRow('Kategori', widget.menu['kategori'] ?? '-', Colors.green[700]!),
                _buildDetailRow('Harga Jual', 'Rp ${_formatNumber(double.tryParse(widget.menu['harga_jual']?.toString() ?? widget.menu['harga']?.toString() ?? '0') ?? 0)}', Colors.green[700]!),
              ]),
              const SizedBox(height: 24),

              if (widget.menu['barcode'] != null && widget.menu['barcode'].toString().isNotEmpty) ...[
                Text('Barcode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    BarcodeWidget(barcode: Barcode.code128(), data: widget.menu['barcode'], width: 500, height: 100, drawText: false),
                    const SizedBox(height: 12),
                    Text(widget.menu['barcode'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[700], letterSpacing: 2)),
                  ]),
                ),
                const SizedBox(height: 24),
              ],

              _buildDetailSection('Ringkasan Perhitungan', Colors.green[700]!, [
                _buildDetailRow('Total Recipe Cost', 'Rp ${_formatNumber(totalRecipe)}', Colors.green[700]!),
                _buildDetailRow('Food Cost %', '${foodCost.toStringAsFixed(1)}%', Colors.green[700]!),
              ]),
              const SizedBox(height: 24),

              Text('Daftar Bahan Baku', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
              const Divider(thickness: 1),
              const SizedBox(height: 12),

              if (bahanList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                  child: Text('Tidak ada bahan baku', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                )
              else
                Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.orange[300]!, width: 2), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Container(
                      decoration: BoxDecoration(color: Colors.orange[700], borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(children: [
                        Expanded(flex: 1, child: Text('No', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(flex: 3, child: Text('Nama Bahan', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(flex: 2, child: Text('Jumlah', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                        Expanded(flex: 2, child: Text('Biaya', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))),
                      ]),
                    ),
                    ...bahanList.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final isEven = idx % 2 == 0;
                      return Container(
                        decoration: BoxDecoration(color: isEven ? Colors.white : Colors.grey[50]),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(children: [
                          Expanded(flex: 1, child: Text('${idx + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Expanded(flex: 3, child: Text(item['nama'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Expanded(flex: 2, child: Text('${item['jumlah']} ${item['satuan']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                          Expanded(flex: 2, child: Text('Rp${_formatNumber(double.tryParse(item['biaya']?.toString() ?? '0') ?? 0)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green[700]))),
                        ]),
                      );
                    }).toList(),
                  ]),
                ),

              const SizedBox(height: 30),

              Row(children: [
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _openEditForm,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4513), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Ubah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _deleteMenu,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Hapus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildDetailSection(String title, Color titleColor, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
      const Divider(thickness: 1),
      const SizedBox(height: 8),
      ...children,
    ]);
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor))),
      ]),
    );
  }
}