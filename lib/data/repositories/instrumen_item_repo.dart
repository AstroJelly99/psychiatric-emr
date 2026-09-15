import '../models/instrumen_item_model.dart';
import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class InstrumenItemRepo {
  static const String _table = 'master_instrumen_item';

  static Future<void> insert(InstrumenItemModel item) {
    return DatabaseHelper.run('insert instrumen_item', () async {
      await DatabaseHelper.table(_table).insert({
        'instrumen_item_id': item.instrumenItemId,
        'instrumen_id': item.instrumenId,
        'pertanyaan': item.pertanyaan,
        'teks_pertanyaan': item.teksPertanyaan,
        'nomer_item': item.nomerItem,
        'kategori_skoring': item.kategoriSkoring,
        'is_active': item.isActive,
        'create_date': timestampToJson(item.createDate),
        'created_by': item.createdBy,
      });
    });
  }

  static Future<void> update(InstrumenItemModel item) {
    return DatabaseHelper.run('update instrumen_item', () async {
      await DatabaseHelper.table(_table).update({
        'instrumen_id': item.instrumenId,
        'pertanyaan': item.pertanyaan,
        'teks_pertanyaan': item.teksPertanyaan,
        'nomer_item': item.nomerItem,
        'kategori_skoring': item.kategoriSkoring,
        'is_active': item.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': item.modifiedBy,
      }).eq('instrumen_item_id', item.instrumenItemId);
    });
  }

  static Future<List<InstrumenItemModel>> getAll() {
    return DatabaseHelper.run('getAll instrumen_item', () async {
      final rows =
          await DatabaseHelper.table(_table).select().eq('is_active', true);
      return rows.map((row) => InstrumenItemModel.fromMap(row)).toList();
    });
  }

  static Future<InstrumenItemModel?> getById(String id) {
    return DatabaseHelper.run('getById instrumen_item', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('instrumen_item_id', id)
          .maybeSingle();
      if (row == null) return null;
      return InstrumenItemModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete instrumen_item', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('instrumen_item_id', id);
    });
  }

  static Future<List<InstrumenItemModel>> searchByPertanyaan(String keyword) {
    return DatabaseHelper.run('searchByPertanyaan instrumen_item', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          // ilike, bukan like: Postgres LIKE case-sensitive (beda dari MySQL).
          .ilike('pertanyaan', '%${DatabaseHelper.escapeLike(keyword)}%')
          .eq('is_active', true);
      return rows.map((row) => InstrumenItemModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists instrumen_item', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('instrumen_item_id')
          .eq('instrumen_item_id', id)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  static Future<bool> hasItems(String instrumenId) {
    return DatabaseHelper.run('hasItems instrumen_item', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('instrumen_item_id')
          .eq('instrumen_id', instrumenId)
          .eq('is_active', true)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  static Future<List<InstrumenItemModel>> getByInstrumenId(String instrumenId) {
    return DatabaseHelper.run('getByInstrumenId instrumen_item', () async {
      // `ORDER BY CAST(nomer_item AS INTEGER)` versi MySQL tidak diperlukan:
      // kolomnya memang sudah integer, jadi urutannya sudah numerik.
      //
      // `ascending: true` WAJIB ditulis eksplisit. Berbeda dari SQL, default
      // `order()` milik postgrest-dart adalah `ascending: false` — jadi
      // `.order('nomer_item')` saja menghasilkan 14,13,…,1 dan kuesioner
      // tampil terbalik.
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('instrumen_id', instrumenId)
          .eq('is_active', true)
          .order('nomer_item', ascending: true);
      return rows.map((row) => InstrumenItemModel.fromMap(row)).toList();
    });
  }

  /// Mengambil banyak item sekaligus berdasarkan daftar id.
  ///
  /// Method BARU (tidak menggantikan apa pun), disiapkan untuk menghapus pola
  /// N+1 di manage_asesmen_psikologis_provider.dart:293 dan
  /// asesmen_section_provider.dart:279 yang memanggil [getById] satu per satu.
  /// Lewat internet, 20 item = 20 round-trip ≈ 4 detik. Penggantian
  /// pemanggilnya ada di lib/domain/, di luar cakupan langkah ini.
  static Future<List<InstrumenItemModel>> getByIds(List<String> ids) {
    return DatabaseHelper.run('getByIds instrumen_item', () async {
      if (ids.isEmpty) return <InstrumenItemModel>[];
      final rows = await DatabaseHelper.table(_table)
          .select()
          .inFilter('instrumen_item_id', ids);
      return rows.map((row) => InstrumenItemModel.fromMap(row)).toList();
    });
  }
}
