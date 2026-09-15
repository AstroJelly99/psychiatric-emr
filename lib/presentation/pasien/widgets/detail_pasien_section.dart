import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/pasien_model.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DetailPasienSection extends StatelessWidget {
  final PasienModel pasien;

  const DetailPasienSection({super.key, required this.pasien});

  @override
  Widget build(BuildContext context) {
    return SkBlock.fullWrap(
      titleText: "Informasi Pasien",
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeaderSection(),
        const SizedBox(height: 20),
        _buildInfoList()
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: blueHighlight.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person,
              size: 32,
              color: blueHighlight,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pasien.patientName,
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: pasien.isActive ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pasien.isActive ? "AKTIF" : "NON-AKTIF",
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoList() {
    final items = [
      {
        "icon": Icons.person_outline,
        "label": "Jenis Kelamin",
        "value": pasien.patientGender == 'L' ? 'Laki-laki' : 'Perempuan',
        "iconColor": Colors.blue,
        "isCritical": false,
      },
      {
        "icon": Icons.cake_outlined,
        "label": "Tanggal Lahir",
        "value": DateFormat('dd MMM yyyy').format(pasien.patientBirthdate),
        "iconColor": Colors.purple,
        "isCritical": false,
      },
      {
        "icon": Icons.phone_outlined,
        "label": "Nomor Telepon",
        "value": pasien.patientPhone,
        "iconColor": Colors.green,
        "isCritical": false,
      },
      {
        "icon": Icons.home_outlined,
        "label": "Alamat",
        "value": pasien.patientAddress,
        "iconColor": Colors.orange,
        "isCritical": false,
      },
      if (pasien.patientAllergy.isNotEmpty)
        {
          "icon": Icons.warning_amber_rounded,
          "label": "Alergi",
          "value": pasien.patientAllergy,
          "iconColor": Colors.red,
          "isCritical": true,
        },
    ];

    return Column(
      children: items.map((item) {
        final isCritical = item["isCritical"] as bool;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isCritical ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCritical ? Colors.red.shade300 : Colors.grey.shade200,
              width: isCritical ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item["icon"] as IconData,
                  size: 22, color: item["iconColor"] as Color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item["label"] as String,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isCritical
                                ? Colors.red.shade700
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (isCritical) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "PERHATIAN",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item["value"] as String,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.red.shade700 : blueDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

}
