import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../restapi.dart';
import '../model/bahan_baku_model.dart';
import '../model/menu_model.dart';

class AddMenuForm extends StatefulWidget {
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

  String?  _selectedKategori;
  File? _selectedImage;
  String? _fotoBase64;

  List<BahanBakuModel> _availableBahanBaku = [];
  bool _isLoadingBahanBaku = false;

  List<Map<String, dynamic>> _selectedBahanBakuList = [];
  double _totalRecipeCost = 0.0;
  double _foodCostPercentage = 0.0;

  // Gradient Colors
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6A11CB),
      Color(0xFF2575FC),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment. topLeft,
    end:  Alignment.bottomRight,
    colors: [
      Color(0xFF9C4DFF),
      Color(0xFF7B2CBF),
      Color(0xFF5A189A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _hargaJualController.addListener(_recalculateTotals);
    _loadBahanBaku();
    if (widget.isEditing && widget.initialData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillInitialData(widget.initialData! ));
    }
  }

  void _fillInitialData(Map<String, dynamic> data) {
    try {
      _kodeMenuController.text = data['kode_menu']?.toString() ?? data['id_menu']?.toString() ?? '';
      _namaMenuController.text = data['nama_menu']?.toString() ?? '';
      _selectedKategori = data['kategori']?.toString();
      _hargaJualController.text = data['harga_jual']?.toString() ?? data['harga']?.toString() ?? '';
      _barcodeController.text = data['barcode']?.toString() ?? _kodeMenuController.text;
      _fotoBase64 = data['foto_menu']?.toString();

      _selectedBahanBakuList. clear();

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
          _selectedBahanBakuList.add({
            'bahan':  null,
            'nama':  nama,
            'qty': TextEditingController(text: jumlah),
            'satuan': unit,
            'cost': biaya
          });
        }
      } else {
        final bahanStr = data['bahan']?.toString() ?? '';
        if (bahanStr. isNotEmpty) {
          final jumlahStr = data['jumlah']?.toString() ?? '';
          final satuanStr = data['satuan']?.toString() ?? '';
          final biayaStr = data['biaya']?.toString() ?? '';

          final bahanList = bahanStr.split(',');
          final jumlahList = jumlahStr.split(',');
          final satuanList = satuanStr.split(',');
          final biayaList = biayaStr.split(',');

          for (int i = 0; i < bahanList.length; i++) {
            final nama = bahanList[i].trim();
            final jumlah = i < jumlahList.length ?  jumlahList[i].trim() : '0';
            final satuan = i < satuanList.length ? satuanList[i].trim() : '';
            final biaya = i < biayaList.length ?  double.tryParse(biayaList[i].trim()) ?? 0.0 : 0.0;
            _selectedBahanBakuList.add({
              'bahan': null,
              'nama': nama,
              'qty': TextEditingController(text: jumlah),
              'satuan': satuan,
              'cost': biaya
            });
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

      if (response == '[]' || response. isEmpty || response == 'null') {
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

      for (var sel in _selectedBahanBakuList) {
        if (sel['bahan'] == null && sel['nama'] != null) {
          try {
            final match = newList.firstWhere((b) =>
            (b.nama_bahan ??  b.nama ??  '').toString().toLowerCase() == sel['nama'].toString().toLowerCase());
            sel['bahan'] = match;
            sel['satuan'] = match.unit ??  sel['satuan'];
            final qty = double.tryParse(sel['qty']?.text ?? '0') ?? 0.0;
            final hargaUnit = double.tryParse(match.harga_per_unit ??  match.harga_unit ?? match.harga ??  '0') ?? 0.0;
            sel['cost'] = qty * hargaUnit;
          } catch (_) {}
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
      _selectedBahanBakuList. add({
        'bahan':  null,
        'nama': null,
        'qty': TextEditingController(),
        'satuan': '',
        'cost': 0.0
      });
    });
  }

  void _removeBahanBaku(int index) {
    setState(() {
      _selectedBahanBakuList[index]['qty']?.dispose();
      _selectedBahanBakuList. removeAt(index);
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
    final harga = double.tryParse(_hargaJualController.text. replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    if (harga > 0 && _totalRecipeCost > 0) return (_totalRecipeCost / harga) * 100;
    return 0.0;
  }

  // Function untuk pick image dari camera
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
        final imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();

        setState(() {
          _selectedImage = imageFile;
          _fotoBase64 = base64Encode(bytes);
        });

        Fluttertoast.showToast(
          msg: "Foto berhasil diambil",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error mengambil foto: $e');
      Fluttertoast.showToast(
        msg: "Gagal mengambil foto:  $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // Function untuk pick image dari gallery
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
        final imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();

        setState(() {
          _selectedImage = imageFile;
          _fotoBase64 = base64Encode(bytes);
        });

        Fluttertoast.showToast(
          msg: "Foto berhasil dipilih",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error memilih gambar: $e');
      Fluttertoast.showToast(
        msg: "Gagal memilih gambar:  $e",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _saveMenu() async {
    // Validasi input
    if (_kodeMenuController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Kode menu harus diisi!", backgroundColor: Colors.red);
      return;
    }
    if (_namaMenuController. text.isEmpty) {
      Fluttertoast.showToast(msg: "Nama menu harus diisi!", backgroundColor: Colors.red);
      return;
    }
    if (_hargaJualController.text. isEmpty) {
      Fluttertoast.showToast(msg: "Harga jual harus diisi!", backgroundColor: Colors.red);
      return;
    }

    // Show loading state
    bool isLoading = false;
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      // Gunakan foto base64 yang sudah ada atau foto lama
      String imageUrl = _fotoBase64 ?? '';

      if (imageUrl.isEmpty && widget.isEditing) {
        imageUrl = widget.initialData? ['foto_menu']?.toString() ?? '';
      }

      final List<BahanBakuItem> bahanForModel = [];
      final List<String> bahanList = [];
      final List<String> jumlahList = [];
      final List<String> satuanList = [];
      final List<String> biayaList = [];

      for (var it in _selectedBahanBakuList) {
        final nama = it['bahan'] != null ? (it['bahan']. nama_bahan ?? it['bahan']. nama ?? '') : (it['nama']?.toString() ?? '');
        final qty = it['qty']?.text ??  '0';
        final satuan = it['bahan'] != null ? (it['bahan'].unit ?? '') : (it['satuan'] ?? '');
        final biaya = (it['cost'] is double) ? it['cost'] as double : double.tryParse((it['cost']?.toString() ?? '0')) ?? 0.0;

        if (nama.isNotEmpty) {
          bahanList.add(nama);
          jumlahList. add(qty);
          satuanList.add(satuan);
          biayaList.add(biaya.toString());

          bahanForModel.add(BahanBakuItem(
              id_bahan: it['bahan'] != null ? (it['bahan'].id?. toString() ?? '') : '',
              nama_bahan: nama,
              jumlah: qty,
              unit: satuan
          ));
        }
      }

      final menuModel = MenuModel(
        id:  widget.isEditing ? (widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?. toString() ?? '') : '',
        kode_menu: _kodeMenuController.text. trim(),
        nama_menu: _namaMenuController.text.trim(),
        kategori: _selectedKategori ??  (widget.initialData?['kategori']?.toString() ?? ''),
        harga:  _hargaJualController. text.trim(),
        stok: widget.initialData?['stok']?.toString() ?? '0',
        bahan_baku: bahanForModel,
        foto_menu: imageUrl,
        barcode: _barcodeController. text.isNotEmpty ? _barcodeController.text : _kodeMenuController.text,
      );

      // Show saving toast
      Fluttertoast.showToast(
        msg: widget.isEditing ? "Memperbarui menu..." : "Menyimpan menu.. .",
        backgroundColor: Colors.blue,
        toastLength: Toast.LENGTH_SHORT,
      );

      bool success = false;

      if (widget.isEditing) {
        final id = widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?.toString() ?? '';
        if (id.isEmpty) throw Exception('ID menu tidak ditemukan untuk update');

        final okNama = await _dataService.updateId('nama_menu', menuModel.nama_menu, token, project, 'menu', appid, id);
        if (okNama != true) throw Exception('Gagal update nama_menu');

        final okHarga = await _dataService.updateId('harga_jual', menuModel.harga, token, project, 'menu', appid, id);
        if (okHarga != true) throw Exception('Gagal update harga_jual');

        final okFoto = await _dataService.updateId('foto_menu', menuModel.foto_menu, token, project, 'menu', appid, id);
        if (okFoto != true) throw Exception('Gagal update foto_menu');

        final bahanBakuJson = json.encode(menuModel.bahan_baku. map((b) => {
          'id_bahan': b. id_bahan,
          'nama_bahan': b.nama_bahan,
          'jumlah': b.jumlah,
          'unit': b. unit,
        }).toList());
        final okBahanBaku = await _dataService.updateId('bahan_baku', bahanBakuJson, token, project, 'menu', appid, id);
        if (okBahanBaku != true) throw Exception('Gagal update bahan_baku');

        final okBahan = await _dataService.updateId('bahan', bahanList. join(','), token, project, 'menu', appid, id);
        if (okBahan != true) throw Exception('Gagal update bahan (legacy)');

        final okJumlah = await _data_data_updateId_safe('jumlah', jumlahList.join(','));
        if (! okJumlah) throw Exception('Gagal update jumlah (legacy)');

        final okSatuan = await _data_data_updateId_safe('satuan', satuanList. join(','));
        if (!okSatuan) throw Exception('Gagal update satuan (legacy)');

        final okBiaya = await _data_data_updateId_safe('biaya', biayaList.join(','));
        if (!okBiaya) throw Exception('Gagal update biaya (legacy)');

        success = true;
      } else {
        await _dataService.insertMenu(
            appid,
            menuModel.kode_menu,
            menuModel.nama_menu,
            menuModel. foto_menu,
            menuModel. kategori,
            menuModel.harga,
            menuModel.barcode,
            bahanList.join(','),
            jumlahList.join(','),
            satuanList.join(','),
            biayaList.join(','),
            _catatanController.text
        );
        success = true;
      }

      if (success) {
        // Panggil callback untuk update parent
        if (widget.isEditing) {
          widget.onMenuUpdated?. call();
        } else {
          widget.onMenuAdded?.call();
        }

        // Tampilkan sukses toast
        Fluttertoast.showToast(
          msg: widget.isEditing ? "✅ Menu berhasil diperbarui!" : "✅ Menu berhasil ditambahkan!",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
        );

        // Tunggu sebentar agar toast terlihat
        await Future.delayed(const Duration(milliseconds: 500));

        // Kembali ke halaman sebelumnya
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving/updating menu: $e');
      Fluttertoast.showToast(
        msg: "❌ Gagal menyimpan menu: ${e.toString()}",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> _data_data_updateId_safe(String field, String value) async {
    try {
      final res = await _dataService.updateId(field, value, token, project, 'menu', appid, widget.initialData?['_id']?.toString() ?? widget.initialData?['id']?. toString() ?? '');
      return res == true;
    } catch (e) {
      debugPrint('updateId $field error: $e');
      return false;
    }
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  // Method untuk menampilkan gambar dari base64
  Widget _buildImageFromBase64(String base64String) {
    try {
      final cleanBase64 = base64String. contains(',') ? base64String.split(',').last : base64String;

      return Image.memory(
        base64Decode(cleanBase64),
        width: 200,
        height: 200,
        fit:  BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment. bottomRight,
              ),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, size: 70, color: Colors.white),
          );
        },
      );
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors:  [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.restaurant_menu_rounded, size: 70, color: Colors.white),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius:  8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType?  keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      margin: const EdgeInsets. only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height:  8),
          Container(
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller:  controller,
              enabled: enabled,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: 'Masukkan $label',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: prefixIcon != null ?  Icon(prefixIcon, color:  Colors.grey[600]) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String?  value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets. only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height:  8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
              border:  Border.all(color: Colors. grey[200]!),
            ),
            child:  Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value:  value,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Pilih $label',
                  prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
                ),
                items: items
                    .map((it) => DropdownMenuItem(
                  value: it,
                  child: Text(it, style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
                onChanged: onChanged,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummaryCard() {
    return Container(
      margin: const EdgeInsets. only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Colors.grey. withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets. all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width:  12),
                const Text(
                  'Ringkasan Perhitungan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors. black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0f7ff),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Total Recipe Cost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rp ${_formatNumber(_totalRecipeCost)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFf0fff4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[100]! ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child:  Column(
                      children: [
                        Text(
                          'Food Cost',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_foodCostPercentage. toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBahanBakuCard(int index) {
    final it = _selectedBahanBakuList[index];

    return Container(
      margin:  const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:  Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Padding(
        padding: const EdgeInsets. all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:  [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical:  6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Bahan ${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors. orange[700],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 24),
                  onPressed: () => _removeBahanBaku(index),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bahan Selection
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius:  BorderRadius.circular(12),
              ),
              child: _availableBahanBaku. isNotEmpty
                  ? DropdownButtonFormField<BahanBakuModel>(
                value: it['bahan'],
                decoration: InputDecoration(
                  hintText: 'Pilih bahan baku',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.shopping_basket_rounded, color: Colors.grey[600]),
                ),
                items: _availableBahanBaku.map((b) {
                  final nama = (b.nama_bahan ?? b.nama ??  '').toString();
                  final unit = (b.unit ?? '').toString();
                  final harga = (b.harga_per_unit ?? b.harga_unit ?? b.harga ??  '').toString();
                  return DropdownMenuItem<BahanBakuModel>(
                    value: b,
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('$unit • Rp$harga', style: TextStyle(fontSize: 12, color: Colors. grey[600])),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    it['bahan'] = val;
                    it['nama'] = val != null ? (val.nama_bahan ?? val.nama ?? '') : it['nama'];
                    it['satuan'] = val?. unit ?? it['satuan'];
                    _recalculateTotals();
                  });
                },
              )
                  :  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: TextEditingController(text: it['nama']?.toString() ?? ''),
                  onChanged: (v) => it['nama'] = v,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nama bahan',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Quantity and Cost
            Row(
              children:  [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius. circular(12),
                    ),
                    child: TextField(
                      controller: it['qty'],
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _recalculateTotals(),
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        labelStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      it['satuan'] ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[50]!, Colors.lightGreen[50]!],
                        begin: Alignment.topLeft,
                        end:  Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Text(
                      'Rp${_formatNumber((it['cost'] as double?) ?? 0.0)}',
                      style:  TextStyle(
                        fontSize:  14,
                        fontWeight: FontWeight.bold,
                        color: Colors. green[900],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leading: IconButton(
          icon:  const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Ubah Menu' : 'Tambah Menu Baru',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:  const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.1),
                            blurRadius:  20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _selectedImage != null && ! kIsWeb
                            ? Image. file(_selectedImage!, width: 200, height: 200, fit: BoxFit.cover)
                            : _fotoBase64 != null && _fotoBase64! .isNotEmpty
                            ?  _buildImageFromBase64(_fotoBase64!)
                            : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.topLeft,
                              end:  Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.restaurant_menu_rounded, size: 70, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton. icon(
                          onPressed:  _pickImageFromCamera,
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Kamera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width:  12),
                        ElevatedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library, size: 20),
                          label: const Text('Galeri'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF764ba2),
                            foregroundColor: Colors. white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius. circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Informasi Utama
              _buildSectionHeader('Informasi Utama', Icons.info_outline_rounded),

              _buildInputField(
                label: 'Kode Menu',
                controller: _kodeMenuController,
                enabled: ! widget.isEditing,
                prefixIcon: Icons.qr_code_2_rounded,
              ),

              _buildInputField(
                label: 'Nama Menu',
                controller: _namaMenuController,
                prefixIcon: Icons.restaurant_rounded,
              ),

              widget.isEditing
                  ?  Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:  Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_rounded, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:  CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kategori',
                            style:  TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedKategori ??  (widget.initialData? ['kategori']?.toString() ?? '-'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : _buildDropdownField(
                label: 'Kategori',
                value: _selectedKategori,
                items: ['Makanan', 'Minuman', 'Dessert', 'Snack'],
                onChanged: (v) => setState(() => _selectedKategori = v),
                icon: Icons.category_rounded,
              ),

              _buildInputField(
                label: 'Harga Jual',
                controller: _hargaJualController,
                keyboardType: TextInputType. number,
                prefixIcon:  Icons.attach_money_rounded,
              ),

              widget.isEditing
                  ?  Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment. start,
                        children: [
                          Text(
                            'Barcode',
                            style:  TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _barcodeController.text.isNotEmpty ? _barcodeController.text : _kodeMenuController.text,
                            style: const TextStyle(fontSize: 16, fontWeight:  FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : _buildInputField(
                label: 'Barcode (Opsional)',
                controller:  _barcodeController,
                prefixIcon: Icons.qr_code_2_rounded,
              ),

              // Ringkasan Perhitungan
              _buildCostSummaryCard(),

              // Daftar Bahan Baku
              _buildSectionHeader('Daftar Bahan Baku', Icons. shopping_basket_rounded),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: buttonGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C4DFF).withOpacity(0.3),
                              blurRadius:  8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ElevatedButton. icon(
                          onPressed:  _addBahanBaku,
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          label: const Text('Tambah Bahan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoadingBahanBaku)
                const Center(child: CircularProgressIndicator())
              else if (_availableBahanBaku.isEmpty && _selectedBahanBakuList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border. all(color: Colors.grey[200]!, style: BorderStyle.solid, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 60, color:  Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada bahan baku',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight. w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan bahan baku dengan tombol di atas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors. grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Daftar bahan baku cards - PERBAIKAN DI SINI
              for (int i = 0; i < _selectedBahanBakuList. length; i++)
                _buildBahanBakuCard(i),

              // Catatan Tambahan (hanya untuk add, tidak untuk edit)
              if (!widget.isEditing)
                _buildSectionHeader('Catatan Tambahan', Icons.notes_rounded),
              if (! widget.isEditing)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius:  10,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _catatanController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tambahkan catatan atau deskripsi menu.. .',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              if (!widget.isEditing) const SizedBox(height: 30),

              // Save Button
              Container(
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
                    begin: Alignment.topLeft,
                    end: Alignment. bottomRight,
                  ),
                  borderRadius: BorderRadius. circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B4513).withOpacity(0.3),
                      blurRadius:  8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        widget.isEditing ? 'Simpan Perubahan' : 'Simpan Menu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors. white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}