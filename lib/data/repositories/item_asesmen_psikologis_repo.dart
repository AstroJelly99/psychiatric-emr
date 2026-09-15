import '../models/item_asesmen_psikologis_model.dart';
import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class ItemAsesmenPsikologisRepo {
  static const String _table = 'item_asesmen_psikologis';

  // `item_id` sengaja tidak dikirim: kolomnya `generated always as identity`
  // di Postgres, mengirim nilai eksplisit akan ditolak server.
  static Future<void> insert(ItemAsesmenPsikologisModel item) {
    return DatabaseHelper.run('insert item_asesmen', () async {
      await DatabaseHelper.table(_table).insert({
        'skor': item.skor,
        'asesmen_id': item.asesmenId,
        'instrumen_item_id': item.instrumenItemId,
        'is_active': item.isActive,
        'create_date': timestampToJson(item.createDate),
        'created_by': item.createdBy,
      });
    });
  }

  static Future<void> update(ItemAsesmenPsikologisModel item) {
    return DatabaseHelper.run('update item_asesmen', () async {
      await DatabaseHelper.table(_table).update({
        'skor': item.skor,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': item.modifiedBy,
      }).eq('item_id', item.itemId);
    });
  }

  static Future<List<ItemAsesmenPsikologisModel>> getByAsesmenId(
      String asesmenId) {
    return DatabaseHelper.run('getByAsesmenId item_asesmen', () async {
      // JOIN ke master_instrumen_item diganti embedded select lewat foreign
      // key `fk_itemasesmen_instrumenitem`. Kolom hasil join (pertanyaan,
      // teks_pertanyaan, nomer_item, kategori_skoring) memang tidak dipakai
      // ItemAsesmenPsikologisModel.fromMap — sama seperti versi MySQL, yang
      // juga membuangnya. Tetap diambil karena urutannya dipakai di ORDER BY.
      final rows = await DatabaseHelper.table(_table)
          .select(
              '*, master_instrumen_item!fk_itemasesmen_instrumenitem(nomer_item)')
          .eq('asesmen_id', asesmenId)
          .eq('is_active', true)
          .order('nomer_item',
              referencedTable: 'master_instrumen_item', ascending: true);

      return rows.map((row) => ItemAsesmenPsikologisModel.fromMap(row)).toList();
    });
  }

  static Future<void> deleteByAsesmenId(String asesmenId, String modifiedBy) {
    return DatabaseHelper.run('deleteByAsesmenId item_asesmen', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('asesmen_id', asesmenId);
    });
  }
}
