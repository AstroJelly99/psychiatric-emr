import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/domain/pasien/pasien_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DialogEditPasien extends StatefulWidget {
  final PasienProvider prov;
  final String pasienId;

  const DialogEditPasien({
    super.key,
    required this.prov,
    required this.pasienId,
  });

  @override
  State<DialogEditPasien> createState() => _DialogEditPasienState();
}

class _DialogEditPasienState extends State<DialogEditPasien> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.prov,
      child: Consumer<PasienProvider>(builder: (context, prov, _) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkBlock.fullWrap(
                padding: const EdgeInsets.all(15),
                children: [
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Nama Pasien",
                      controller: prov.nameTf,
                      hint: "Masukkan Nama Pasien",
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Alamat",
                      controller: prov.addressTf,
                      hint: "Masukkan Alamat Pasien",
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formField(
                      primaryText: "Jenis Kelamin",
                      secondaryText: "Gender",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          isExpanded: true,
                          hint: const Text('Pilih Jenis Kelamin'),
                          value: prov.gender,
                          items: const [
                            DropdownMenuItem<String>(
                              value: 'L',
                              child: Text('Laki-laki'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'P',
                              child: Text('Perempuan'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              prov.gender = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formField(
                      primaryText: "Tanggal Lahir",
                      secondaryText: "Birthdate",
                      child: InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: prov.birthdate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              prov.birthdate = selectedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Expanded + ellipsis: tanpa ini Row-nya
                              // overflow di lebar HP karena teks tanggal
                              // ("Pilih Tanggal Lahir" / "12 September 1998")
                              // tidak bisa menyusut di samping ikon kalender.
                              Expanded(
                                child: Text(
                                  prov.birthdate != null
                                      ? DateFormat('dd MMMM yyyy')
                                          .format(prov.birthdate!)
                                      : "Pilih Tanggal Lahir",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: prov.birthdate != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Nomor Telepon",
                      controller: prov.phoneTf,
                      // Boleh lebih dari satu nomor, satu baris per nomor
                      // — pasien dan keluarganya sering punya nomor
                      // berbeda-beda. inputFormatters kosong: formatter
                      // bawaan cuma mengizinkan huruf/angka/`,.` `/-?`,
                      // padahal label seperti "(Ayah)" butuh tanda kurung.
                      hint: "0812xxxx (Pasien)\n0813xxxx (Ayah)",
                      maxLines: 3,
                      inputFormatters: const [],
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Alergi",
                      controller: prov.allergyTf,
                      hint: "Masukkan Alergi (jika ada)",
                      keyboardType: TextInputType.text,
                    ),
                  ]),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}