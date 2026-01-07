import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../config.dart';
import '../model/bahan_baku_model.dart';
import '../model/stok_masuk.dart';
import '../model/stok_keluar.dart';
import '../model/waste_food.dart';

class LaporanPage extends StatefulWidget {
  final String userId;
  final String userName;

  const LaporanPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  bool _isLoading = true;

  // Data for statistics
  List<StokMasukModel> _stokMasukList = [];
  List<dynamic> _stokKeluarList = [];
  List<WasteFoodModel> _wasteFoodList = [];

  double _totalOmset = 0;
  double _totalUntung = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadStokMasuk(),
      _loadStokKeluar(),
      _loadWasteFood(),
    ]);

    _calculateFinancials();

    setState(() => _isLoading = false);
  }

  Future<void> _loadStokMasuk() async {
    try {
      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'stok_masuk',
          'appid': appid,
          'user_id': widget.userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          _stokMasukList = data.map((item) => StokMasukModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('Error loading stok masuk: $e');
    }
  }

  Future<void> _loadStokKeluar() async {
    try {
      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'stok_keluar',
          'appid': appid,
          'user_id': widget.userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          _stokKeluarList = data;
        }
      }
    } catch (e) {
      print('Error loading stok keluar: $e');
    }
  }

  Future<void> _loadWasteFood() async {
    try {
      final response = await http.post(
        Uri.parse('$fileUri/select/'),
        body: {
          'token': token,
          'project': project,
          'collection': 'waste_food',
          'appid': appid,
          'user_id': widget.userId,
        },
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data is List) {
          _wasteFoodList = data.map((item) => WasteFoodModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('Error loading waste food: $e');
    }
  }

  void _calculateFinancials() {
    // Calculate total dari stok keluar (penjualan)
    _totalOmset = 0;
    for (var item in _stokKeluarList) {
      if (item['total_harga'] != null) {
        _totalOmset += double.tryParse(item['total_harga'].toString()) ?? 0;
      }
    }

    // Calculate total pengeluaran dari stok masuk
    double totalPengeluaran = 0;
    for (var item in _stokMasukList) {
      totalPengeluaran += double.tryParse(item.total_harga) ?? 0;
    }

    _totalUntung = _totalOmset - totalPengeluaran;
  }

  Map<String, int> _getStokMasukVsKeluar() {
    // Group by bahan baku name and count
    Map<String, int> stokMasuk = {};
    Map<String, int> stokKeluar = {};

    // Count stok masuk per bahan
    for (var item in _stokMasukList) {
      String kodeBahan = item.kode_bahan;
      stokMasuk[kodeBahan] = (stokMasuk[kodeBahan] ?? 0) + 1;
    }

    // Count stok keluar per bahan (from menu ingredients)
    for (var item in _stokKeluarList) {
      if (item['menu'] != null) {
        try {
          var menuData = json.decode(item['menu']);
          if (menuData is List) {
            for (var menuItem in menuData) {
              if (menuItem['bahan_baku'] != null) {
                var bahanBaku = menuItem['bahan_baku'];
                if (bahanBaku is List) {
                  for (var bahan in bahanBaku) {
                    String namaBahan = bahan['nama_bahan'] ?? 'Unknown';
                    stokKeluar[namaBahan] = (stokKeluar[namaBahan] ?? 0) + 1;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing menu: $e');
        }
      }
    }

    return {
      'stokMasuk': stokMasuk.length,
      'stokKeluar': stokKeluar.length,
    };
  }

  Map<String, int> _getWasteFoodByCategory() {
    Map<String, int> categories = {
      'Expired': 0,
      'Contamination': 0,
      'Overcooking': 0,
      'Spoilage': 0,
      'Prep Waste': 0,
      'Kesalahan Produksi': 0,
    };

    for (var waste in _wasteFoodList) {
      String kategori = waste.jenis_waste;
      if (categories.containsKey(kategori)) {
        categories[kategori] = categories[kategori]! + 1;
      }
    }

    return categories;
  }

  List<Map<String, dynamic>> _getPemakaianBahanBaku() {
    // Get top 20 most used ingredients
    Map<String, int> bahanCount = {};

    for (var waste in _wasteFoodList) {
      String namaBahan = waste.nama_bahan;
      bahanCount[namaBahan] = (bahanCount[namaBahan] ?? 0) + 1;
    }

    var sorted = bahanCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(20).map((e) => {
      'nama': e.key,
      'count': e.value,
    }).toList();
  }

  List<FlSpot> _getTotalPendapatanData() {
    // Group by month and calculate total
    Map<int, double> monthlyRevenue = {};

    for (var item in _stokKeluarList) {
      try {
        String tanggal = item['tanggal'] ?? '';
        if (tanggal.isNotEmpty) {
          DateTime date = DateFormat('yyyy-MM-dd').parse(tanggal);
          int month = date.month;
          double harga = double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
          monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + harga;
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    List<FlSpot> spots = [];
    for (int i = 1; i <= 12; i++) {
      spots.add(FlSpot(i.toDouble(), (monthlyRevenue[i] ?? 0) / 1000)); // in thousands
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Summary Cards
                      _buildFinancialSummary(),
                      const SizedBox(height: 20),

                    // Stok Masuk vs Stok Keluar Chart
                    _buildStokChart(),
                    const SizedBox(height: 20),

                    // Pemakaian Bahan Baku List
                    _buildPemakaianBahanBaku(),
                    const SizedBox(height: 20),

                    // Total Pendapatan Chart
                    _buildTotalPendapatanChart(),
                    const SizedBox(height: 20),

                    // Waste Food Pie Chart
                    _buildWasteFoodChart(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Omset',
            'Rp${NumberFormat('#,###', 'id_ID').format(_totalOmset.toInt())}',
            Colors.blue[100]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Untung',
            'Rp${NumberFormat('#,###', 'id_ID').format(_totalUntung.toInt())}',
            Colors.green[100]!,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStokChart() {
    final data = _getStokMasukVsKeluar();
    final stokMasukCount = data['stokMasuk'] ?? 0;
    final stokKeluarCount = data['stokKeluar'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              Text(
                'Stok Masuk vs Stok Keluar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (stokMasukCount > stokKeluarCount ? stokMasukCount : stokKeluarCount).toDouble() + 5,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return Text('Stok Masuk', style: GoogleFonts.poppins(fontSize: 10));
                          case 1:
                            return Text('Stok Keluar', style: GoogleFonts.poppins(fontSize: 10));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: stokMasukCount.toDouble(),
                        color: Colors.blue[300],
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: stokKeluarCount.toDouble(),
                        color: Colors.green[300],
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.blue[300]!, 'Stok Masuk'),
              const SizedBox(width: 20),
              _buildLegend(Colors.green[300]!, 'Stok Keluar'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPemakaianBahanBaku() {
    final data = _getPemakaianBahanBaku();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              Text(
                'Pemakaian Bahan Baku',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Belum ada data pemakaian',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...data.take(20).map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['nama'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    item['count'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildTotalPendapatanChart() {
    final spots = _getTotalPendapatanData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              Text(
                'Total Pendapatan',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[value.toInt()],
                              style: GoogleFonts.poppins(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}k',
                          style: GoogleFonts.poppins(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 12,
                minY: 0,
                maxY: 300,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.purple[300],
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.purple[300]!,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple[100]!.withAlpha(77),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteFoodChart() {
    final wasteData = _getWasteFoodByCategory();
    final totalWaste = wasteData.values.reduce((a, b) => a + b);

    if (totalWaste == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.grey[400], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Waste Food',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada data waste food',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      Colors.red[300]!,
      Colors.orange[300]!,
      Colors.yellow[300]!,
      Colors.pink[300]!,
      Colors.brown[300]!,
      Colors.red[400]!,
    ];

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    wasteData.forEach((category, count) {
      if (count > 0) {
        sections.add(
          PieChartSectionData(
            value: count.toDouble(),
            title: '${((count / totalWaste) * 100).toStringAsFixed(0)}%',
            color: colors[colorIndex % colors.length],
            radius: 80,
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.grey[400], size: 24),
              const SizedBox(width: 8),
              Text(
                'Waste Food',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (wasteData['Contamination']! > 0)
                _buildPieLegend(colors[0], 'Contamination'),
              if (wasteData['Overcooking']! > 0)
                _buildPieLegend(colors[1], 'Overcooking'),
              if (wasteData['Expired']! > 0)
                _buildPieLegend(colors[2], 'Expired'),
              if (wasteData['Spoilage']! > 0)
                _buildPieLegend(colors[3], 'Spoilage'),
              if (wasteData['Prep Waste']! > 0)
                _buildPieLegend(colors[4], 'Prep Waste'),
              if (wasteData['Kesalahan Produksi']! > 0)
                _buildPieLegend(colors[5], 'Kesalahan Produksi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPieLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

