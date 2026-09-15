import '../models/model_converters.dart';
import '../models/obat_model.dart';
import '../../database/database_helper.dart';

class ObatRepo {
  static const String _tableObat = 'master_obat';
  static const String _tableInteraksi = 'drug_interaction';

  /// Embedded select pengganti dua LEFT JOIN ke master_obat.
  ///
  /// `mo1:obat_id_1(nama_obat)` menyuruh PostgREST mengikuti foreign key
  /// `fk_drug_interaction_obat1`. Hasilnya bersarang, jadi selalu lewat
  /// [_flattenInteraction] sebelum masuk ke DrugInteractionModel.fromMap.
  static const String _interactionSelect =
      '*, mo1:obat_id_1(nama_obat), mo2:obat_id_2(nama_obat)';

  /// Meratakan hasil embedded select jadi bentuk datar `nama_obat_1` /
  /// `nama_obat_2` — bentuk yang sama seperti alias JOIN di versi MySQL.
  static Map<String, dynamic> _flattenInteraction(Map<String, dynamic> row) {
    final mo1 = row['mo1'];
    final mo2 = row['mo2'];
    return {
      ...row,
      'nama_obat_1': mo1 is Map ? mo1['nama_obat'] : null,
      'nama_obat_2': mo2 is Map ? mo2['nama_obat'] : null,
    };
  }

  static Future<void> insert(ObatModel obat) {
    return DatabaseHelper.run('insert obat', () async {
      await DatabaseHelper.table(_tableObat).insert({
        'obat_id': obat.obatId,
        'nama_obat': obat.namaObat,
        'nama_generik': obat.namaGenerik,
        'kategori': obat.kategori,
        'deskripsi': obat.deskripsi,
        'is_active': obat.isActive,
        'create_date': timestampToJson(obat.createDate),
        'created_by': obat.createdBy,
      });
    });
  }

  static Future<void> update(ObatModel obat) {
    return DatabaseHelper.run('update obat', () async {
      await DatabaseHelper.table(_tableObat).update({
        'nama_obat': obat.namaObat,
        'nama_generik': obat.namaGenerik,
        'kategori': obat.kategori,
        'deskripsi': obat.deskripsi,
        'is_active': obat.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': obat.modifiedBy,
      }).eq('obat_id', obat.obatId);
    });
  }

  static Future<List<ObatModel>> getAll({int limit = 100, int offset = 0}) {
    return DatabaseHelper.run('getAll obat', () async {
      final rows = await DatabaseHelper.table(_tableObat)
          .select()
          .eq('is_active', true)
          .order('nama_obat', ascending: true)
          .range(offset, offset + limit - 1);
      return rows.map((row) => ObatModel.fromMap(row)).toList();
    });
  }

  static Future<ObatModel?> getById(String id) {
    return DatabaseHelper.run('getById obat', () async {
      final row = await DatabaseHelper.table(_tableObat)
          .select()
          .eq('obat_id', id)
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return ObatModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete obat', () async {
      await DatabaseHelper.table(_tableObat).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('obat_id', id);
    });
  }

  static Future<List<ObatModel>> searchByName(String name) {
    return DatabaseHelper.run('searchByName obat', () async {
      final pattern = '%${DatabaseHelper.escapeLike(name)}%';
      final rows = await DatabaseHelper.table(_tableObat)
          .select()
          // ilike, bukan like: Postgres LIKE case-sensitive (beda dari MySQL).
          .or('nama_obat.ilike.$pattern,nama_generik.ilike.$pattern')
          .eq('is_active', true)
          .order('nama_obat', ascending: true);
      return rows.map((row) => ObatModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists obat', () async {
      final rows = await DatabaseHelper.table(_tableObat)
          .select('obat_id')
          .eq('obat_id', id)
          .eq('is_active', true)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  static Future<List<ObatModel>> getByKategori(String kategori) {
    return DatabaseHelper.run('getByKategori obat', () async {
      final rows = await DatabaseHelper.table(_tableObat)
          .select()
          .eq('kategori', kategori)
          .eq('is_active', true)
          .order('nama_obat', ascending: true);
      return rows.map((row) => ObatModel.fromMap(row)).toList();
    });
  }

  static Future<void> insertInteraction(DrugInteractionModel interaction) {
    return DatabaseHelper.run('insertInteraction', () async {
      // obat_id_1 selalu lebih kecil dari obat_id_2 (lihat unique_drug_pair).
      final sortedIds = _sortObatIds(interaction.obatId1, interaction.obatId2);

      await DatabaseHelper.table(_tableInteraksi).insert({
        'interaction_id': interaction.interactionId,
        'obat_id_1': sortedIds[0],
        'obat_id_2': sortedIds[1],
        'severity_level': interaction.severityLevel.name,
        'deskripsi_interaksi': interaction.deskripsiInteraksi,
        'is_active': interaction.isActive,
        'create_date': timestampToJson(interaction.createDate),
        'created_by': interaction.createdBy,
      });
    });
  }

  static Future<void> updateInteraction(DrugInteractionModel interaction) {
    return DatabaseHelper.run('updateInteraction', () async {
      final sortedIds = _sortObatIds(interaction.obatId1, interaction.obatId2);

      await DatabaseHelper.table(_tableInteraksi).update({
        'obat_id_1': sortedIds[0],
        'obat_id_2': sortedIds[1],
        'severity_level': interaction.severityLevel.name,
        'deskripsi_interaksi': interaction.deskripsiInteraksi,
        'is_active': interaction.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': interaction.modifiedBy,
      }).eq('interaction_id', interaction.interactionId);
    });
  }

  static Future<DrugInteractionModel?> getInteractionById(String id) {
    return DatabaseHelper.run('getInteractionById', () async {
      final row = await DatabaseHelper.table(_tableInteraksi)
          .select(_interactionSelect)
          .eq('interaction_id', id)
          .eq('is_active', true)
          .maybeSingle();
      if (row == null) return null;
      return DrugInteractionModel.fromMap(_flattenInteraction(row));
    });
  }

  static Future<List<DrugInteractionModel>> getInteractionsByObatId(
      String obatId) {
    return DatabaseHelper.run('getInteractionsByObatId', () async {
      final rows = await DatabaseHelper.table(_tableInteraksi)
          .select(_interactionSelect)
          .or('obat_id_1.eq.$obatId,obat_id_2.eq.$obatId')
          .eq('is_active', true)
          // severity_level adalah enum native, jadi DESC tetap berarti
          // CONTRAINDICATED > MAJOR > MODERATE > MINOR, sama seperti MySQL.
          .order('severity_level', ascending: false)
          .order('create_date', ascending: false);
      return rows
          .map((row) => DrugInteractionModel.fromMap(_flattenInteraction(row)))
          .toList();
    });
  }

  static Future<int> getInteractionCount(String obatId) {
    return DatabaseHelper.run('getInteractionCount', () async {
      final response = await DatabaseHelper.table(_tableInteraksi)
          .select('interaction_id')
          .or('obat_id_1.eq.$obatId,obat_id_2.eq.$obatId')
          .eq('is_active', true)
          .count();
      return response.count;
    });
  }

  static Future<List<DrugInteractionModel>> checkMultipleInteractions(
      List<String> obatIds) {
    return DatabaseHelper.run('checkMultipleInteractions', () async {
      if (obatIds.length < 2) return <DrugInteractionModel>[];

      // RPC menyaring baris yang kedua obatnya ada di daftar; unique_drug_pair
      // + _sortObatIds menjamin pasangan tersimpan terurut, jadi tidak perlu
      // enumerasi pasangan manual (n² kondisi OR seperti versi MySQL lama).
      final rows = await DatabaseHelper.client.rpc(
        'check_multiple_interactions',
        params: {'p_obat_ids': obatIds},
      );

      return (rows as List)
          .map((row) =>
              DrugInteractionModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    });
  }

  static Future<void> deleteInteraction(
      String interactionId, String modifiedBy) {
    return DatabaseHelper.run('deleteInteraction', () async {
      await DatabaseHelper.table(_tableInteraksi).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('interaction_id', interactionId);
    });
  }

  static Future<List<DrugInteractionModel>> getAllInteractions() {
    return DatabaseHelper.run('getAllInteractions', () async {
      final rows = await DatabaseHelper.table(_tableInteraksi)
          .select(_interactionSelect)
          .eq('is_active', true)
          .order('severity_level', ascending: false)
          .order('create_date', ascending: false);
      return rows
          .map((row) => DrugInteractionModel.fromMap(_flattenInteraction(row)))
          .toList();
    });
  }

  /// Saran nama obat untuk autocomplete.
  ///
  /// Pengganti `SELECT DISTINCT nama_obat ... LOWER(nama_obat) LIKE LOWER(?)`.
  /// `DISTINCT` tidak punya padanan di PostgREST, jadi dedup dilakukan di
  /// sini — aman karena hasilnya sudah dibatasi [limit].
  static Future<List<String>> searchNamaObatSuggestions(String keyword,
      {int limit = 10}) {
    return DatabaseHelper.run('searchNamaObatSuggestions', () async {
      final rows = await DatabaseHelper.table(_tableObat)
          .select('nama_obat')
          .ilike('nama_obat', '%${DatabaseHelper.escapeLike(keyword)}%')
          .eq('is_active', true)
          .order('nama_obat', ascending: true)
          .limit(limit);

      final seen = <String>{};
      final hasil = <String>[];
      for (final row in rows) {
        final nama = asString(row['nama_obat']);
        if (nama.isNotEmpty && seen.add(nama.toLowerCase())) {
          hasil.add(nama);
        }
      }
      return hasil;
    });
  }

  /// Mencocokkan daftar nama obat dengan nama kanonik di master_obat.
  ///
  /// Menggantikan loop yang menjalankan satu query per obat. Lewat internet
  /// pola lama berarti 100-300 ms per obat; sekarang satu round-trip.
  /// Nama yang tidak cocok tidak muncul di hasil, sama seperti versi lama.
  static Future<List<String>> resolveDrugNames(List<String> names) {
    return DatabaseHelper.run('resolveDrugNames', () async {
      if (names.isEmpty) return <String>[];
      final rows = await DatabaseHelper.client.rpc(
        'resolve_drug_names',
        params: {'p_names': names},
      );
      return (rows as List)
          .map((row) => asString((row as Map)['nama_obat']))
          .where((nama) => nama.isNotEmpty)
          .toList();
    });
  }

  /// Interaksi yang melibatkan salah satu nama obat di [names].
  ///
  /// Mengembalikan baris mentah (bukan DrugInteractionModel) karena pemanggil
  /// di drug_interaction_provider membaca kolom `obat1_name` / `obat2_name`
  /// hasil RPC apa adanya — bentuk map-nya sama persis dengan hasil query
  /// JOIN versi MySQL.
  static Future<List<Map<String, dynamic>>> findInteractionsByDrugNames(
      List<String> names) {
    return DatabaseHelper.run('findInteractionsByDrugNames', () async {
      if (names.isEmpty) return <Map<String, dynamic>>[];
      final rows = await DatabaseHelper.client.rpc(
        'find_interactions_by_drug_names',
        params: {'p_names': names},
      );
      return (rows as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    });
  }

  static List<String> _sortObatIds(String id1, String id2) {
    final ids = [id1, id2];
    ids.sort();
    return ids;
  }

  static Future<bool> interactionExists(String obatId1, String obatId2) {
    return DatabaseHelper.run('interactionExists', () async {
      final sortedIds = _sortObatIds(obatId1, obatId2);

      final rows = await DatabaseHelper.table(_tableInteraksi)
          .select('interaction_id')
          .eq('obat_id_1', sortedIds[0])
          .eq('obat_id_2', sortedIds[1])
          .eq('is_active', true)
          .limit(1);
      return rows.isNotEmpty;
    });
  }

  static Future<List<DrugInteractionModel>> getInteractionsBySeverity(
      SeverityLevel severity) {
    return DatabaseHelper.run('getInteractionsBySeverity', () async {
      final rows = await DatabaseHelper.table(_tableInteraksi)
          .select(_interactionSelect)
          .eq('severity_level', severity.name)
          .eq('is_active', true)
          .order('create_date', ascending: false);
      return rows
          .map((row) => DrugInteractionModel.fromMap(_flattenInteraction(row)))
          .toList();
    });
  }
}
