import '../models/kunjungan_model.dart';
import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class KunjunganRepo {
  static const String _table = 'master_kunjungan';

  /// Payload kolom klinis, dipakai bersama oleh insert dan update.
  static Map<String, dynamic> _clinicalFields(KunjunganModel kunjungan) => {
        'tanggal_kunjungan': dateToJson(kunjungan.tanggalKunjungan),
        'keluhan_utama': kunjungan.keluhanUtama,
        'riwayat_penyakit_sekarang': kunjungan.riwayatPenyakitSekarang,
        'riwayat_penyakit_dahulu': kunjungan.riwayatPenyakitDahulu,
        'riwayat_penyakit_keluarga': kunjungan.riwayatPenyakitKeluarga,
        'pemeriksaan_fisik': kunjungan.pemeriksaanFisik,
        'tekanan_darah': kunjungan.tekananDarah,
        'suhu': kunjungan.suhu,
        'skala_nyeri': kunjungan.skalaNyeri,
        'nadi': kunjungan.nadi,
        'respiration_rate': kunjungan.respirationRate,
        'deskripsi_umum': kunjungan.deskripsiUmum,
        'kontak': kunjungan.kontak,
        'kesadaran': kunjungan.kesadaran,
        'orientasi': kunjungan.orientasi,
        'memori': kunjungan.memori,
        'konsentrasi': kunjungan.konsentrasi,
        'mood': kunjungan.mood,
        'proses_berpikir': kunjungan.prosesBerpikir,
        'persepsi': kunjungan.persepsi,
        'kemauan': kunjungan.kemauan,
        'psikomotor': kunjungan.psikomotor,
        'intelegensi': kunjungan.intelegensi,
        'diagnosis': kunjungan.diagnosis,
        'terapi': kunjungan.terapi,
        'note': kunjungan.note,
        'pasien_id': kunjungan.pasienId,
        'is_active': kunjungan.isActive,
      };

  static Future<void> insert(KunjunganModel kunjungan) {
    return DatabaseHelper.run('insert kunjungan', () async {
      await DatabaseHelper.table(_table).insert({
        'kunjungan_id': kunjungan.kunjunganId,
        ..._clinicalFields(kunjungan),
        'create_date': timestampToJson(kunjungan.createDate),
        'created_by': kunjungan.createdBy,
      });
    });
  }

  static Future<void> update(KunjunganModel kunjungan) {
    return DatabaseHelper.run('update kunjungan', () async {
      await DatabaseHelper.table(_table).update({
        ..._clinicalFields(kunjungan),
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': kunjungan.modifiedBy,
      }).eq('kunjungan_id', kunjungan.kunjunganId);
    });
  }

  static Future<List<KunjunganModel>> getAll(
      {int limit = 50, int offset = 0}) {
    return DatabaseHelper.run('getAll kunjungan', () async {
      // LIMIT ? OFFSET ? -> .range(from, to) yang inklusif di kedua ujung.
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('is_active', true)
          .range(offset, offset + limit - 1);
      return rows.map((row) => KunjunganModel.fromMap(row)).toList();
    });
  }

  static Future<List<KunjunganModel>> getByPasienId(String pasienId) {
    return DatabaseHelper.run('getByPasienId kunjungan', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('pasien_id', pasienId)
          .eq('is_active', true)
          .order('tanggal_kunjungan', ascending: false);
      return rows.map((row) => KunjunganModel.fromMap(row)).toList();
    });
  }

  static Future<List<KunjunganModel>> getAllByPasienId(String pasienId) {
    // Isinya memang identik dengan getByPasienId di versi MySQL; keduanya
    // dipertahankan karena provider yang berbeda memanggil nama yang berbeda.
    return getByPasienId(pasienId);
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete kunjungan', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('kunjungan_id', id);
    });
  }

  static Future<List<KunjunganModel>> searchByDiagnosis(String keyword) {
    return DatabaseHelper.run('searchByDiagnosis kunjungan', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          // ilike, bukan like: Postgres LIKE case-sensitive (beda dari MySQL).
          .ilike('diagnosis', '%${DatabaseHelper.escapeLike(keyword)}%')
          .eq('is_active', true);
      return rows.map((row) => KunjunganModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists kunjungan', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('kunjungan_id')
          .eq('kunjungan_id', id)
          .limit(1);
      return rows.isNotEmpty;
    });
  }
}
