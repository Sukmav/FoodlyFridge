import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../config.dart';
import '../restapi.dart';
import '../helpers/image_helper.dart';
import '../model/bahan_baku_model.dart';
import '../model/menu_model.dart';

class AddMenuForm extends StatefulWidget {
  // onMenuAdded optional to support both add and edit callers
  const AddMenuForm({
    super.key,
    this.onMenuAdded,
    this.initialData,
    this.isEditing = false,
    this.onMenuUpdated,
  });

  final VoidCallback? onMenuAdded;
  final VoidCallback? onMenuUpdated;
  final Map<String, dynamic>? initialData;
  final bool isEditing;

  @override
  State<AddMenuForm> createState() => _AddMenuFormState();
}

class _AddMenuFormState extends State<AddMenuForm> {
  final DataService _dataService = DataService();

  final TextEditingController _kodeMenuController = TextEditingController();
  final TextEditingController _namaMenuController = TextEditingController();
  final TextEditingController _hargaJualController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _selectedKategori;
  File? _selectedImage;
  String? _selectedImagePath;

  List<BahanBakuModel> _availableBahanBaku = [];
  bool _isLoadingBahanBaku = false;

  // Each entry: { 'bahan': BahanBakuModel?, 'nama': String?, 'qty': TextEditingController, 'satuan': String, 'cost': double }
  List<Map<String, dynamic>> _selectedBahanBakuList = [];

  double _totalRecipeCost = 0.0;
  double _foodCostPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _hargaJualController.addListener(_recalculateTotals);
    _loadBahanBaku();
    if (widget.isEditing && widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillInitialData(widget.initialData!));
    }
  }

  void _fillInitialData(Map<String, dynamic> data) {
    try {
      _kodeMenuController.text = data['kode_menu']?.toString() ?? data['id_menu']?.toString() ?? '';
      _namaMenuController.text = data['nama_menu']?.toString() ?? '';
      _selectedKategori = data['kategori']?.toString();
      _hargaJualController.text = data['harga_jual']?.toString() ?? data['harga']?.toString() ?? '';
      _barcodeController.text = data['barcode']?.toString() ?? _kodeMenuController.text;
      _selectedImagePath = data['foto_menu']?.toString();

      _selectedBahanBakuList.clear();

      // Structured bahan_baku preferred
      final raw = data['bahan_baku'];
      if (raw != null) {
        List<dynamic> listRaw = [];
        if (raw is List) listRaw = raw;
        if (raw is String && raw.isNotEmpty) {
          try {
            final decoded = json.decode(raw);
            if (decoded is List) listRaw = decoded;
          } catch (_) {}
        }
        for (var it in listRaw) {
          final nama = it['nama_bahan']?.toString() ?? it['nama']?.toString() ?? '';
          final jumlah = it['jumlah']?.toString() ?? it['qty']?.toString() ?? '0';
          final unit = it['unit']?.toString() ?? '';
          final biaya = double.tryParse(it['biaya']?.toString() ?? '0') ?? 0.0;
          _selectedBahanBakuList.add({'bahan': null, 'nama': nama, 'qty': TextEditingController(text: jumlah), 'satuan': unit, 'cost': biaya});
        }
      } else {
        // fallback to comma-separated fields
        final bahanStr = data['bahan']?.toString() ?? '';
        if (bahanStr.isNotEmpty) {
          final jumlahStr = data['jumlah']?.toString() ?? '';
          final satuanStr = data['satuan']?.toString() ?? '';
          final biayaStr = data['biaya']?.toString() ?? '';

          final bahanList = bahanStr.split(',');
          final jumlahList = jumlahStr.split(',');
          final satuanList = satuanStr.split(',');
          final biayaList = biayaStr.split(',');

          for (int i = 0; i < bahanList.length; i++) {
            final nama = bahanList[i].trim();
            final jumlah = i < jumlahList.length ? jumlahList[i].trim() : '0';
            final satuan = i < satuanList.length ? satuanList[i].trim() : '';
            final biaya = i < biayaList.length ? double.tryParse(biayaList[i].trim()) ?? 0.0 : 0.0;
            _selectedBahanBakuList.add({'bahan': null, 'nama': nama, 'qty': TextEditingController(text: jumlah), 'satuan': satuan, 'cost': biaya});
          }
        }
      }

      _recalculateTotals();
      setState(() {});
    } catch (e) {
      debugPrint('Error filling initial data: $e');
    }
  }

  @override
  void dispose() {
    _kodeMenuController.dispose();
    _namaMenuController.dispose();
    _hargaJualController.dispose();
    _barcodeController.dispose();
    _catatanController.dispose();
    for (var it in _selectedBahanBakuList) {
      it['qty']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBahanBaku() async {
    setState(() => _isLoadingBahanBaku = true);
    try {
      final response = await _dataService.selectAll(token, project, 'bahan_baku', appid);

      if (response == '[]' || response.isEmpty || response == 'null') {
        setState(() {
          _availableBahanBaku = [];
          _isLoadingBahanBaku = false;
        });
        return;
      }

      final dynamic decoded = json.decode(response);
      List<dynamic> dataList;
      if (decoded is Map && decoded.containsKey('data')) {
        dataList = decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        dataList = decoded;
      } else {
        dataList = [];
      }

      final newList = dataList.map((j) => BahanBakuModel.fromJson(j)).toList();

      // match prefilled bahan by name
      for (var sel in _selectedBahanBakuList) {
        if (sel['bahan'] == null && sel['nama'] != null) {
          try {
            final match = newList.firstWhere((b) => (b.nama_bahan ?? b.nama ?? '').toString().toLowerCase() == sel['nama'].toString().toLowerCase());
            sel['bahan'] = match;
            sel['satuan'] = match.unit ?? sel['satuan'];
            final qty = double.tryParse(sel['qty']?.text ?? '0') ?? 0.0;
            final hargaUnit = double.tryParse(match.harga_per_unit ?? match.harga_unit ?? match.harga ?? '0') ?? 0.0;
            sel['cost'] = qty * hargaUnit;
          } catch (_) {
            // no match
          }
        }
      }

      setState(() {
        _availableBahanBaku = newList;
        _isLoadingBahanBaku = false;
      });
    } catch (e) {
      debugPrint('Error loading bahan baku: $e');
      setState(() {
        _availableBahanBaku = [];
        _isLoadingBahanBaku = false;
      });
    }
  }

  void _addBahanBaku() {
    setState(() {
      _selectedBahanBakuList.add({'bahan': null, 'nama': null, 'qty': TextEditingController(), 'satuan': '', 'cost': 0.0});
    });
  }

  void _removeBahanBaku(int index) {
    setState(() {
      _selectedBahanBakuList[index]['qty']?.dispose();
      _selectedBahanBakuList.removeAt(index);
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    double total = 0.0;
    for (var it in _selectedBahanBakuList) {
      final qty = double.tryParse(it['qty']?.text ?? '0') ?? 0.0;
      double cost = 0.0;
      if (it['bahan'] != null) {
        final BahanBakuModel b = it['bahan'];
        final hargaUnit = double.tryParse(b.harga_per_unit ?? b.harga_unit ?? b.harga ?? '0') ?? 0.0;
        cost = qty * hargaUnit;
      } else {
        cost = double.tryParse(it['cost']?.toString() ?? '0') ?? 0.0;
      }
      it['cost'] = cost;
      total += cost;
    }
    setState(() {
      _totalRecipeCost = total;
      _foodCostPercentage = _calculateFoodCostValue();
    });
  }

  double _calculateFoodCostValue() {
    final harga = double.tryParse(_hargaJualController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (harga > 0 && _totalRecipeCost > 0) return (_totalRecipeCost / harga) * 100;
    return 0.0;
  }

  Future<void> _pickImage() async {
    final file = await ImageHelper.showImageSourceDialog(context);
    if (file != null) {
      setState(() {
        _selectedImage = file;
        if (kIsWeb) _selectedImagePath = file.path;
      });
    }
  }

  Future<void> _saveMenu() async {
    // validations
    if (_kodeMenuController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Kode menu harus diisi!", backgroundColor: Colors.red);
      return;
    }
    if (_namaMenuController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Nama menu harus diisi!", backgroundColor: Colors.red);
      return;
    }
    if (_hargaJualController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Harga jual harus diisi!", backgroundColor: Colors.red);
      return;
    }

    // process image
    String imageUrl = '';
    if (_selectedImage != null) {
      try {
        Fluttertoast.showToast(msg: "Memproses gambar...", backgroundColor: Colors.blue);

        if (!kIsWeb) {
          final local = await ImageHelper.saveImageToAssets(_selectedImage!, _namaMenuController.text.replaceAll(' ', '_'));
          if (local != null && local.isNotEmpty) imageUrl = local;
        }

        final cloud = await ImageHelper.uploadImageToGoCloud(imageFile: _selectedImage!, token: token, project: project, fileName: _namaMenuController.text.replaceAll(' ', '_'));
        if (cloud != null && cloud.isNotEmpty) {
          imageUrl = cloud;
        } else {
          final base64 = await ImageHelper.convertImageToBase64(_selectedImage!);
          if (base64 != null && base64.isNotEmpty) imageUrl = base64;
        }
      } catch (e) {
        debugPrint('Error processing image: $e');
      }
    } else {
      if (widget.isEditing) {
        imageUrl = widget.initialData?['foto_menu']?.toString() ?? '';
      }
    }

    // build bahan lists and model bahan_baku
    final List<BahanBakuItem> bahanForModel = [];
    final List<String> bahanList = [];
    final List<String> jumlahList = [];
    final List<String> satuanList = [];
    final List<String> biayaList = [];

    for (var it in _selectedBahanBakuList) {
      final nama = it['bahan'] != null ? (it['bahan'].nama_bahan ?? it['bahan'].nama ?? '') : (it['nama']?.toString() ?? '');
      final qty = it['qty']?.text ?? '0';
      final satuan = it['bahan'] != null ? (it['bahan'].unit ?? '') : (it['satuan'] ?? '');
      final biaya = (it['cost'] is double) ? it['cost'] as double : double.tryParse((it['cost']?.toString() ?? '0')) ?? 0.0;

      if (nama.isNotEmpty) {
        bahanList.add(nama);
        jumlahList.add(qty);
        satuanList.add(satuan);
        biayaList.add(biaya.toString());

        bahanForModel.add(BahanBakuItem(id_bahan: it['bahan'] != null ? (it['bahan'].id?.toString() ?? '') : '', nama_bahan: nama, jumlah: qty, unit: satuan));
      }
    }

    final menuModel = MenuModel(
      id: widget.isEditing ? (widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?.toString() ?? '') : '',
      kode_menu: _kodeMenuController.text.trim(),
      nama_menu: _namaMenuController.text.trim(),
      kategori: _selectedKategori ?? (widget.initialData?['kategori']?.toString() ?? ''),
      harga: _hargaJualController.text.trim(),
      stok: widget.initialData?['stok']?.toString() ?? '0',
      bahan_baku: bahanForModel,
      foto_menu: imageUrl,
      barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : _kodeMenuController.text,
    );

    try {
      Fluttertoast.showToast(msg: widget.isEditing ? "Memperbarui menu..." : "Menyimpan menu...", backgroundColor: Colors.blue);

      if (widget.isEditing) {
        final id = widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?.toString() ?? '';
        if (id.isEmpty) throw Exception('ID menu tidak ditemukan untuk update');

        // Update allowed fields using DataService.updateId (one field per request)
        // Update nama_menu
        final okNama = await _dataService.updateId('nama_menu', menuModel.nama_menu, token, project, 'menu', appid, id);
        if (okNama != true) throw Exception('Gagal update nama_menu');

        // Update harga_jual
        final okHarga = await _dataService.updateId('harga_jual', menuModel.harga, token, project, 'menu', appid, id);
        if (okHarga != true) throw Exception('Gagal update harga_jual');

        // Update foto_menu (if provided)
        final okFoto = await _dataService.updateId('foto_menu', menuModel.foto_menu, token, project, 'menu', appid, id);
        if (okFoto != true) throw Exception('Gagal update foto_menu');

        // Update bahan_baku as JSON string (structured)
        final bahanBakuJson = json.encode(menuModel.bahan_baku.map((b) => {
          'id_bahan': b.id_bahan,
          'nama_bahan': b.nama_bahan,
          'jumlah': b.jumlah,
          'unit': b.unit,
        }).toList());
        final okBahanBaku = await _dataService.updateId('bahan_baku', bahanBakuJson, token, project, 'menu', appid, id);
        if (okBahanBaku != true) throw Exception('Gagal update bahan_baku');

        // Also update legacy comma-separated fields for compatibility
        final okBahan = await _dataService.updateId('bahan', bahanList.join(','), token, project, 'menu', appid, id);
        if (okBahan != true) throw Exception('Gagal update bahan (legacy)');

        final okJumlah = await _data_data_updateId_safe('jumlah', jumlahList.join(','));
        if (!okJumlah) throw Exception('Gagal update jumlah (legacy)');

        final okSatuan = await _data_data_updateId_safe('satuan', satuanList.join(','));
        if (!okSatuan) throw Exception('Gagal update satuan (legacy)');

        final okBiaya = await _data_data_updateId_safe('biaya', biayaList.join(','));
        if (!okBiaya) throw Exception('Gagal update biaya (legacy)');

        Fluttertoast.showToast(msg: "Menu berhasil diperbarui!", backgroundColor: Colors.green);
        widget.onMenuUpdated?.call();
      } else {
        // Insert via existing insert endpoint (DataService.insertMenu)
        await _dataService.insertMenu(appid, menuModel.kode_menu, menuModel.nama_menu, menuModel.foto_menu, menuModel.kategori, menuModel.harga, menuModel.barcode, bahanList.join(','), jumlahList.join(','), satuanList.join(','), biayaList.join(','), _catatanController.text);
        Fluttertoast.showToast(msg: "Menu berhasil ditambahkan!", backgroundColor: Colors.green);
        widget.onMenuAdded?.call();
      }

      if (Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving/updating menu: $e');
      Fluttertoast.showToast(msg: "Gagal menyimpan menu: ${e.toString()}", backgroundColor: Colors.red);
    }
  }

  // helper wrapper to call updateId and return bool safely
  Future<bool> _data_data_updateId_safe(String field, String value) async {
    try {
      final res = await _dataService.updateId(field, value, token, project, 'menu', appid, widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?.toString() ?? '');
      return res == true;
    } catch (e) {
      debugPrint('updateId $field error: $e');
      return false;
    }
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Ubah Menu' : 'Tambah Menu'), backgroundColor: Colors.green[700]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image / picker
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: Colors.green[700], borderRadius: BorderRadius.circular(16)),
                child: Stack(alignment: Alignment.center, children: [
                  if (_selectedImage != null && !kIsWeb)
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selectedImage!, width: 120, height: 120, fit: BoxFit.cover))
                  else if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty)
                    ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(_selectedImagePath!, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.camera_alt, size: 50, color: Colors.white.withOpacity(0.8))))
                  else
                    Icon(Icons.camera_alt, size: 50, color: Colors.white.withOpacity(0.8)),
                  Positioned(bottom: 10, right: 10, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.add_circle, color: Colors.green[700], size: 24))),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionTitle('Informasi Utama'),
          const SizedBox(height: 16),
          _buildTextField(controller: _kodeMenuController, label: 'Kode Menu', hint: 'Masukkan kode menu', enabled: !widget.isEditing),
          const SizedBox(height: 16),
          _buildTextField(controller: _namaMenuController, label: 'Nama menu', hint: 'Masukkan nama menu'),
          const SizedBox(height: 16),

          widget.isEditing ? _buildReadOnlyField(label: 'Kategori', value: _selectedKategori ?? (widget.initialData?['kategori']?.toString() ?? '-')) : _buildDropdownField(label: 'Kategori', value: _selectedKategori, items: ['Makanan', 'Minuman', 'Dessert', 'Snack'], onChanged: (v) => setState(() => _selectedKategori = v)),
          const SizedBox(height: 16),

          _buildTextField(controller: _hargaJualController, label: 'Harga Jual', hint: 'Masukkan harga jual', keyboardType: TextInputType.number),
          const SizedBox(height: 16),

          widget.isEditing ? _buildReadOnlyField(label: 'Barcode', value: _barcodeController.text.isNotEmpty ? _barcodeController.text : _kodeMenuController.text) : _buildTextField(controller: _barcodeController, label: 'Barcode (Opsional)', hint: 'Masukkan barcode'),
          const SizedBox(height: 30),

          _buildSectionTitle('Ringkasan Perhitungan'),
          const SizedBox(height: 16),
          _buildReadOnlyField(label: 'Total Recipe Cost (otomatis)', value: 'Rp${_formatNumber(_totalRecipeCost)}'),
          const SizedBox(height: 16),
          _buildReadOnlyField(label: 'Food Cost % (otomatis)', value: '${_foodCostPercentage.toStringAsFixed(1)}%'),
          const SizedBox(height: 30),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildSectionTitle('Daftar Bahan Baku'),
            ElevatedButton.icon(onPressed: _addBahanBaku, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah Bahan'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700])),
          ]),
          const SizedBox(height: 16),

          if (_isLoadingBahanBaku)
            const Center(child: CircularProgressIndicator())
          else if (_availableBahanBaku.isEmpty && _selectedBahanBakuList.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Belum ada bahan baku. Silakan tambahkan bahan baku terlebih dahulu.', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center)))
          else
            ..._selectedBahanBakuList.asMap().entries.map((e) => _buildBahanBakuCard(e.key)),

          const SizedBox(height: 30),

          if (!widget.isEditing) ...[
            _buildSectionTitle('Catatan Tambahan (Opsional)'),
            const SizedBox(height: 16),
            TextField(controller: _catatanController, maxLines: 4, decoration: InputDecoration(hintText: 'Tambahkan catatan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 30),
          ],

          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _saveMenu, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B4513), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan Menu', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[700]));

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, bool enabled = true, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(controller: controller, enabled: enabled, keyboardType: keyboardType, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]), filled: true, fillColor: enabled ? Colors.white : Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange[300]!)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
    ]);
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)), child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]))),
    ]);
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: value, decoration: InputDecoration(hintText: 'Pilih $label', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange[300]!))), items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(), onChanged: onChanged),
    ]);
  }

  Widget _buildBahanBakuCard(int index) {
    final it = _selectedBahanBakuList[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[300]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Bahan Baku ${index + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeBahanBaku(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
        const SizedBox(height: 12),
        _availableBahanBaku.isNotEmpty
            ? DropdownButtonFormField<BahanBakuModel>(
          value: it['bahan'],
          decoration: InputDecoration(hintText: 'Pilih bahan baku', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!))),
          items: _availableBahanBaku.map((b) {
            final nama = (b.nama_bahan ?? b.nama ?? '').toString();
            final unit = (b.unit ?? '').toString();
            final harga = (b.harga_per_unit ?? b.harga_unit ?? b.harga ?? '').toString();
            return DropdownMenuItem<BahanBakuModel>(value: b, child: Text('$nama ($unit) - Rp$harga'));
          }).toList(),
          onChanged: (BahanBakuModel? val) {
            setState(() {
              it['bahan'] = val;
              it['nama'] = val != null ? (val.nama_bahan ?? val.nama ?? '') : it['nama'];
              it['satuan'] = val?.unit ?? it['satuan'];
              _recalculateTotals();
            });
          },
        )
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Nama Bahan', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(controller: TextEditingController(text: it['nama']?.toString() ?? ''), onChanged: (v) => it['nama'] = v, decoration: InputDecoration(hintText: 'Masukkan nama bahan', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(flex: 2, child: TextField(controller: it['qty'], keyboardType: TextInputType.number, onChanged: (v) => _recalculateTotals(), decoration: InputDecoration(labelText: 'Qty', labelStyle: const TextStyle(fontSize: 12), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), child: Text(it['satuan'] ?? '-', style: const TextStyle(fontSize: 14)))),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), child: Text('Rp${_formatNumber((it['cost'] as double?) ?? 0.0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))),
        ]),
      ]),
    );
  }
}