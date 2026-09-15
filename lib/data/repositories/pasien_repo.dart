import '../models/model_converters.dart';
import '../models/pasien_model.dart';
import '../../database/database_helper.dart';

class PasienRepo {
  static const String _table = 'master_pasien';

  static Future<void> insert(PasienModel pasien) {
    return DatabaseHelper.run('insert pasien', () async {
      await DatabaseHelper.table(_table).insert({
        'pasien_id': pasien.pasienId,
        'patient_name': pasien.patientName,
        'patient_address': pasien.patientAddress,
        'patient_gender': pasien.patientGender,
        'patient_birthdate': dateToJson(pasien.patientBirthdate),
        'patient_phone': pasien.patientPhone,
        'patient_allergy': pasien.patientAllergy,
        'is_active': pasien.isActive,
        'create_date': timestampToJson(pasien.createDate),
        'created_by': pasien.createdBy,
      });
    });
  }

  static Future<void> update(PasienModel pasien) {
    return DatabaseHelper.run('update pasien', () async {
      await DatabaseHelper.table(_table).update({
        'patient_name': pasien.patientName,
        'patient_address': pasien.patientAddress,
        'patient_gender': pasien.patientGender,
        'patient_birthdate': dateToJson(pasien.patientBirthdate),
        'patient_phone': pasien.patientPhone,
        'patient_allergy': pasien.patientAllergy,
        'is_active': pasien.isActive,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': pasien.modifiedBy,
      }).eq('pasien_id', pasien.pasienId);
    });
  }

  static Future<List<PasienModel>> getAll() {
    return DatabaseHelper.run('getAll pasien', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .eq('is_active', true);
      return rows.map((row) => PasienModel.fromMap(row)).toList();
    });
  }

  static Future<PasienModel?> getById(String id) {
    return DatabaseHelper.run('getById pasien', () async {
      final row = await DatabaseHelper.table(_table)
          .select()
          .eq('pasien_id', id)
          .maybeSingle();
      if (row == null) return null;
      return PasienModel.fromMap(row);
    });
  }

  static Future<void> delete(String id, String modifiedBy) {
    return DatabaseHelper.run('delete pasien', () async {
      await DatabaseHelper.table(_table).update({
        'is_active': false,
        'modify_date': timestampToJson(DateTime.now()),
        'modified_by': modifiedBy,
      }).eq('pasien_id', id);
    });
  }

  // `.ilike` bukan `.like`: MySQL memakai collation case-insensitive, Postgres
  // tidak. Dengan `.like`, mencari "budi" tidak akan menemukan "Budi".
  static Future<List<PasienModel>> searchByName(String name) {
    return DatabaseHelper.run('searchByName pasien', () async {
      final rows = await DatabaseHelper.table(_table)
          .select()
          .ilike('patient_name', '%${DatabaseHelper.escapeLike(name)}%')
          .eq('is_active', true);
      return rows.map((row) => PasienModel.fromMap(row)).toList();
    });
  }

  static Future<bool> exists(String id) {
    return DatabaseHelper.run('exists pasien', () async {
      final rows = await DatabaseHelper.table(_table)
          .select('pasien_id')
          .eq('pasien_id', id)
          .limit(1);
      return rows.isNotEmpty;
    });
  }
}
