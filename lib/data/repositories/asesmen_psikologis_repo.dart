import '../models/asesmen_psikologis_model.dart';
import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class AsesmenPsikologisRepo {
  static const String _table = 'master_asesmen_psikologis';

  static Future<void> insert(AsesmenPsikologisModel asesmen) {
    return DatabaseHelper.run('insert asesmen', () async {
      // `tanggal_asesmen` NOT NULL di database, tapi field Dart-nya nullable.
      // MySQL non-strict menerima NULL diam-diam dan menyimpannya sebagai
      // '0000-00-00'; Postgres menolak dengan kode 23502. Dicegat di sini
      // supaya pesannya menyebut field mana yang kosong, bukan kode SQL.
      final tanggalAsesmen = asesmen.tanggalAsesmen;
      if (tanggalAsesmen == null) {
        throw const RepositoryException(
          kind: RepositoryErrorKind.query,
          operation: 'insert asesmen',
          message: 'Tanggal asesmen belum diisi. '
              'Pilih kunjungan terlebih dahulu sebelum menyimpan.',
        );
      }

      await DatabaseHelper.table(_table).insert({
        'asesmen_id': asesmen.asesmenId,
        'jenis_asesmen': asesmen.jenisAsesmen,
        'skor_total': asesmen.skorTotal,
        'hasil_interpretasi': asesmen.hasilInterpretasi,
        'pasien_id': asesmen.pasienId,
        'kunjungan_id': asesmen.kunjunganId,
        'instrumen_id': asesmen.instrumenId,
        'tanggal_asesmen': timestampToJson(tanggalAsesmen),
        'is_active': asesmen.isActive,
        'create_date': timestampToJson(asesmen.createDate),
        'created_by': asesmen.createdBy,
      });
    });
  }

  static Future<void> update(AsesmenPsikologisModel asesmen) {
    return DatabaseHelper.run('update asesmen', () async {
      // `tanggal_asesmen` sengaja tidak ikut di-update, sama seperti versi
      // MySQL — tanggal asesmen tidak bisa dikoreksi setelah dibuat.
      await DatabaseHelper.table(_table).update({
        'jenis_asesmen': asesmen.jenisAsesmen,
        'skor_total': asesmen.skorTotal,
        'hasil_interpretasi': asesmen.hasilInterpretasi,
        'pasien_id': asesmen.pasienId,
        'kunjungan_id': asesmen.kunjunganId,
        'instrumen_id': asesmen.instrumenId,
        'is_active': asesmen.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': asesmen.modifiedBy,
      }).eq('asesmen_id', asesmen.asesmenId);
    });
  }

  static Future<List<AsesmenPsikologisModel>> getAll() {
    return DatabaseHelper.run('getAll asesmen', () async {
      final rows =
          await DatabaseHelper.table(_table).select().eq('is_active', true);
      return rows.map((row) => AsesmenPsikologisModel.fromMap(row)).toList();
    });
  }

  static Future<AsesmenPsikologisModel?> getById(String id) {
    return DatabaseHelper.run('getById asesmen', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('asesmen_id', id)
          .maybeSingle();
      if (row == null) return null;
      return AsesmenPsikologisModel.fromMap(row);
    });
  }

  static Future<List<AsesmenPsikologisModel>> getByPasienId(String pasienId) {
    return DatabaseHelper.run('getByPasienId asesmen', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('pasien_id', pasienId)
          .eq('is_active', true);
      return rows.map((row) => AsesmenPsikologisModel.fromMap(row)).toList();
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete asesmen', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('asesmen_id', id);
    });
  }

  static Future<List<AsesmenPsikologisModel>> search({
    String? pasienId,
    String? instrumenId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DatabaseHelper.run('search asesmen', () async {
      var query =
          DatabaseHelper.table(_table).select().eq('is_active', true);

      if (pasienId != null) {
        query = query.eq('pasien_id', pasienId);
      }

      if (instrumenId != null) {
        query = query.eq('instrumen_id', instrumenId);
      }

      // `DATE(create_date) >= ?` tidak bisa dinyatakan lewat query builder,
      // jadi diubah jadi perbandingan rentang atas kolom aslinya. Batasnya
      // dihitung dari tengah malam WAKTU LOKAL lalu dikirim sebagai UTC,
      // supaya "tanggal" yang dimaksud tetap tanggal di klinik, bukan di UTC.
      if (startDate != null) {
        final awalHari =
            DateTime(startDate.year, startDate.month, startDate.day);
        query = query.gte('create_date', timestampToJson(awalHari));
      }

      if (endDate != null) {
        // `<= tanggal` inklusif -> `< tanggal + 1 hari`.
        final akhirHari =
            DateTime(endDate.year, endDate.month, endDate.day + 1);
        query = query.lt('create_date', timestampToJson(akhirHari));
      }

      final rows = await query.order('create_date', ascending: false);
      return rows.map((row) => AsesmenPsikologisModel.fromMap(row)).toList();
    });
  }
}
