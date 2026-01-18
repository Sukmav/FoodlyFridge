// lib/model/daily_data_model.dart
import 'package:intl/intl.dart';

class DailyData {
  final String day;
  final double penjualan;
  final double transaksi;
  final double waste;
  final DateTime date;
  
  DailyData({
    required this.day,
    required this.penjualan,
    required this.transaksi,
    required this.waste,
    required this.date,
  });

  // Getter untuk formatted date
  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Getter untuk full day name
  String get fullDayName {
    return DateFormat('EEEE', 'id_ID').format(date);
  }

  // Convert to Map
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'penjualan': penjualan,
      'transaksi': transaksi,
      'waste': waste,
      'date': date.toIso8601String(),
    };
  }

  // Create from Map
  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      day: json['day'] ?? '',
      penjualan: (json['penjualan'] ?? 0).toDouble(),
      transaksi: (json['transaksi'] ?? 0).toDouble(),
      waste: (json['waste'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}