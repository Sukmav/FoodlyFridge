import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../helpers/riwayat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LaporanPage extends StatefulWidget {
  final String userId;
  final String userName;

  const LaporanPage({super.key, required this.userId, required this.userName});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SimpleRiwayatService _riwayatService = SimpleRiwayatService();
  List<Map<String, dynamic>> _allActivities = [];
  bool _isLoading = true;
  String _timeFilter = 'Hari Ini';
  DateTime _selectedDate = DateTime.now();

  // Data untuk charts
  List<FlSpot> _penjualanData = [];
  List<FlSpot> _wasteData = [];
  List<FlSpot> _stokMasukData = [];

  Map<String, double> _penjualanMap = {};
  Map<String, double> _wasteMap = {};
  Map<String, double> _stokMasukMap = {};

  // Statistik
  double _totalPenjualan = 0;
  double _totalWaste = 0;
  double _totalStokMasuk = 0;
  int _totalTransaksi = 0;
  double _averageTransactionValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLaporanData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLaporanData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Load semua aktivitas
      final activities = await _riwayatService.getAllUserActivities(
        widget.userId,
      );

      // 2. Filter berdasarkan tanggal yang dipilih
      final filteredActivities = _filterActivitiesByDate(activities);

      // 3. Hitung statistik
      await _calculateStatistics(filteredActivities);

      // 4. Generate chart data
      await _generateChartData(filteredActivities);

      if (mounted) {
        setState(() {
          _allActivities = filteredActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading laporan data: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterActivitiesByDate(
    List<Map<String, dynamic>> activities,
  ) {
    DateTime startDate;
    DateTime endDate = DateTime.now();

    switch (_timeFilter) {
      case 'Hari Ini':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case 'Minggu Ini':
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'Bulan Ini':
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case 'Tahun Ini':
        startDate = DateTime(endDate.year, 1, 1);
        break;
      default:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
    }

    return activities.where((activity) {
      try {
        final timestamp = DateTime.parse(activity['timestamp']);
        return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _calculateStatistics(
    List<Map<String, dynamic>> activities,
  ) async {
    double penjualan = 0;
    double waste = 0;
    double stokMasuk = 0;
    int transaksi = 0;

    for (var activity in activities) {
      double? extractedValue = _extractNumericValue(
        activity['description'] ?? '',
      );

      if (extractedValue != null) {
        switch (activity['type']) {
          case 'stok_keluar':
            transaksi++;
            penjualan += extractedValue;
            break;
          case 'waste_food':
            waste += extractedValue;
            break;
          case 'stok_masuk':
            stokMasuk += extractedValue;
            break;
        }
      }
    }

    setState(() {
      _totalPenjualan = penjualan;
      _totalWaste = waste;
      _totalStokMasuk = stokMasuk;
      _totalTransaksi = transaksi;
      _averageTransactionValue = transaksi > 0 ? penjualan / transaksi : 0;
    });
  }

  double? _extractNumericValue(String description) {
    // Cari angka dengan format currency atau angka biasa
    final patterns = [
      RegExp(r'Total:\s*Rp?\s*([\d.,]+)'),
      RegExp(r'Harga:\s*([\d.,]+)'),
      RegExp(r'Jumlah:\s*([\d.,]+)'),
      RegExp(r'Stok:\s*([\d.,]+)'),
      RegExp(r'([\d.,]+)\s*(?:Rp|IDR|rb|ribu|jt|juta)', caseSensitive: false),
      RegExp(r'([\d.,]+)'), // Fallback: ambil angka apa saja
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(description);
      if (match != null) {
        try {
          final numberStr = match.group(1) ?? match.group(0) ?? '0';
          // Bersihkan dari titik dan koma
          final cleanStr = numberStr
              .replaceAll('.', '')
              .replaceAll(',', '.')
              .replaceAll(RegExp(r'[^0-9.]'), '');

          final value = double.tryParse(cleanStr);
          if (value != null) return value;
        } catch (e) {
          continue;
        }
      }
    }

    return null;
  }

  Future<void> _generateChartData(List<Map<String, dynamic>> activities) async {
    // Group activities by time period
    Map<String, double> penjualanMap = {};
    Map<String, double> wasteMap = {};
    Map<String, double> stokMasukMap = {};

    // Tentukan format berdasarkan filter waktu
    DateFormat dateFormat;
    Duration interval;

    switch (_timeFilter) {
      case 'Hari Ini':
        dateFormat = DateFormat('HH:00');
        interval = const Duration(hours: 1);
        break;
      case 'Minggu Ini':
        dateFormat = DateFormat('EEE');
        interval = const Duration(days: 1);
        break;
      case 'Bulan Ini':
        dateFormat = DateFormat('dd/MM');
        interval = const Duration(days: 1);
        break;
      case 'Tahun Ini':
        dateFormat = DateFormat('MMM');
        interval = const Duration(days: 30);
        break;
      default:
        dateFormat = DateFormat('dd/MM');
        interval = const Duration(days: 1);
    }

    for (var activity in activities) {
      try {
        final timestamp = DateTime.parse(activity['timestamp']);
        final timeKey = dateFormat.format(timestamp);
        final extractedValue = _extractNumericValue(
          activity['description'] ?? '',
        );

        if (extractedValue != null) {
          switch (activity['type']) {
            case 'stok_keluar':
              penjualanMap.update(
                timeKey,
                (v) => v + extractedValue,
                ifAbsent: () => extractedValue,
              );
              break;
            case 'waste_food':
              wasteMap.update(
                timeKey,
                (v) => v + extractedValue,
                ifAbsent: () => extractedValue,
              );
              break;
            case 'stok_masuk':
              stokMasukMap.update(
                timeKey,
                (v) => v + extractedValue,
                ifAbsent: () => extractedValue,
              );
              break;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing activity: $e');
        }
      }
    }

    setState(() {
      _penjualanMap = penjualanMap;
      _wasteMap = wasteMap;
      _stokMasukMap = stokMasukMap;
      _penjualanData = _convertMapToChartData(penjualanMap);
      _wasteData = _convertMapToChartData(wasteMap);
      _stokMasukData = _convertMapToChartData(stokMasukMap);
    });
  }

  // Future<void> _generateDummyChartData(DateFormat dateFormat) async {
  //   // Generate data dummy untuk demo
  //   final now = DateTime.now();
  //   List<String> labels = [];

  //   // Buat label berdasarkan periode
  //   switch (_timeFilter) {
  //     case 'Hari Ini':
  //       for (int i = 0; i < 12; i++) {
  //         final time = now.subtract(Duration(hours: 11 - i));
  //         labels.add(dateFormat.format(time));
  //       }
  //       break;
  //     case 'Minggu Ini':
  //       final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  //       labels = days;
  //       break;
  //     case 'Bulan Ini':
  //       for (int i = 0; i < 7; i++) {
  //         final date = now.subtract(Duration(days: 6 - i));
  //         labels.add(dateFormat.format(date));
  //       }
  //       break;
  //     case 'Tahun Ini':
  //       final months = [
  //         'Jan',
  //         'Feb',
  //         'Mar',
  //         'Apr',
  //         'May',
  //         'Jun',
  //         'Jul',
  //         'Aug',
  //         'Sep',
  //         'Oct',
  //         'Nov',
  //         'Dec',
  //       ];
  //       labels = months;
  //       break;
  //   }

  //   // Generate data dummy dengan pola random
  //   final random = Random();
  //   List<FlSpot> penjualan = [];
  //   List<FlSpot> waste = [];
  //   List<FlSpot> stokMasuk = [];

  //   for (int i = 0; i < labels.length; i++) {
  //     final x = i.toDouble();
  //     penjualan.add(FlSpot(x, random.nextDouble() * 1000000 + 500000));
  //     waste.add(FlSpot(x, random.nextDouble() * 200000 + 50000));
  //     stokMasuk.add(FlSpot(x, random.nextDouble() * 800000 + 300000));
  //   }

  //   setState(() {
  //     _penjualanData = penjualan;
  //     _wasteData = waste;
  //     _stokMasukData = stokMasuk;
  //   });
  // }

  List<FlSpot> _convertMapToChartData(Map<String, double> dataMap) {
    final sortedKeys = dataMap.keys.toList()..sort((a, b) => a.compareTo(b));

    return sortedKeys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dataMap[entry.value]!);
    }).toList();
  }

  Future<void> _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _timeFilter = 'Kustom';
      });
      await _loadLaporanData();
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isCurrency,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              if (isCurrency)
                Text(
                  'IDR',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCurrency
                ? NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(double.parse(value))
                : value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color color,
    required Map<String, double>? dataMap, // Tambahkan parameter dataMap
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                dataMap != null && dataMap.isNotEmpty
                    ? '${dataMap.length} data points'
                    : 'Data dummy',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada data',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        horizontalInterval: _calculateInterval(data),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (dataMap != null) {
                                final keys = dataMap.keys.toList();
                                final index = value.toInt();
                                if (index >= 0 && index < keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      keys[index],
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _calculateInterval(data),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compactCurrency(
                                  locale: 'id_ID',
                                  symbol: 'Rp',
                                  decimalDigits: 0,
                                ).format(value),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: data,
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.1),
                          ),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                      minX: 0,
                      maxX: data.length > 1 ? data.length - 1 : 1,
                      minY: 0,
                      maxY: data.isNotEmpty
                          ? data
                                    .map((e) => e.y)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2
                          : 100,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(List<FlSpot> data) {
    if (data.isEmpty) return 100;
    final maxY = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return maxY / 5;
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final icon = activity['icon'] ?? 'history';
    final color = Color(
      int.parse((activity['color'] ?? '#667eea').replaceFirst('#', '0xff')),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconData(icon), size: 24, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] ?? 'Aktivitas',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'] ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity['user_name'] ?? 'User',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(activity['timestamp']),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'upload':
        return Icons.upload;
      case 'download':
        return Icons.download;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'delete':
        return Icons.delete;
      case 'people':
        return Icons.people;
      case 'business':
        return Icons.business;
      default:
        return Icons.history;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd/MM/yy HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Periode Laporan',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Hari Ini'),
                    _buildFilterChip('Minggu Ini'),
                    _buildFilterChip('Bulan Ini'),
                    _buildFilterChip('Tahun Ini'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showDatePicker,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _timeFilter == 'Kustom'
                          ? DateFormat('dd MMMM yyyy').format(_selectedDate)
                          : 'Pilih Tanggal Kustom',
                      style: AppTextStyles.bodyMedium,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                title: 'Total Penjualan',
                value: _totalPenjualan.toString(),
                color: AppColors.success,
                icon: Icons.attach_money_rounded,
                isCurrency: true,
              ),
              _buildStatCard(
                title: 'Total Transaksi',
                value: _totalTransaksi.toString(),
                color: AppColors.primary,
                icon: Icons.receipt_long_rounded,
                isCurrency: false,
              ),
              _buildStatCard(
                title: 'Total Waste',
                value: _totalWaste.toString(),
                color: AppColors.danger,
                icon: Icons.delete_outline_rounded,
                isCurrency: true,
              ),
              _buildStatCard(
                title: 'Total Stok Masuk',
                value: _totalStokMasuk.toString(),
                color: AppColors.stockIn,
                icon: Icons.inventory_2_rounded,
                isCurrency: true,
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Charts Section
          _buildChartCard(
            title: 'Grafik Penjualan',
            data: _penjualanData,
            color: AppColors.success,
            dataMap: _penjualanMap, // Tambahkan ini
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Grafik Waste',
            data: _wasteData,
            color: AppColors.danger,
            dataMap: _wasteMap, // Tambahkan ini
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Grafik Stok Masuk',
            data: _stokMasukData,
            color: AppColors.stockIn,
            dataMap: _stokMasukMap, // Tambahkan ini
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ChoiceChip(
      label: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: _timeFilter == label ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: _timeFilter == label,
      onSelected: (selected) async {
        if (selected) {
          setState(() {
            _timeFilter = label;
          });
          await _loadLaporanData();
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildActivitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_allActivities.isEmpty && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada aktivitas',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada aktivitas yang tercatat dalam periode ini',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                ..._allActivities.map(
                  (activity) => _buildActivityItem(activity),
                ),
                const SizedBox(height: 32),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ringkasan Analisis
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Analisis',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildAnalysisRow(
                  'Rata-rata Nilai Transaksi',
                  NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_averageTransactionValue),
                  AppColors.success,
                ),
                _buildAnalysisRow(
                  'Efisiensi Stok',
                  '${_totalTransaksi > 0 ? ((_totalPenjualan / (_totalStokMasuk + _totalPenjualan)) * 100).toStringAsFixed(1) : '0.0'}%',
                  AppColors.info,
                ),
                _buildAnalysisRow(
                  'Rasio Waste',
                  '${_totalPenjualan > 0 ? ((_totalWaste / _totalPenjualan) * 100).toStringAsFixed(1) : '0.0'}%',
                  AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rekomendasi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Rekomendasi',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecommendationItem(
                  'Tingkatkan Penjualan',
                  'Fokus pada menu dengan margin tinggi',
                  Icons.trending_up_rounded,
                  AppColors.success,
                ),
                _buildRecommendationItem(
                  'Kurangi Waste',
                  'Pantau stok bahan baku lebih ketat',
                  Icons.warning_amber_rounded,
                  AppColors.danger,
                ),
                _buildRecommendationItem(
                  'Optimalkan Stok',
                  'Sesuaikan pembelian dengan pola penjualan',
                  Icons.timeline_rounded,
                  AppColors.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48), // Hanya tinggi TabBar
          child: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 1,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Aktivitas'),
                Tab(text: 'Analisis'),
              ],
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('Memuat laporan...', style: AppTextStyles.bodyMedium),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildActivitiesTab(),
                  _buildAnalyticsTab(),
                ],
              ),
      ),
    );
  }
}
