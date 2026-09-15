import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/data/repositories/instrumen_item_repo.dart';
import 'package:emr_homemade/domain/instrumen/instrumen_datatable.dart';
import 'package:emr_homemade/domain/instrumen/instrumen_provider.dart';
import 'package:emr_homemade/presentation/asesmen/interpretation_dialog.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:emr_homemade/utils/widgets/loading_widgets.dart';
import 'package:emr_homemade/utils/widgets/tables.dart';
import 'package:provider/provider.dart';

class InstrumenPage extends StatelessWidget {
  const InstrumenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InstrumenProvider(context),
      child: Consumer<InstrumenProvider>(
        builder: (context, prov, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  // IntrinsicHeight dilepas: syarat LayoutBuilder di dalam
                  // lineWrap responsif supaya tidak error.
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SkBlock.lineBlock(
                        text: "Atur Instrumen",
                        isHeader: true,
                        padding: const EdgeInsets.all(15),
                      ),
                      _insertField(context, prov),
                      SkBlock.lineWrap(responsive: true, children: [
                        SkBlock.lineBlock(
                          text: "Tabel Instrumen",
                          padding: const EdgeInsets.all(15),
                          isHeader: true,
                        ),
                      ]),
                      _filterField(prov),
                      _showTable(context, prov),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _filterField(InstrumenProvider prov) {
  return SkBlock.fullWrap(
    titleText: 'Filter Tabel',
    padding: const EdgeInsets.all(15),
    children: [
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.formTextField(
            primaryText: "Nama Instrumen",
            secondaryText: "Instrumen Name",
            controller: prov.namaInstrumenSearch,
            hint: "Cari Nama Instrumen",
            onChanged: (value) {
              if (prov.namaInstrumenSearch.text.isNotEmpty) {
                prov.changeFilter(true);
                prov.getInstrumenFilter(prov.namaInstrumenSearch.text);
              } else {
                prov.changeFilter(false);
                prov.getInstrumens();
              }
            }),
      ]),
    ],
  );
}

Widget _insertField(BuildContext context, InstrumenProvider prov) {
  return SkBlock.fullWrap(
      titleText: "Input Data Baru",
      padding: const EdgeInsets.all(15),
      children: [
        SkBlock.lineWrap(
          responsive: true,
          children: [
            SkBlock.formTextField(
                primaryText: "Versi",
                secondaryText: "Version *",
                controller: prov.versi,
                hint: "Masukkan Versi"),
            SkBlock.formTextField(
                primaryText: "Nama Instrumen",
                secondaryText: "Instrument Name *",
                controller: prov.namaInstrumen,
                hint: "Masukkan Nama Instrumen"),
            SkBlock.formTextField(
                primaryText: "Deskripsi",
                secondaryText: "Description",
                controller: prov.deskripsi,
                hint: "Masukkan Deskripsi"),
            SkBlock.button(
              context: context,
              onTap: () async {
                if (prov.formValid) {
                  bool? userConfirmed = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return defaultConfirmationDialog(
                          content: const Text("Tambahkan instrumen ini ?"),
                          context: context);
                    },
                  );

                  if (userConfirmed == true) {
                    final success = await prov.addInstrumen();
                    if (success && context.mounted) {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return defaultSuccessDialog(
                                context: context,
                                content: const Text(
                                    "Instrumen Berhasil ditambahkan!"));
                          });
                      prov.getInstrumens();
                      prov.clearForm();
                    } else if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return defaultErrorDialog();
                        },
                      );
                    }
                  }
                } else {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return defaultInvalidDialog(context: context);
                      });
                }
              },
              color: blueHighlight,
              text: "TAMBAH INSTRUMEN",
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              width: 280,
            ),
          ],
        ),
      ]);
}

List<DataColumn> _tableHeader(InstrumenProvider prov) => [
      DataColumn2(
          size: ColumnSize.S,
          onSort: (columnIndex, ascending) =>
              prov.onTableSort(columnIndex, ascending, (d) => d.versi),
          label: const Text("VERSI ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      DataColumn2(
          onSort: (columnIndex, ascending) =>
              prov.onTableSort(columnIndex, ascending, (d) => d.namaInstrumen),
          size: ColumnSize.S,
          label: const Text("NAMA INSTRUMEN",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      DataColumn2(
          size: ColumnSize.S,
          onSort: (columnIndex, ascending) =>
              prov.onTableSort(columnIndex, ascending, (d) => d.deskripsi),
          label: const Text("DESK",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      DataColumn2(
          size: ColumnSize.S,
          onSort: (columnIndex, ascending) =>
              prov.onTableSort(columnIndex, ascending, (d) => d.createdBy),
          label: const Text("CREATOR",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      const DataColumn2(
          size: ColumnSize.M,
          label: Text("AKSI",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
    ];

Widget _showTable(BuildContext context, InstrumenProvider prov) {
  return prov.isLoading
      ? defaultLoading()
      : SkBlock.fullWrap(
          padding: const EdgeInsets.all(15),
          children: [
            defaultTable(
              context: context,
              source: InstrumenDataTable(
                onActionPressed: (index, actionType) async {
                  final instrumen = prov.filteredInstrumens[index];

                  if (actionType == "edit") {
                    prov.setEditForm(instrumen);
                    _editInstrumenDialog(context, prov);
                  } else if (actionType == "rules") {
                    showDialog(
                      context: context,
                      builder: (context) => InterpretationRulesDialog(
                        instrumenId: instrumen.instrumenId,
                        instrumenName: instrumen.namaInstrumen,
                      ),
                    );
                  } 
                  else if (actionType == "delete") {
                    final hasItems = await InstrumenItemRepo.hasItems(
                        instrumen.instrumenId);

                    // Halaman bisa keburu ditutup selama await ini (query
                    // lewat internet, bukan instan seperti localhost).
                    if (!context.mounted) return;

                    if (hasItems) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Tidak Dapat Hapus"),
                          content: Text(
                              "Instrumen ${instrumen.namaInstrumen} tidak dapat dihapus karena masih memiliki item"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => customDeleteInstrumenDialog(
                          context: context,
                          namaInstrumen: instrumen.namaInstrumen,
                          onCancel: () => Navigator.pop(context),
                          onDelete: () async {
                            Navigator.pop(context);
                            await prov.deleteInstrumen(
                                instrumen.instrumenId, prov.createdBy!);
                            prov.getInstrumens();
                          },
                        ),
                      );
                    }
                  } 
                  else if (actionType == "activate") {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Aktifkan Instrumen?"),
                        content: Text(
                            "Anda yakin ingin mengaktifkan instrumen ${instrumen.namaInstrumen}?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Batal")),
                          TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                await prov.activateInstrumen(
                                    instrumen.instrumenId, prov.createdBy!);
                                prov.getInstrumens();
                              },
                              child: const Text("Aktifkan")),
                        ],
                      ),
                    );
                  }
                },
                data: prov.filteredInstrumens,
              ),
              sortAscending: prov.sortAscending,
              sortColumnIndex: prov.sortColumnIndex,
              columnCount: 5,
              columns: _tableHeader(prov),
            ),
          ],
        );
}

Future<dynamic> _editInstrumenDialog(
    BuildContext context, InstrumenProvider prov) {
  return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return defaultEditFieldDialog(
              onClose: () => Navigator.pop(context),
              contents: [
                DialogManageInstrumen(
                  prov: prov,
                ),
              ]);
        });
      });
}

class DialogManageInstrumen extends StatefulWidget {
  final InstrumenProvider prov;
  const DialogManageInstrumen({
    super.key,
    required this.prov,
  });

  @override
  State<DialogManageInstrumen> createState() => _DialogManageInstrumenState();
}

class _DialogManageInstrumenState extends State<DialogManageInstrumen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.prov,
      child: Consumer<InstrumenProvider>(builder: (context, prov, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkBlock.fullWrap(
              padding: const EdgeInsets.all(15),
              children: [
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                      primaryText: "Versi",
                      secondaryText: "Version *",
                      controller: prov.versiEdit,
                      hint: "Masukkan Versi"),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                      primaryText: "Nama Instrumen",
                      secondaryText: "Instrument Name *",
                      controller: prov.namaInstrumenEdit,
                      hint: "Masukkan Nama Instrumen"),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                      primaryText: "Deskripsi",
                      secondaryText: "Description",
                      controller: prov.deskripsiEdit,
                      hint: "Masukkan Deskripsi"),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.button(
                    context: context,
                    onTap: () async {
                      if (prov.editFormValid) {
                      bool? userConfirmed = await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return defaultConfirmationDialog(
                              content: const Text("Update instrumen ini?"),
                              context: context);
                        },
                      );

                      if (userConfirmed == true) {
                        final success = await prov.updateInstrumen();
                        if (success && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return defaultSuccessDialog(
                                  context: context,
                                  content: const Text(
                                      "Instrumen Berhasil diupdate!"));
                            },
                          ).then((_) {
                            if (context.mounted) Navigator.pop(context);
                            prov.getInstrumens();
                            prov.clearForm();
                          });
                        } else if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return defaultErrorDialog();
                            },
                          );
                        }
                      }
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return defaultInvalidDialog(context: context);
                        },
                      );
                    }
                  },
                  color: blueHighlight,
                  text: "UPDATE INSTRUMEN",
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  width: 280,
                  ),
                ]),
              ],
            ),
          ],
        );
      }),
    );
  }
}
