class ReportModel {
  final String id;
  final String type;
  final DateTime date;
  final Map<String, dynamic> data;

  ReportModel({
    required this.id,
    required this.type,
    required this.date,
    required this.data,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
    );
  }
}