class StaffModel {
  final String id;
  final String nama_staff;
  final String nomor_telepone;

  StaffModel({
    required this.id,
    required this.nama_staff,
    required this.nomor_telepone
  });

  factory StaffModel.fromJson(Map data) {
    return StaffModel(
        id: data['_id'],
        nama_staff: data['nama_staff'],
        nomor_telepone: data['nomor_telepone']
    );
  }
}