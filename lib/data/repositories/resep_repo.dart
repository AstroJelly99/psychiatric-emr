import '../models/model_converters.dart';
import '../models/resep_model.dart';
import '../../database/database_helper.dart';

class ResepRepository {
  static const String _table = 'master_resep';

  static Future<void> insert(ResepModel resep) {
    return DatabaseHelper.run('insert resep', () async {
      await DatabaseHelper.table(_table).insert({
        'resep_id': resep.resepId,
        'tanggal_resep': dateToJson(resep.tanggalResep),
        'catatan': resep.catatan,
        'pasien_id': resep.pasienId,
        'kunjungan_id': resep.kunjunganId,
        'is_active': resep.isActive,
        'create_date': timestampToJson(resep.createDate),
        'created_by': resep.createdBy,
      });
    });
  }

  static Future<void> update(ResepModel resep) {
    return DatabaseHelper.run('update resep', () async {
      await DatabaseHelper.table(_table).update({
        'tanggal_resep': dateToJson(resep.tanggalResep),
        'catatan': resep.catatan,
        'pasien_id': resep.pasienId,
        'kunjungan_id': resep.kunjunganId,
        'is_active': resep.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': resep.modifiedBy,
      }).eq('resep_id', resep.resepId);
    });
  }

  static Future<List<ResepModel>> getByKunjunganId(String kunjunganId) {
    return DatabaseHelper.run('getByKunjunganId resep', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('kunjungan_id', kunjunganId)
          .eq('is_active', true);
      return rows.map((row) => ResepModel.fromMap(row)).toList();
    });
  }

  /// Seluruh resep milik satu pasien, terbaru lebih dulu.
  ///
  /// Dipakai saat dokter menulis resep baru dan perlu melihat resep-resep
  /// sebelumnya. `getByKunjunganId` tidak cukup untuk itu: dia hanya
  /// mengembalikan resep pada kunjungan yang sedang dibuka, padahal yang
  /// dibutuhkan justru resep dari kunjungan-kunjungan LAIN.
  ///
  /// `ascending: false` ditulis eksplisit — default `order()` milik
  /// postgrest-dart memang descending, tapi mengandalkan default yang
  /// berlawanan dengan SQL itu persis yang dulu membuat nomor kuesioner
  /// terbalik.
  static Future<List<ResepModel>> getByPasienId(String pasienId) {
    return DatabaseHelper.run('getByPasienId resep', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('pasien_id', pasienId)
          .eq('is_active', true)
          .order('tanggal_resep', ascending: false);
      return rows.map((row) => ResepModel.fromMap(row)).toList();
    });
  }

  static Future<ResepModel?> getById(String id) {
    return DatabaseHelper.run('getById resep', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('resep_id', id)
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return ResepModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete resep', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('resep_id', id);
    });
  }
}
