import 'package:flutter/foundation.dart';
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

enum StokMasukStep {
  selectVendor,
  selectBahanBaku,
  inputQuantity,
  reviewOrder,
  orderConfirmation,
}

class _StokMasukPageState extends State<StokMasukPage> {
  final DataService _dataService = DataService();
  final TextEditingController _catatanController = TextEditingController();

  BahanBakuModel? _selectedBahanBaku;
  VendorModel? _selectedVendor;
  DateTime _tanggalMasuk = DateTime.now();
  bool _isLoading = false;

  // New variables for multi-step flow
  StokMasukStep _currentStep = StokMasukStep.selectVendor;
  int _quantity = 1;
  double _hargaPerUnit = 0;
  double _totalHarga = 0;
  bool _showNotification = false;

  // Track selected items with quantities
  // Use fallback key = nama_bahan when id is empty to avoid collision when id missing
  Map<String, int> _selectedItems = {}; // key -> quantity (key = id if available else nama_bahan)
  Map<String, BahanBakuModel> _selectedBahanBakuMap = {}; // key -> BahanBakuModel

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  // Calculate totals
  void _calculateTotal() {
    setState(() {
      _totalHarga = _quantity * _hargaPerUnit;
    });
  }

  // Navigate to select vendor from bahan baku list
  void _onBahanBakuSelected(BahanBakuModel bahan) {
    setState(() {
      _selectedBahanBaku = bahan;
      _hargaPerUnit = double.tryParse(bahan.harga_per_unit) ?? 0;
      // Load existing quantity if item was previously selected, otherwise default to 1
      final key = (bahan.id != null && bahan.id.isNotEmpty) ? bahan.id : bahan.nama_bahan;
      _quantity = _selectedItems[key] ?? 1;
      _calculateTotal();
    });
    _showQuantityBottomSheet();
  }

  // Show bottom sheet for quantity input (with Cancel button)
  void _showQuantityBottomSheet() {
    // Capture current state so Cancel can revert to it
    final prevSelectedBahan = _selectedBahanBaku;
    final prevQuantity = _quantity;
    final prevTotal = _totalHarga;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Jumlah Stok yang Ingin Dipesan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bahan Baku Name
                    Text(
                      _selectedBahanBaku?.nama_bahan ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Harga Per Satuan
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Text(
                            'Harga Per Satuan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Rp ${_hargaPerUnit.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A9B3B),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quantity Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minus Button
                        IconButton(
                          onPressed: () {
                            if (_quantity > 1) {
                              setModalState(() {
                                _quantity--;
                                _totalHarga = _quantity * _hargaPerUnit;
                              });
                            }
                          },
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4A574),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.remove,
                              color: Color(0xFFD4A574),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Quantity Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Plus Button
                        IconButton(
                          onPressed: () {
                            setModalState(() {
                              _quantity++;
                              _totalHarga = _quantity * _hargaPerUnit;
                            });
                          },
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD4A574),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Total Harga
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A9B3B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF7A9B3B),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Harga',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Rp ${_totalHarga.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A9B3B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons row: Cancel, Tambah Lagi, Pesan
                    Row(
                      children: [
                        // BATAL: discard changes and close sheet
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Revert any in-sheet changes by restoring previous captured values
                              setState(() {
                                _selectedBahanBaku = prevSelectedBahan;
                                _quantity = prevQuantity;
                                _totalHarga = prevTotal;
                              });
                              Navigator.pop(context); // just close the sheet
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Colors.grey,
                                width: 1,
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
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // "Tambah Lagi" keeps user on bahan list so they can add more items
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Save current selection then close the sheet and stay on bahan list
                              if (_selectedBahanBaku != null) {
                                final key = (_selectedBahanBaku!.id != null && _selectedBahanBaku!.id.isNotEmpty)
                                    ? _selectedBahanBaku!.id
                                    : _selectedBahanBaku!.nama_bahan;
                                setState(() {
                                  _selectedItems[key] = _quantity;
                                  _selectedBahanBakuMap[key] = _selectedBahanBaku!;
                                });
                              }
                              Navigator.pop(context);
                              // do not change _currentStep so user remains on selectBahanBaku
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                color: Color(0xFF7A9B3B),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Tambah Lagi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A9B3B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Pesan Button - proceed to review (keeps existing behaviour)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Save current selection and go to review
                              if (_selectedBahanBaku != null) {
                                final key = (_selectedBahanBaku!.id != null && _selectedBahanBaku!.id.isNotEmpty)
                                    ? _selectedBahanBaku!.id
                                    : _selectedBahanBaku!.nama_bahan;
                                setState(() {
                                  _selectedItems[key] = _quantity;
                                  _selectedBahanBakuMap[key] = _selectedBahanBaku!;
                                });
                              }
                              Navigator.pop(context);
                              setState(() {
                                _currentStep = StokMasukStep.reviewOrder;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF7A9B3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Pesan',
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show bottom summary popup with total and items
  void _showBottomSummaryPopup() {
    // Calculate totals
    int totalItems = _selectedItems.length; // Count distinct items, not quantity sum
    double grandTotal = 0;

    _selectedItems.forEach((bahanBakuId, qty) {
      final bahan = _selectedBahanBakuMap[bahanBakuId];
      if (bahan != null) {
        double harga = double.tryParse(bahan.harga_per_unit) ?? 0;
        grandTotal += (qty * harga);
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rp ${grandTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A9B3B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Harga',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalItems',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bahan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Add a small "Tambah Lagi" link so user can add more items without leaving list
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // keep user on bahan list (no change to _currentStep)
                },
                child: Text(
                  'Tambah bahan lain',
                  style: TextStyle(color: Colors.green[700]),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to review order
                    setState(() {
                      _currentStep = StokMasukStep.reviewOrder;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF7A9B3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Pesan',
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
        );
      },
    );
  }

  // Cancel review and go back to initial state
  void _cancelReview() {
    setState(() {
      _selectedVendor = null;
      _selectedBahanBaku = null;
      _quantity = 1;
      _totalHarga = 0;
      _currentStep = StokMasukStep.selectVendor;

      // IMPORTANT: clear selected items so UI returns to unselected state
      _selectedItems.clear();
      _selectedBahanBakuMap.clear();
    });
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
        // Stay on selectVendor step - don't auto-navigate
        // User must manually tap "Pilih Bahan Baku" card
      });
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

    if (_quantity <= 0) {
      Fluttertoast.showToast(
        msg: "Masukkan jumlah yang valid!",
        backgroundColor: Colors.red,
      );
      return;
    }

    // Show confirmation popup
    await _showOrderConfirmationPopup();
  }

  Future<void> _showOrderConfirmationPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Vendor siap mengirim Pesanan Anda, ditunggu ya!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close dialog
                        await _showNotificationBanner();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8B4513), width: 2), // warna & tebal garis
                        foregroundColor: const Color(0xFF8B4513), // warna teks
                        backgroundColor: Colors.white, // biarkan transparan
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Siap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotificationBanner() async {
    setState(() {
      _showNotification = true;
    });
  }

  Future<void> _confirmStokMasuk() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stok Masuk',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A9B3B),
                  ),
                ),
                const SizedBox(height: 20),
                _buildPopupRow('Nama', _selectedBahanBaku?.nama_bahan ?? '-'),
                const SizedBox(height: 12),
                _buildPopupRow('Jumlah', '$_quantity ${_selectedBahanBaku?.unit ?? ''}'),
                const SizedBox(height: 12),
                _buildPopupRow('Harga', 'Rp ${_hargaPerUnit.toStringAsFixed(0)}/${_selectedBahanBaku?.unit ?? ''}'),
                const SizedBox(height: 12),
                _buildPopupRow('Dari', _selectedVendor?.nama_vendor ?? '-'),
                const Divider(height: 24),
                _buildPopupRow('Total', 'Rp ${_totalHarga.toStringAsFixed(0)}', isBold: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close dialog
                      await _saveAndShowSuccessAnimation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7A9B3B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terima',
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
          ),
        );
      },
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF7A9B3B) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndShowSuccessAnimation() async {
    // Show success animation
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.check_circle_outline_outlined,
                        color: const Color(0xFF7A9B3B),
                        size: 100 * value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    // Save to database
    await _saveToDatabase();

    // Hide notification and reset
    setState(() {
      _showNotification = false;
      _selectedVendor = null;
      _selectedBahanBaku = null;
      _quantity = 1;
      _totalHarga = 0;
      _currentStep = StokMasukStep.selectVendor;

      // IMPORTANT: clear selected items so UI returns to unselected state after confirming
      _selectedItems.clear();
      _selectedBahanBakuMap.clear();
    });

    Fluttertoast.showToast(
      msg: "Stok masuk berhasil dikonfirmasi!",
      backgroundColor: Colors.green,
    );
  }

  Future<void> _saveToDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String tanggalMasukStr = '${_tanggalMasuk.year}-${_tanggalMasuk.month.toString().padLeft(2, '0')}-${_tanggalMasuk.day.toString().padLeft(2, '0')}';

      double grossQty = double.parse(_selectedBahanBaku!.gross_qty.isEmpty ? '1' : _selectedBahanBaku!.gross_qty);
      double totalQty = _quantity * grossQty;

      // Insert data ke database
      final result = await _dataService.insertStokMasuk(
        appid,
        _selectedBahanBaku!.id,
        tanggalMasukStr,
        _quantity.toString(),
        totalQty.toStringAsFixed(2),
        _hargaPerUnit.toStringAsFixed(0),
        _totalHarga.toStringAsFixed(0),
        _selectedVendor!.id,
      );

      if (kDebugMode) print('Result insert stok masuk: $result');

      // Update stok tersedia bahan baku
      if (_selectedBahanBaku!.id.isNotEmpty) {
        double stokSebelumnya = double.parse(_selectedBahanBaku!.stok_tersedia.isEmpty ? '0' : _selectedBahanBaku!.stok_tersedia);
        double stokBaru = stokSebelumnya + totalQty;

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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (kDebugMode) print('Error menyimpan stok masuk: $e');
      Fluttertoast.showToast(
        msg: "Gagal menyimpan: ${e.toString()}",
        backgroundColor: Colors.red,
      );
    }
  }

  Future<String> _data_service_selectAll() async {
    final res = await _dataService.selectAll(
      token,
      project,
      'bahan_baku',
      appid,
    );
    if (res == null) return '';
    if (res is String) return res;
    try {
      return json.encode(res);
    } catch (_) {
      return res.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          Column(
            children: [
              // Notification banner
              if (_showNotification)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3CD),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Stok Masuk !',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _confirmStokMasuk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A9B3B),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Main content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStepContent(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case StokMasukStep.selectVendor:
        return _buildSelectVendorStep();
      case StokMasukStep.selectBahanBaku:
        return _buildSelectBahanBakuStep();
      case StokMasukStep.reviewOrder:
        return _buildReviewOrderStep();
      default:
        return _buildSelectVendorStep();
    }
  }

  Widget _buildSelectVendorStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pilih Vendor Card
          GestureDetector(
            onTap: _navigateToPilihVendor,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                        Text(
                          _selectedVendor != null ? 'Vendor' : 'Pilih Vendor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_selectedVendor != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _selectedVendor!.nama_vendor,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B6D5B),
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

          // Pilih Bahan Baku Card (disabled if vendor not selected)
          GestureDetector(
            onTap: _selectedVendor != null
                ? () {
              setState(() {
                _currentStep = StokMasukStep.selectBahanBaku;
              });
            }
                : null,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedVendor != null ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedVendor != null
                      ? Colors.grey[300]!
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  if (_selectedVendor != null)
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _selectedVendor != null
                          ? const Color(0xFF7A9B3B)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Pilih Bahan Baku',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedVendor != null
                            ? const Color(0xFF5B6D5B)
                            : Colors.grey[400],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _selectedVendor != null
                        ? Colors.grey[400]
                        : Colors.grey[300],
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectBahanBakuStep() {
    // Create unique key from Map content to force rebuild when items change
    final mapKey = _selectedItems.entries.map((e) => '${e.key}:${e.value}').join(',');

    // Safety: if vendor not selected, fallback to vendor step
    if (_selectedVendor == null) return _buildSelectVendorStep();

    return PilihBahanBakuFromVendorPage(
      key: ValueKey(mapKey), // Force rebuild when Map content changes
      vendor: _selectedVendor!,
      onBahanBakuSelected: _onBahanBakuSelected,
      selectedItems: Map.from(_selectedItems), // Pass copy to ensure new reference
    );
  }

  Widget _buildReviewOrderStep() {
    // Calculate totals from all selected items
    int totalQuantity = 0;
    double grandTotal = 0;

    _selectedItems.forEach((bahanBakuId, qty) {
      final bahan = _selectedBahanBakuMap[bahanBakuId];
      if (bahan != null) {
        totalQuantity += qty;
        double harga = double.tryParse(bahan.harga_per_unit) ?? 0;
        grandTotal += (qty * harga);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Pesanan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B6D5B),
            ),
          ),
          const SizedBox(height: 20),

          // Order Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Vendor', _selectedVendor?.nama_vendor ?? '-'),
                const Divider(height: 24),

                // List all selected items
                const Text(
                  'Bahan Baku',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ..._selectedItems.entries.map((entry) {
                  final bahan = _selectedBahanBakuMap[entry.key];
                  final qty = entry.value;
                  if (bahan == null) return const SizedBox.shrink();

                  double harga = double.tryParse(bahan.harga_per_unit) ?? 0;
                  double subtotal = qty * harga;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bahan.nama_bahan,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '$qty ${bahan.unit} × Rp ${harga.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rp ${subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const Divider(height: 24),
                _buildReviewRow(
                  'Total Harga',
                  'Rp ${grandTotal.toStringAsFixed(0)}',
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                borderSide: const BorderSide(color: Color(0xFFD4A574)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD4A574)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD4A574), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelReview,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF7A9B3B), width: 2),
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
              Expanded(
                child: ElevatedButton(
                  onPressed: _buatPesanan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF7A9B3B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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
        ],
      ),
    );
  }
}

// ==================== HALAMAN PILIH BAHAN BAKU FROM VENDOR ====================
class PilihBahanBakuFromVendorPage extends StatefulWidget {
  final VendorModel vendor;
  final Function(BahanBakuModel) onBahanBakuSelected;
  final Map<String, int> selectedItems;

  const PilihBahanBakuFromVendorPage({
    super.key,
    required this.vendor,
    required this.onBahanBakuSelected,
    required this.selectedItems,
  });

  @override
  State<PilihBahanBakuFromVendorPage> createState() => _PilihBahanBakuFromVendorPageState();
}

class _PilihBahanBakuFromVendorPageState extends State<PilihBahanBakuFromVendorPage> {
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
      final response = await _data_service_selectAll();

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

  Future<String> _data_service_selectAll() async {
    final res = await _dataService.selectAll(
      token,
      project,
      'bahan_baku',
      appid,
    );
    if (res == null) return '';
    if (res is String) return res;
    try {
      return json.encode(res);
    } catch (_) {
      return res.toString();
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
    return Column(
      children: [
        // Header dengan info vendor
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Bahan Baku',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B6D5B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Vendor: ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    widget.vendor.nama_vendor,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A9B3B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

              // Use same key logic as parent: id if present else nama_bahan
              final key = (bahan.id != null && bahan.id.isNotEmpty) ? bahan.id : bahan.nama_bahan;
              final quantity = widget.selectedItems[key] ?? 0;
              final isSelected = quantity > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? const BorderSide(color: Color(0xFF7A9B3B), width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5A3C).withOpacity(0.1),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7A9B3B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$quantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    widget.onBahanBakuSelected(bahan);
                  },
                ),
              );
            },
          ),
        ),
      ],
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
            fontWeight: FontWeight.bold,
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
                        color: const Color(0xFF8B5A3C).withOpacity(0.1),
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