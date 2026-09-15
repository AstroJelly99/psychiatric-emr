import 'package:uuid/uuid.dart';

import 'model_converters.dart';

class PasienModel {
  String pasienId;
  String patientName;
  String patientAddress;
  String patientGender;
  DateTime patientBirthdate;
  String patientPhone;
  String patientAllergy;
  bool isActive;
  DateTime createDate;
  String createdBy;
  DateTime? modifyDate;
  String? modifiedBy;

  PasienModel({
    String? pasienId,
    required this.patientName,
    required this.patientAddress,
    required this.patientGender,
    required this.patientBirthdate,
    required this.patientPhone,
    this.patientAllergy = '',
    required this.isActive,
    DateTime? createDate,
    required this.createdBy,
    this.modifyDate,
    this.modifiedBy,
  })  : pasienId = pasienId ?? const Uuid().v4(),
        createDate = createDate ?? DateTime.now();


  PasienModel copyWith({
    String? pasienId,
    String? patientName,
    String? patientAddress,
    String? patientGender,
    DateTime? patientBirthdate,
    String? patientPhone,
    String? patientAllergy,
    bool? isActive,
    DateTime? createDate,
    String? createdBy,
    DateTime? modifyDate,
    String? modifiedBy,
  }) {
    return PasienModel(
      pasienId: pasienId ?? this.pasienId,
      patientName: patientName ?? this.patientName,
      patientAddress: patientAddress ?? this.patientAddress,
      patientGender: patientGender ?? this.patientGender,
      patientBirthdate: patientBirthdate ?? this.patientBirthdate,
      patientPhone: patientPhone ?? this.patientPhone,
      patientAllergy: patientAllergy ?? this.patientAllergy,
      isActive: isActive ?? this.isActive,
      createDate: createDate ?? this.createDate,
      createdBy: createdBy ?? this.createdBy,
      modifyDate: modifyDate ?? this.modifyDate,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pasien_id': pasienId,
      'patient_name': patientName,
      'patient_address': patientAddress,
      'patient_gender': patientGender,
      'patient_birthdate': dateToJson(patientBirthdate),
      'patient_phone': patientPhone,
      'patient_allergy': patientAllergy,
      'is_active': isActive,
      'create_date': timestampToJson(createDate),
      'created_by': createdBy,
      'modify_date': timestampToJsonOrNull(modifyDate),
      'modified_by': modifiedBy,
    };
  }

  factory PasienModel.fromMap(Map<String, dynamic> map) {
    return PasienModel(
      pasienId: asString(map['pasien_id']),
      patientName: asString(map['patient_name']),
      patientAddress: asString(map['patient_address']),
      patientGender: asString(map['patient_gender']),
      patientBirthdate: asDate(map['patient_birthdate']),
      patientPhone: asString(map['patient_phone']),
      patientAllergy: asString(map['patient_allergy']),
      isActive: asBool(map['is_active']),
      createDate: asDateTime(map['create_date']),
      createdBy: asString(map['created_by']),
      modifyDate: asDateTimeOrNull(map['modify_date']),
      modifiedBy: asStringOrNull(map['modified_by']),
    );
  }
}
