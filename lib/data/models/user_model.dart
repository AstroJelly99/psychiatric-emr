import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class UserModel {
  String userId;
  String username;
  String password;
  String name;
  String role;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  UserModel({
    String? userId,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : userId = userId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();

  /// Payload kolom tabel `master_user`.
  ///
  /// `password` TIDAK disertakan: kolomnya sudah dihapus dari database di
  /// 0001_init.sql karena kredensial pindah ke Supabase Auth. Field
  /// [password] di class ini masih ada supaya form yang sudah berjalan di
  /// lib/presentation/ tidak ikut pecah, tapi isinya tidak pernah dikirim
  /// maupun diterima dari server.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'name': name,
      'role': role,
      'is_active': isActive,
      'create_date': timestampToJson(createDate),
      'created_by': createdBy,
      'modify_date': timestampToJsonOrNull(modifyDate),
      'modified_by': modifiedBy,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: asStringOrNull(map['user_id']) ?? const Uuid().v4(),
      username: asString(map['username']),
      // Kolom `password` sudah tidak ada di server, jadi selalu ''.
      password: asString(map['password']),
      name: asString(map['name']),
      role: asString(map['role']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
