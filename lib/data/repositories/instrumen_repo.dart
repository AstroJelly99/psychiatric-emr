import '../models/instrumen_model.dart';
import '../models/model_converters.dart';
import '../../database/database_helper.dart';

class InstrumenRepo {
  static const String _table = 'master_instrumen';

  static Future<void> insert(InstrumenModel instrumen) {
    return DatabaseHelper.run('insert instrumen', () async {
      await DatabaseHelper.table(_table).insert({
        'instrumen_id': instrumen.instrumenId,
        'versi': instrumen.versi,
        'nama_instrumen': instrumen.namaInstrumen,
        'deskripsi': instrumen.deskripsi,
        'is_active': instrumen.isActive,
        'create_date': timestampToJson(instrumen.createDate),
        'created_by': instrumen.createdBy,
      });
    });
  }

  static Future<void> update(InstrumenModel instrumen) {
    return DatabaseHelper.run('update instrumen', () async {
      await DatabaseHelper.table(_table).update({
        'versi': instrumen.versi,
        'nama_instrumen': instrumen.namaInstrumen,
        'deskripsi': instrumen.deskripsi,
        'is_active': instrumen.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': instrumen.modifiedBy,
      }).eq('instrumen_id', instrumen.instrumenId);
    });
  }

  static Future<List<InstrumenModel>> getAll() {
    return DatabaseHelper.run('getAll instrumen', () async {
      final rows =
          await DatabaseHelper.table(_table).select().eq('is_active', true);
      return rows.map((row) => InstrumenModel.fromMap(row)).toList();
    });
  }

  static Future<InstrumenModel?> getById(String id) {
    return DatabaseHelper.run('getById instrumen', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('instrumen_id', id)
          .maybeSingle();
      if (row == null) return null;
      return InstrumenModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete instrumen', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('instrumen_id', id);
    });
  }

  static Future<List<InstrumenModel>> searchByName(String name) {
    return DatabaseHelper.run('searchByName instrumen', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          // ilike, bukan like: Postgres LIKE case-sensitive (beda dari MySQL).
          .ilike('nama_instrumen', '%${DatabaseHelper.escapeLike(name)}%')
          .eq('is_active', true);
      return rows.map((row) => InstrumenModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists instrumen', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('instrumen_id')
          .eq('instrumen_id', id)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  static Future<void> activate(String id, String modifiedBy) {
    return DatabaseHelper.run('activate instrumen', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': true,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('instrumen_id', id);
    });
  }
}
