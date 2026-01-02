class WasteFoodModel {
  final String id;
  final String nama_bahan;
  final String jenis_waste;
  final String jumlah_terbuang;
  final String tanggal;
  final String catatan;
  final String foto;
  final String total_kerugian;
  final String kode_bahan;

  WasteFoodModel({
    required this.id,
    required this.nama_bahan,
    required this.jenis_waste,
    required this.jumlah_terbuang,
    required this.tanggal,
    required this.catatan,
    required this.foto,
    required this.total_kerugian,
    required this.kode_bahan
  });

  factory WasteFoodModel.fromJson(Map data) {
    return WasteFoodModel(
        id: data['_id'],
        nama_bahan: data['nama_bahan'],
        jenis_waste: data['jenis_waste'],
        jumlah_terbuang: data['jumlah_terbuang'],
        tanggal: data['tanggal'],
        catatan: data['catatan'],
        foto: data['foto'],
        total_kerugian: data['total_kerugian'],
        kode_bahan: data['kode_bahan']
    );
  }
}

//waste food ini adalah fungsi yang akan digunakan untuk mencatat setiap bahan baku yang terbuang atau tidak terpakai dalam proses operasional restoran. Waste food ini berisi informasi penting seperti nama bahan baku, jenis waste (misalnya kadaluarsa, rusak, dll), jumlah bahan yang terbuang, tanggal pembuangan, catatan tambahan, foto bahan baku yang terbuang, total kerugian akibat waste tersebut, dan kode bahan baku. Dengan adanya pencatatan waste food ini, restoran dapat memantau dan mengelola limbah makanan mereka dengan lebih efektif, serta mengidentifikasi area di mana efisiensi dapat ditingkatkan untuk mengurangi pemborosan.
// Selain itu, data waste food juga dapat digunakan untuk analisis biaya dan perencanaan pembelian bahan baku di masa depan.
// Hal ini membantu restoran dalam mengoptimalkan penggunaan bahan baku, mengurangi kerugian finansial, dan mendukung praktik operasional yang lebih berkelanjutan.
// Dengan demikian, waste food model ini menjadi alat penting dalam manajemen operasional restoran.
// Ini juga dapat membantu dalam pelaporan internal dan kepatuhan terhadap regulasi terkait pengelolaan limbah makanan.
// Dengan mencatat dan menganalisis data waste food, restoran dapat mengambil langkah-langkah proaktif untuk mengurangi pemborosan, meningkatkan efisiensi operasional, dan pada akhirnya meningkatkan profitabilitas bisnis mereka.
// Selain itu, pencatatan waste food juga dapat meningkatkan kesadaran staf tentang pentingnya pengelolaan bahan baku yang efisien dan bertanggung jawab.
// Dengan demikian, waste food model ini tidak hanya berfungsi sebagai alat pencatatan, tetapi juga sebagai komponen kunci dalam strategi manajemen restoran yang lebih luas.