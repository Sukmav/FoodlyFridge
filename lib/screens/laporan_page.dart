import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/report_service.dart';
import '../model/daily_data_model.dart';

class LaporanPage extends StatefulWidget {
  // Opsional parameter untuk fallback
  final String? userId;
  final String? userName;

  const LaporanPage({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  final ReportService _reportService = ReportService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> _dailyChartData = {};
  
  Map<String, dynamic> _overviewStats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  Map<String, dynamic> _analysisData = {};
  Map<String, dynamic> _chartData = {};
  
  bool _isLoading = true;
  bool _exporting = false;
  late String _currentUserId;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      // Coba dapatkan user dari Firebase Auth
      final user = _auth.currentUser;
      
      if (user != null) {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? 
                          user.email?.split('@')[0] ?? 
                          widget.userName ?? 
                          'User';
      } else {
        // Fallback ke parameter widget jika ada
        _currentUserId = widget.userId ?? '';
        _currentUserName = widget.userName ?? 'User';
        
        // Jika masih kosong, coba dari SharedPreferences
        if (_currentUserId.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          _currentUserId = prefs.getString('current_user_id') ?? '';
          _currentUserName = prefs.getString('current_user_name') ?? 'User';
        }
      }
      
      // Load data setelah userId didapatkan
      await _loadData();
    } catch (e) {
      print('Error initializing user data: $e');
      // Set default values
      _currentUserId = '';
      _currentUserName = 'User';
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUserId.isNotEmpty) {
        final stats = await _reportService.getOverviewStats(_currentUserId);
        final activities = await _reportService.getRecentActivities(_currentUserId);
        final analysis = await _reportService.getAnalysisData(_currentUserId);
        final charts = await _reportService.getChartData(_currentUserId);
        final dailyCharts = await _reportService.getDailyChartData(_currentUserId);
        
        if (mounted) {
          setState(() {
            _overviewStats = stats;
            _recentActivities = activities;
            _analysisData = analysis;
            _chartData = charts;
            _dailyChartData = dailyCharts;
          });
        }
      } else {
        print('Warning: userId is empty, showing empty report');
        if (mounted) {
          setState(() {
            _overviewStats = {};
            _recentActivities = [];
            _analysisData = {};
            _chartData = {};
          });
        }
      }
    } catch (e) {
      print('Error loading report data: $e');
      if (mounted) {
        setState(() {
          _overviewStats = {};
          _recentActivities = [];
          _analysisData = {};
          _chartData = {};
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _exportReport() async {
    setState(() {
      _exporting = true;
    });

    try {
      final success = await _reportService.exportReport(_currentUserId, 'pdf');
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan berhasil diexport'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengexport laporan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
        });
      }
    }
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3, // Sesuaikan aspect ratio
      padding: EdgeInsets.all(8),
      mainAxisSpacing: 8, // Tambah spacing
      crossAxisSpacing: 8,
      children: [
        _buildStatCard(
          title: 'Total Penjualan',
          value: _overviewStats['totalPenjualanFormatted'] ?? 'Rp 0',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Total Transaksi',
          value: _overviewStats['totalTransaksiFormatted'] ?? '0',
          icon: Icons.receipt,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Total Waste',
          value: _overviewStats['totalWasteFormatted'] ?? 'Rp 0',
          icon: Icons.warning,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Total Stok Masuk',
          value: _overviewStats['totalStokMasukFormatted'] ?? 'Rp 0',
          icon: Icons.inventory,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    if (_recentActivities.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text(
                'Belum ada aktivitas',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ..._recentActivities.map((activity) => _buildActivityItem(activity)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _parseColor(activity['color'] ?? '#667EEA'),
            child: Icon(
              _getActivityIcon(activity['icon']?.toString() ?? ''),
              color: Colors.white,
              size: 16,
            ),
            radius: 16,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']?.toString() ?? 'Aktivitas',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['description']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      activity['user_name']?.toString() ?? 'User',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    Spacer(),
                    Text(
                      _formatDate(activity['timestamp']?.toString() ?? ''),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
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

Widget _buildAnalysisSection() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Analisis Ringkasan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            children: [
              _buildAnalysisItem(
                'Margin Keuntungan',
                '${_analysisData['marginKeuntungan']?.toStringAsFixed(1) ?? '0'}%',
                Icons.trending_up,
                Colors.green,
              ),
              _buildAnalysisItem(
                'Persentase Waste',
                '${_analysisData['wastePercentage']?.toStringAsFixed(1) ?? '0'}%',
                Icons.trending_down,
                Colors.orange,
              ),
              // _buildAnalysisItem(
              //   'Total Menu Tersedia',
              //   '${_analysisData['totalMenu'] ?? '0'}',
              //   Icons.restaurant_menu,
              //   Colors.blue,
              // ),
              _buildAnalysisItem(
                'Menu Terjual',
                '${_analysisData['uniqueMenusSold'] ?? '0'}',
                Icons.shopping_basket,
                Colors.purple,
              ),
              _buildAnalysisItem(
                'Rata-rata Transaksi',
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(_analysisData['avgTransaksi'] ?? 0),
                Icons.monetization_on,
                Colors.teal,
              ),
              _buildAnalysisItem(
                'Total Transaksi',
                '${_analysisData['totalTransaksi'] ?? '0'}',
                Icons.receipt,
                Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildAnalysisItem(String title, String value, IconData icon, Color color) {
    // Handle value yang mengandung "U" atau format tidak valid
    String displayValue = value;
    if (value.contains('U') || value.contains('NaN') || value.contains('null')) {
      displayValue = '0'; // Default ke 0
    }
    
    return Container(
      margin: EdgeInsets.all(4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            displayValue, // Gunakan displayValue yang sudah difilter
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

Widget _buildDailyChartSection() {
  // Cek apakah data ada
  if (_dailyChartData.isEmpty || !_dailyChartData.containsKey('dailyData')) {
    return _buildEmptyChart();
  }

  try {
    // Konversi data
    final List<DailyData> dailyDataList = _convertToDailyDataList(_dailyChartData);
    
    if (dailyDataList.isEmpty) {
      return _buildEmptyDataChart();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildChartHeader(),
            SizedBox(height: 8),
            Text(
              'Grafik harian penjualan dan aktivitas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            
            // Tabs dengan Expanded untuk mencegah overflow
            Container(
              height: 400, // 3. Berikan tinggi tetap yang cukup
              child: DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 4. Column anak juga gunakan .min
                  children: [
                    TabBar(
                      labelColor: Colors.teal,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.teal,
                      tabs: [
                        Tab(text: 'Penjualan'),
                        Tab(text: 'Transaksi'),
                        Tab(text: 'Waste'),
                      ],
                    ),
                    SizedBox(height: 16),
                    // 5. Expanded di dalam Container dengan tinggi tetap AMAN
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildSalesChart(dailyDataList),
                          _buildTransactionsChart(dailyDataList),
                          _buildWasteChart(dailyDataList),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  } catch (e) {
    print('Error building daily chart: $e');
    return _buildErrorChart(e);
  }
}
  
  // HELPER METHODS untuk chart section
Widget _buildEmptyChart() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Data grafik harian belum tersedia',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildEmptyDataChart() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada data untuk 7 hari terakhir',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    ),
  );
}

Widget _buildErrorChart(dynamic error) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error menampilkan grafik harian',
            style: TextStyle(color: Colors.red),
          ),
          SizedBox(height: 8),
          Text(
            'Detail: $error',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

Widget _buildChartHeader() {
  return Row(
    children: [
      Icon(Icons.timeline, color: Colors.teal),
      SizedBox(width: 8),
      Text(
        'Aktivitas 7 Hari Terakhir',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

List<DailyData> _convertToDailyDataList(Map<String, dynamic> chartData) {
  List<DailyData> result = [];
  
  if (chartData.containsKey('dailyData')) {
    final dynamic dailyDataDynamic = chartData['dailyData'];
    
    if (dailyDataDynamic is List) {
      for (var item in dailyDataDynamic) {
        if (item is DailyData) {
          result.add(item);
        } else if (item is Map<String, dynamic>) {
          try {
            result.add(DailyData.fromJson(item));
          } catch (e) {
            print('Error converting item: $e');
          }
        }
      }
    }
  }
  
  // Jika kosong, buat default
  if (result.isEmpty) {
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      result.add(DailyData(
        day: _formatDayLabel(date),
        penjualan: 0.0,
        transaksi: 0.0,
        waste: 0.0,
        date: date,
      ));
    }
  }
  
  return result;
}

// PERBAIKI chart widgets dengan axis yang benar
Widget _buildSalesChart(List<DailyData> dailyDataList) {
  // Cari nilai maksimum untuk set axis
  double maxValue = 0;
  for (var data in dailyDataList) {
    if (data.penjualan > maxValue) maxValue = data.penjualan;
  }
  
  // Tambah 10% untuk padding
  if (maxValue > 0) maxValue = maxValue * 1.1;
  
  return Container(
    padding: EdgeInsets.all(8),
    child: SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: 0,
        labelStyle: TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Penjualan (Rp)'),
        numberFormat: NumberFormat.compactCurrency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ),
        minimum: 0,
        maximum: maxValue > 0 ? maxValue : null,
        labelStyle: TextStyle(fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x : point.y',
        builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
          if (data is DailyData) {
            final currencyFormat = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );
            return Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(data.day, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Penjualan: ${currencyFormat.format(data.penjualan)}'),
                ],
              ),
            );
          }
          return Container();
        },
      ),
      series: <CartesianSeries>[
        ColumnSeries<DailyData, String>(
          dataSource: dailyDataList,
          xValueMapper: (DailyData data, _) => data.day,
          yValueMapper: (DailyData data, _) => data.penjualan,
          name: 'Penjualan Harian',
          color: Colors.green,
          dataLabelSettings: DataLabelSettings(
            isVisible: dailyDataList.any((d) => d.penjualan > 0),
            labelAlignment: ChartDataLabelAlignment.top,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontSize: 10),
            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
              if (data is DailyData && data.penjualan > 0) {
                final formatter = NumberFormat.compact(locale: 'id_ID');
                final labelText = formatter.format(data.penjualan);
                
                // PERBAIKAN: Return Widget, bukan String
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    labelText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                );
              }
              // PERBAIKAN: Return Widget kosong
              return Container();
            },
          ),
        ),
      ],
    ),
  );
}

// BUAT juga _buildTransactionsChart dan _buildWasteChart dengan pola yang sama
Widget _buildTransactionsChart(List<DailyData> dailyDataList) {
  double maxValue = 0;
  for (var data in dailyDataList) {
    if (data.transaksi > maxValue) maxValue = data.transaksi;
  }
  maxValue = maxValue * 1.1;
  
  return Container(
    padding: EdgeInsets.all(8),
    child: SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: 0,
        labelStyle: TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Jumlah Transaksi'),
        minimum: 0,
        maximum: maxValue > 0 ? maxValue : null,
        interval: 1,
        labelStyle: TextStyle(fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        ColumnSeries<DailyData, String>(
          dataSource: dailyDataList,
          xValueMapper: (DailyData data, _) => data.day,
          yValueMapper: (DailyData data, _) => data.transaksi,
          name: 'Transaksi Harian',
          color: Colors.blue,
          dataLabelSettings: DataLabelSettings(
            isVisible: dailyDataList.any((d) => d.transaksi > 0),
            labelAlignment: ChartDataLabelAlignment.top,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );
}

Widget _buildWasteChart(List<DailyData> dailyDataList) {
  double maxValue = 0;
  for (var data in dailyDataList) {
    if (data.waste > maxValue) maxValue = data.waste;
  }
  maxValue = maxValue * 1.1;
  
  return Container(
    padding: EdgeInsets.all(8),
    child: SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: 0,
        labelStyle: TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Kerugian (Rp)'),
        numberFormat: NumberFormat.compactCurrency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ),
        minimum: 0,
        maximum: maxValue > 0 ? maxValue : null,
        labelStyle: TextStyle(fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        LineSeries<DailyData, String>(
          dataSource: dailyDataList,
          xValueMapper: (DailyData data, _) => data.day,
          yValueMapper: (DailyData data, _) => data.waste,
          name: 'Waste Harian',
          color: Colors.orange,
          markerSettings: MarkerSettings(isVisible: true),
          dataLabelSettings: DataLabelSettings(
            isVisible: dailyDataList.any((d) => d.waste > 0),
            labelAlignment: ChartDataLabelAlignment.top,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
  );
}
  // Helper untuk format label hari
  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hari Ini';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Kemarin';
    } else {
      final daysOfWeek = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
      return daysOfWeek[date.weekday % 7];
    }
  }

  Widget _buildDailySummaryItem(String title, double value, Color color, IconData icon) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    String formattedValue;
    if (title.contains('Transaksi')) {
      formattedValue = value.toInt().toString();
    } else {
      formattedValue = currencyFormat.format(value);
    }
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          formattedValue,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateString;
    }
  }

  Color _parseColor(String colorString) {
    try {
      String color = colorString;
      if (color.startsWith('#')) {
        color = color.substring(1);
      }
      if (color.length == 6) {
        color = 'FF$color';
      }
      return Color(int.parse(color, radix: 16));
    } catch (e) {
      return Color(0xFF667EEA);
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'delete':
        return Icons.delete;
      case 'upload':
        return Icons.upload;
      case 'download':
        return Icons.download;
      case 'edit':
        return Icons.edit;
      case 'add_circle':
        return Icons.add_circle;
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'people':
        return Icons.people;
      case 'business':
        return Icons.business;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: _exporting 
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.download),
            onPressed: _exporting ? null : _exportReport,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat laporan...'),
                ],
              ),
            )
          : _currentUserId.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 60, color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'Tidak dapat memuat laporan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'User ID tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.blue[100]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUserName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _currentUserId.length > 8 
                                      ? 'ID: ${_currentUserId.substring(0, 8)}...'
                                      : 'ID: $_currentUserId',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Overview Section
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildOverviewCards(),
                      
                      SizedBox(height: 24),
                      
                      // Analysis Section
                      _buildAnalysisSection(),
                      
                      SizedBox(height: 24),
                      
                      // Chart Section
                      _buildDailyChartSection(),
                      
                      SizedBox(height: 24),
                      
                      // Recent Activities
                      _buildRecentActivities(),
                      
                      SizedBox(height: 16),
                      
                      // Last Updated
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }
}

class SalesData {
  SalesData({
    required this.month,
    required this.penjualan,
    required this.pembelian,
    required this.waste,
  });
  
  final String month;
  final double penjualan;
  final double pembelian;
  final double waste;
}