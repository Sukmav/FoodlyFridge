import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../model/waste_food.dart';
import '../model/bahan_baku_model.dart';
import '../restapi.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:flutter/foundation.dart';

class WasteFoodPage extends StatefulWidget {
  final String userId;
  final String userName;

  const WasteFoodPage({
    super.key,
    required this. userId,
    required this.userName,
  });

  @override
  State<WasteFoodPage> createState() => _WasteFoodPageState();
}

class _WasteFoodPageState extends State<WasteFoodPage> {
  final DataService _dataService = DataService();
  List<WasteFoodModel> _wasteList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWasteFood();
  }

  Future<void> _loadWasteFood() async {
    setState(() => _isLoading = true);

    try {
      final response = await _dataService.selectAll(token, project, 'waste_food', appid);

      if (response == null || response == '[]' || response. isEmpty || response == 'null') {
        if (mounted) {
          setState(() {
            _wasteList = [];
            _isLoading = false;
          });
        }
        return;
      }

      dynamic decodedData;
      try {
        decodedData = json.decode(response);
      } catch (e) {
        if (mounted) {
          setState(() {
            _wasteList = [];
            _isLoading = false;
          });
        }
        return;
      }

      List<dynamic> dataList = [];

      if (decodedData is Map) {
        if (decodedData. containsKey('data')) {
          var dataValue = decodedData['data'];
          if (dataValue is List) {
            dataList = dataValue;
          } else if (dataValue != null) {
            dataList = [dataValue];
          }
        } else if (decodedData.containsKey('result')) {
          var resultValue = decodedData['result'];
          if (resultValue is List) {
            dataList = resultValue;
          } else if (resultValue != null) {
            dataList = [resultValue];
          }
        } else {
          dataList = [decodedData];
        }
      } else if (decodedData is List) {
        dataList = decodedData;
      }

      List<WasteFoodModel> allWasteList = [];
      for (var i = 0; i < dataList.length; i++) {
        try {
          var item = dataList[i];

          if (item is Map<String, dynamic>) {
            var wasteModel = WasteFoodModel.fromJson(item);
            allWasteList.add(wasteModel);
          } else if (item is Map) {
            var convertedMap = Map<String, dynamic>.from(item);
            var wasteModel = WasteFoodModel.fromJson(convertedMap);
            allWasteList.add(wasteModel);
          }
        } catch (e) {
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _wasteList = allWasteList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wasteList = [];
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAddWasteFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahWasteFoodPage(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );

    if (result == true) {
      await _loadWasteFood();
    }
  }

  void _navigateToDetail(WasteFoodModel waste) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasteFoodDetailPage(
          waste: waste,
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
    );

    if (result == true) {
      await _loadWasteFood();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ?  const Center(child: CircularProgressIndicator())
            : _wasteList.isEmpty
            ? _buildEmptyState()
            : _buildWasteList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddWasteFood,
        backgroundColor: const Color(0xFF7A9B3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 120, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text('Belum Ada Data Waste Food', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Tambahkan data untuk memulai', style: GoogleFonts.poppins(fontSize: 14, color: Colors. grey[500])),
        ],
      ),
    );
  }

  Widget _buildWasteList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _wasteList.length,
      itemBuilder: (context, index) {
        final waste = _wasteList[index];
        return _buildWasteCard(waste);
      },
    );
  }

  Widget _buildWasteCard(WasteFoodModel waste) {
    return InkWell(
      onTap: () => _navigateToDetail(waste),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWasteIcon(waste),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(waste.nama_bahan. isNotEmpty ? waste.nama_bahan : 'Unknown', style: GoogleFonts. poppins(fontSize: 17, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${waste.jenis_waste.isNotEmpty ? waste.jenis_waste : 'Kadaluarsa'} • ${_formatTanggal(waste.tanggal)}', style: GoogleFonts. poppins(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w400)),
                  const SizedBox(height: 8),
                  Text('${waste.jumlah_terbuang.isNotEmpty ? waste. jumlah_terbuang :  '-'} | Kerugian:  ${_formatRupiah(waste.total_kerugian)}', style: GoogleFonts.poppins(fontSize: 13, color:  Colors.grey[700], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteIcon(WasteFoodModel waste) {
    return Container(
      width:  64,
      height: 64,
      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFD54F), width: 2)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: waste.foto. isNotEmpty ?  _buildImageWidget(waste.foto) : Icon(Icons.delete_outline, size: 32, color: Colors. orange[700]),
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.isEmpty) return Icon(Icons.image_not_supported, size: 32, color: Colors.grey[400]);

    try {
      if (imagePath.length > 100 && ! imagePath.startsWith('http')) {
        final base64String = imagePath.contains(',') ? imagePath.split(',').last : imagePath;
        try {
          return Image.memory(base64Decode(base64String), fit: BoxFit.cover, width: 64, height: 64, errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 32, color: Colors.grey[400]));
        } catch (e) {
          return Icon(Icons.broken_image, size: 32, color: Colors. grey[400]);
        }
      }

      if (imagePath.startsWith('http')) {
        return Image.network(imagePath, fit: BoxFit.cover, width: 64, height: 64, errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 32, color: Colors.grey[400]));
      }

      return Icon(Icons.image, size: 32, color:  Colors.grey[400]);
    } catch (e) {
      return Icon(Icons.broken_image, size: 32, color:  Colors.grey[400]);
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      if (tanggal.isEmpty) return '-';
      DateTime date;
      if (tanggal.contains('-')) {
        date = DateTime. parse(tanggal. split(' ')[0]);
      } else if (tanggal.contains('/')) {
        final parts = tanggal.split('/');
        if (parts.length == 3) {
          date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return tanggal;
        }
      } else {
        return tanggal;
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return tanggal. isEmpty ? '-' : tanggal;
    }
  }

  String _formatRupiah(String jumlah) {
    try {
      if (jumlah. isEmpty) return 'Rp 0';
      final cleanNumber = jumlah.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanNumber.isEmpty) return 'Rp 0';
      final angka = int.parse(cleanNumber);
      final formatter = NumberFormat('#,###', 'id_ID');
      return 'Rp ${formatter.format(angka)}';
    } catch (e) {
      return 'Rp 0';
    }
  }
}

// ==================== TAMBAH WASTE FOOD PAGE ====================
class TambahWasteFoodPage extends StatefulWidget {
  final String userId;
  final String userName;

  const TambahWasteFoodPage({super.key, required this.userId, required this.userName});

  @override
  State<TambahWasteFoodPage> createState() => _TambahWasteFoodPageState();
}

class _TambahWasteFoodPageState extends State<TambahWasteFoodPage> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();
  final TextEditingController _jumlahTerbuangController = TextEditingController();
  final TextEditingController _totalKerugianController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  BahanBakuModel? _selectedBahanBaku;
  String? _selectedJenisWaste;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  String? _fotoBase64;
  bool _isLoading = false;
  List<BahanBakuModel> _bahanBakuList = [];

  final List<String> _jenisWasteOptions = ['Expired', 'Rusak', 'Busuk', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    _loadBahanBaku();
    _totalKerugianController.text = 'Rp 0';
  }

  @override
  void dispose() {
    _jumlahTerbuangController.dispose();
    _totalKerugianController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadBahanBaku() async {
    setState(() => _isLoading = true);

    try {
      final response = await _dataService.selectAll(token, project, 'bahan_baku', appid);

      if (response == '[]' || response. isEmpty || response == 'null') {
        if (mounted) {
          setState(() {
            _bahanBakuList = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data bahan baku.  Tambahkan bahan baku terlebih dahulu di menu Bahan Baku. '), backgroundColor: Colors.orange, duration: Duration(seconds: 5)));
        }
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

      final bahanBakuList = dataList.map((json) => BahanBakuModel.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _bahanBakuList = bahanBakuList;
          _isLoading = false;
        });
        if (bahanBakuList. isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Belum ada data bahan baku.  Tambahkan bahan baku terlebih dahulu di menu Bahan Baku.'), backgroundColor: Colors.orange, duration: Duration(seconds: 5)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bahanBakuList = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data bahan baku: $e'), backgroundColor: Colors. red, duration: const Duration(seconds: 5)));
      }
    }
  }

  void _onBahanBakuSelected(BahanBakuModel?  bahanBaku) {
    setState(() {
      _selectedBahanBaku = bahanBaku;
      if (bahanBaku != null) {
        _jumlahTerbuangController.clear();
        _calculateTotalKerugian();
      } else {
        _jumlahTerbuangController.clear();
        _totalKerugianController.text = 'Rp 0';
      }
    });
  }

  void _calculateTotalKerugian() {
    if (_selectedBahanBaku != null && _jumlahTerbuangController. text.isNotEmpty) {
      try {
        final jumlahTerbuang = double.parse(_jumlahTerbuangController.text. replaceAll(',', '').replaceAll('. ', ''));
        final hargaPerUnit = double.parse(_selectedBahanBaku!.harga_per_unit);
        final totalKerugian = jumlahTerbuang * hargaPerUnit;
        setState(() {
          _totalKerugianController.text = 'Rp ${NumberFormat('#,###', 'id_ID').format(totalKerugian)}';
        });
      } catch (e) {
        setState(() {
          _totalKerugianController.text = 'Rp 0';
        });
      }
    } else {
      setState(() {
        _totalKerugianController.text = 'Rp 0';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        final bytes = await _selectedImage!.readAsBytes();
        _fotoBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        final bytes = await _selectedImage!.readAsBytes();
        _fotoBase64 = base64Encode(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(SnackBar(content:  Text('Gagal memilih gambar: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF7A9B3B))), child: child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _simpanWasteFood() async {
    if (! _formKey.currentState!. validate()) return;
    if (_selectedBahanBaku == null) {
      ScaffoldMessenger. of(context).showSnackBar(const SnackBar(content: Text('Pilih bahan baku terlebih dahulu')));
      return;
    }
    if (_selectedJenisWaste == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih jenis waste terlebih dahulu')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jumlahTerbuang = double.parse(_jumlahTerbuangController.text);
      final hargaPerUnit = double.parse(_selectedBahanBaku! .harga_per_unit);
      final totalKerugian = jumlahTerbuang * hargaPerUnit;

      // 1. INSERT WASTE FOOD
      final response = await http.post(Uri.parse('$fileUri/insert/'), body: {
        'token': token,
        'project':  project,
        'collection':  'waste_food',
        'appid': appid,
        'user_id': widget.userId,
        'nama_bahan': _selectedBahanBaku! .nama_bahan,
        'jenis_waste': _selectedJenisWaste!,
        'jumlah_terbuang': '${_jumlahTerbuangController. text} ${_selectedBahanBaku!.unit}',
        'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'catatan': _catatanController. text. isEmpty ? '-' : _catatanController. text,
        'foto': _fotoBase64 ??  '',
        'total_kerugian': totalKerugian.toStringAsFixed(0),
        'kode_bahan':  _selectedBahanBaku! .id,
      });

      if (response.statusCode == 200) {
        // 2. UPDATE STOK BAHAN BAKU
        try {
          final stokParts = _selectedBahanBaku!. stok_tersedia.split(' ');
          double stokSekarang = 0;
          String unitStok = _selectedBahanBaku!. unit;

          if (stokParts.isNotEmpty) {
            stokSekarang = double.tryParse(stokParts[0]. replaceAll(',', '')) ?? 0;
            if (stokParts.length > 1) unitStok = stokParts[1];
          }

          final stokBaru = stokSekarang - jumlahTerbuang;
          final stokAkhir = stokBaru < 0 ? 0 :  stokBaru;
          final stokBaruFormatted = '$stokAkhir $unitStok';

          if (kDebugMode) {
            print('========== UPDATE STOK BAHAN BAKU ==========');
            print('Bahan:  ${_selectedBahanBaku!.nama_bahan}');
            print('Stok Sekarang: $stokSekarang $unitStok');
            print('Jumlah Terbuang: $jumlahTerbuang $unitStok');
            print('Stok Baru: $stokAkhir $unitStok');
          }

          if (_selectedBahanBaku!. id. isNotEmpty) {
            await _dataService.updateId('stok_tersedia', stokBaruFormatted, token, project, 'bahan_baku', appid, _selectedBahanBaku! .id);
          } else {
            await _dataService.updateWhere('nama_bahan', _selectedBahanBaku!.nama_bahan, 'stok_tersedia', stokBaruFormatted, token, project, 'bahan_baku', appid);
          }

          if (kDebugMode) print('✅ Stok berhasil diupdate');
        } catch (e) {
          if (kDebugMode) print('⚠️ Gagal update stok (tapi waste food tetap tersimpan): $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data waste food berhasil ditambahkan dan stok diperbarui'), backgroundColor: Colors.green));
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data:  ${response.statusCode}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi kesalahan:  $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)), title: Text('Tambah Data', style: GoogleFonts.poppins(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.w600))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Detail Waste', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFD4A373))),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),
            Text('Nama Bahan Baku', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _isLoading
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8), color: Colors.grey[100]), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Loading...', style: GoogleFonts.poppins(color: Colors.grey)), const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))]))
                : Container(padding:  const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4A373)), borderRadius: BorderRadius. circular(8), color: Colors.white), child: DropdownButtonHideUnderline(child:  DropdownButton<BahanBakuModel>(value: _selectedBahanBaku, isExpanded: true, hint: Text(_bahanBakuList.isEmpty ? 'Tidak ada data bahan baku' : 'Pilih Bahan Baku', style:  GoogleFonts.poppins(color: _bahanBakuList.isEmpty ? Colors.red : const Color(0xFFD4A373))), icon: Icon(Icons.keyboard_arrow_down, color: _bahanBakuList.isEmpty ? Colors.grey : const Color(0xFFD4A373)), style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14), items: _bahanBakuList.isEmpty ? null : _bahanBakuList.map((BahanBakuModel bahanBaku) => DropdownMenuItem<BahanBakuModel>(value: bahanBaku, child: Text(bahanBaku. nama_bahan, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)))).toList(), onChanged: _bahanBakuList.isEmpty ? null : _onBahanBakuSelected))),
            const SizedBox(height: 16),
            Text('Jenis Waste', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border:  Border.all(color: const Color(0xFFD4A373)), borderRadius: BorderRadius.circular(8)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedJenisWaste, isExpanded: true, hint: Text('Pilih Jenis Waste', style: GoogleFonts. poppins(color: const Color(0xFFD4A373))), icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4A373)), style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14), items: _jenisWasteOptions.map((String jenis) => DropdownMenuItem<String>(value: jenis, child: Text(jenis))).toList(), onChanged: (String? newValue) => setState(() => _selectedJenisWaste = newValue)))),
            const SizedBox(height: 16),
            Text('Jumlah Terbuang${_selectedBahanBaku != null ? ' (${_selectedBahanBaku!.unit})' : ''}', style: GoogleFonts.poppins(fontSize: 14, fontWeight:  FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(controller: _jumlahTerbuangController, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: _selectedBahanBaku != null, decoration: InputDecoration(hintText: _selectedBahanBaku != null ? 'Masukkan jumlah (${_selectedBahanBaku!.unit})' : 'Pilih bahan baku terlebih dahulu', hintStyle: GoogleFonts. poppins(color: Colors. grey), suffixText: _selectedBahanBaku?. unit, suffixStyle: GoogleFonts.poppins(color: const Color(0xFFD4A373), fontWeight: FontWeight.w600), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4A373))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius. circular(8), borderSide: const BorderSide(color: Color(0xFFD4A373))), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color:  Colors.grey)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color:  Color(0xFFD4A373), width: 2)), filled: _selectedBahanBaku == null, fillColor: _selectedBahanBaku == null ? Colors.grey[100] : null, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)), style: GoogleFonts.poppins(), onChanged: (value) => _calculateTotalKerugian(), validator: (value) {
              if (value == null || value. isEmpty) return 'Jumlah terbuang harus diisi';
              if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
              if (double.parse(value) <= 0) return 'Jumlah harus lebih dari 0';
              return null;
            }),
            const SizedBox(height:  16),
            Text('Total Kerugian', style: GoogleFonts.poppins(fontSize: 14, fontWeight:  FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(controller: _totalKerugianController, enabled: false, decoration: InputDecoration(hintText: 'otomatis', hintStyle: GoogleFonts.poppins(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color:  Color(0xFFD4A373))), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color:  Colors.grey)), filled: true, fillColor: Colors. grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)), style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 16),
            Text('Tanggal', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            InkWell(onTap: _selectDate, child: Container(padding: const EdgeInsets. symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4A373)), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: GoogleFonts.poppins(color: Colors.black87)), const Icon(Icons.calendar_today, color: Color(0xFFD4A373), size: 20)]))),
            const SizedBox(height: 24),
            Text('Catatan & Foto Bukti', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFD4A373))),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),
            Text('Catatan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(controller: _catatanController, maxLines: 4, decoration: InputDecoration(hintText: 'Tambah Catatan', hintStyle: GoogleFonts.poppins(color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4A373))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius. circular(8), borderSide: const BorderSide(color: Color(0xFFD4A373))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color:  Color(0xFFD4A373), width: 2)), contentPadding: const EdgeInsets.all(16)), style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 120, height: 120, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD4A373), width: 2), borderRadius: BorderRadius.circular(8)), child: _selectedImage != null ? ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(_selectedImage!, fit: BoxFit.cover)) : Center(child: Text('Foto Bukti', style: GoogleFonts.poppins(color: const Color(0xFFD4A373), fontSize: 12), textAlign: TextAlign.center))), const SizedBox(width: 16), Column(children: [SizedBox(width: 120, child: OutlinedButton(onPressed: _pickImageFromCamera, style: OutlinedButton.styleFrom(side: const BorderSide(color:  Color(0xFF7A9B3B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text('Kamera', style: GoogleFonts.poppins(color: const Color(0xFF7A9B3B), fontSize: 14)))), const SizedBox(height: 8), SizedBox(width: 120, child: OutlinedButton(onPressed: _pickImageFromGallery, style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF7A9B3B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)), child: Text('Galeri', style:  GoogleFonts.poppins(color: const Color(0xFF7A9B3B), fontSize: 14))))])]),
            const SizedBox(height: 24),
            Text('Diinputkan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFD4A373))),
            const Divider(color: Color(0xFFD4A373), thickness: 1),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [Text('Oleh', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight. w500, color: const Color(0xFF7A9B3B))), Text(widget.userName. isNotEmpty ? widget.userName : 'User', style: GoogleFonts. poppins(fontSize: 14, color: Colors.grey[600]))]),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _simpanWasteFood, style: ElevatedButton. styleFrom(backgroundColor: const Color(0xFF7A9B3B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: _isLoading ? const SizedBox(width: 24, height: 24, child:  CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Simpan', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)))),
          ],
        ),
      ),
    );
  }
}

// ==================== DETAIL WASTE FOOD PAGE (DUMMY) ====================
class WasteFoodDetailPage extends StatelessWidget {
  final WasteFoodModel waste;
  final String userId;
  final String userName;

  const WasteFoodDetailPage({super.key, required this.waste, required this.userId, required this. userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Waste', style: GoogleFonts.poppins())),
      body: Center(child: Text('Detail Page - Coming Soon', style: GoogleFonts.poppins(fontSize: 18))),
    );
  }
}