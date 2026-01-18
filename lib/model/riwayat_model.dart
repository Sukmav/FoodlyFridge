//lib/model/riwayat_model.dart
import 'package:intl/intl.dart';

class HistoryModel {
  final String id;
  final String
  type; // 'bahan_baku', 'menu', 'stok_masuk', 'waste_food', 'stok_keluar', 'staff', 'vendor'
  final String action; // 'create', 'update', 'delete'
  final String title;
  final String description;
  final String user_name;
  final String user_id;
  final String timestamp;
  final Map<String, dynamic>? metadata; // Data tambahan (opsional)
  final String? icon; // Ikon untuk tipe aktivitas

  HistoryModel({
    required this.id,
    required this.type,
    required this.action,
    required this.title,
    required this.description,
    required this.user_name,
    required this.user_id,
    required this.timestamp,
    this.metadata,
    this.icon,
  });

  // Getter untuk formatted date
  String get formattedDate {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  // Getter untuk hari
  String get day {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('EEEE').format(date);
    } catch (e) {
      return '';
    }
  }

  // Getter untuk warna berdasarkan tipe
  String get color {
    switch (type) {
      case 'bahan_baku':
        return '#4facfe';
      case 'menu':
        return '#43e97b';
      case 'stok_masuk':
        return '#667eea';
      case 'waste_food':
        return '#f83600';
      case 'stok_keluar':
        return '#f093fb';
      case 'staff':
        return '#a8edea';
      case 'vendor':
        return '#cd9cf2';
      default:
        return '#667eea';
    }
  }

  // Getter untuk ikon berdasarkan tipe
  String get iconType {
    switch (type) {
      case 'bahan_baku':
        return 'shopping_basket';
      case 'menu':
        return 'restaurant_menu';
      case 'stok_masuk':
        return 'download';
      case 'waste_food':
        return 'delete';
      case 'stok_keluar':
        return 'upload';
      case 'staff':
        return 'people';
      case 'vendor':
        return 'business';
      default:
        return 'history';
    }
  }

  // Getter untuk warna action
  String get actionColor {
    switch (action) {
      case 'create':
        return '#43e97b';
      case 'update':
        return '#4facfe';
      case 'delete':
        return '#f83600';
      default:
        return '#667eea';
    }
  }

  // Getter untuk label action
  String get actionLabel {
    switch (action) {
      case 'create':
        return 'Ditambahkan';
      case 'update':
        return 'Diperbarui';
      case 'delete':
        return 'Dihapus';
      default:
        return action;
    }
  }

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      user_name: json['user_name']?.toString() ?? '',
      user_id: json['user_id']?.toString() ?? '',
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      icon: json['icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'action': action,
      'title': title,
      'description': description,
      'user_name': user_name,
      'user_id': user_id,
      'timestamp': timestamp,
      'metadata': metadata,
      'icon': icon,
    };
  }
}
