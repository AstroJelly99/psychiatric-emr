import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/domain/instrumen_item/instrumen_item_datatable.dart';
import 'package:emr_homemade/domain/instrumen_item/instrumen_item_provider.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:emr_homemade/utils/widgets/loading_widgets.dart';
import 'package:emr_homemade/utils/widgets/tables.dart';
import 'package:provider/provider.dart';

class InstrumenItemPage extends StatelessWidget {
  const InstrumenItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InstrumenItemProvider(context),
      child: Consumer<InstrumenItemProvider>(
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
                        text: "Atur Item Instrumen",
                        isHeader: true,
                        padding: const EdgeInsets.all(15),
                      ),
                      _insertField(context, prov),
                      SkBlock.lineWrap(responsive: true, children: [
                        SkBlock.lineBlock(
                          text: "Tabel Item Instrumen",
                          padding: const EdgeInsets.all(15),
                          isHeader: true,
                        ),
                      ]),
                      _filterField(context, prov),
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

Widget _filterField(BuildContext context, InstrumenItemProvider prov) {
  return SkBlock.fullWrap(
    titleText: 'Filter Tabel',
    padding: const EdgeInsets.all(15),
    children: [
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.formDropdown(
          primaryText: "Filter Instrumen",
          secondaryText: "Pilih Instrumen",
          value: prov.selectedInstrumenFilter,
          items: prov.instrumens
              .map((instrumen) => DropdownMenuItem(
                    value: instrumen.instrumenId,
                    child: Text(instrumen.namaInstrumen),
                  ))
              .toList(),
          onChanged: (value) {
            prov.selectedInstrumenFilter = value;
            prov.applyFilters();
          },
        ),

        SkBlock.formTextField(
          primaryText: "Cari Pertanyaan",
          secondaryText: "Search Question",
          controller: prov.searchController,
          hint: "Masukkan kata kunci pencarian...",
          onChanged: (value) {
            prov.searchFilter = value;
            prov.applyFilters();
          },
        ),

        SkBlock.button(
          context: context,
          onTap: () {
            prov.resetFilters();
          },
          color: cyanDef,
          text: "RESET FILTER",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          width: 150,
        ),
      ]),
    ],
  );
}

Widget _insertField(BuildContext context, InstrumenItemProvider prov) {
  return SkBlock.fullWrap(
    titleText: "Input Data Baru",
    padding: const EdgeInsets.all(15),
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkBlock.formDropdown(
            primaryText: "Pilih Instrumen",
            secondaryText: "Select Instrument *",
            value: prov.selectedInstrumenFilter,
            items: prov.instrumens
                .map(
                  (instrumen) => DropdownMenuItem(
                    value: instrumen.instrumenId,
                    child: Text(instrumen.namaInstrumen),
                  ),
                )
                .toList(),
            onChanged: (value) {
              prov.selectedInstrumenFilter = value;
            },
          ),
          const SizedBox(height: 12),
          SkBlock.formTextField(
            primaryText: "Pertanyaan",
            secondaryText: "Question *",
            controller: prov.pertanyaan,
            hint: "Masukkan Pertanyaan",
          ),
          const SizedBox(height: 12),
          SkBlock.formTextField(
            primaryText: "Teks Pertanyaan",
            secondaryText: "Question Text *",
            controller: prov.teksPertanyaan,
            hint: "Masukkan Teks Pertanyaan",
          ),
          const SizedBox(height: 12),
          SkBlock.formTextField(
            primaryText: "Nomor Item",
            secondaryText: "Item Number *",
            controller: prov.nomerItem,
            hint: "Masukkan Nomor Item",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SkBlock.formScoringCategoryTextField(
            primaryText: "Kategori Skoring",
            secondaryText: "Scoring Category * (contoh: 1-10, 0-10)",
            controller: prov.kategoriSkoring,
            hint: "Masukkan Kategori Skoring (contoh: 1-10)",
          ),
          const SizedBox(height: 20),
          _responsiveButton(SkBlock.button(
            context: context,
            onTap: () async {
              if (prov.formValid) {
                bool? userConfirmed = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return defaultConfirmationDialog(
                      content: const Text("Tambahkan item instrumen ini?"),
                      context: context,
                    );
                  },
                );

                if (userConfirmed == true) {
                  final success = await prov.addInstrumenItem();
                  if (success && context.mounted) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return defaultSuccessDialog(
                          context: context,
                          content: const Text(
                              "Item Instrumen Berhasil ditambahkan!"),
                        );
                      },
                    );
                    prov.getInstrumenItems();
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
                  },
                );
              }
            },
            color: blueHighlight,
            text: "TAMBAH ITEM INSTRUMEN",
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            width: 280,
          )),
        ],
      ),
    ],
  );
}

/// Membungkus tombol berlebar tetap supaya ikut menyusut di layar sempit.
///
/// `SkBlock.button` di halaman ini memakai `width: 280` / `width: 150`, yang
/// pada lebar HP lebih besar dari ruang yang tersedia dan langsung overflow.
/// Dibungkus lineWrap responsif: di layar lebar tetap Row sehingga lebar
/// tetapnya dihormati persis seperti sekarang, di layar sempit jadi Column
/// dengan CrossAxisAlignment.stretch sehingga lebarnya mengikuti layar.
Widget _responsiveButton(Widget button) =>
    SkBlock.lineWrap(responsive: true, children: [button]);

List<DataColumn> _tableHeader(InstrumenItemProvider prov) => [
      DataColumn2(
        size: ColumnSize.S,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.nomerItem),
        label: const Text(
          "NO. ITEM",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.pertanyaan),
        size: ColumnSize.S,
        label: const Text(
          "PERTANYAAN",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.L,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.teksPertanyaan),
        label: const Text(
          "TEKS PERTANYAAN",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.kategoriSkoring),
        label: const Text(
          "KATEGORI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn2(
        size: ColumnSize.S,
        label: Text(
          "AKSI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    ];

Widget _showTable(BuildContext context, InstrumenItemProvider prov) {
  return prov.isLoading
      ? defaultLoading()
      : SkBlock.fullWrap(
          padding: const EdgeInsets.all(15),
          children: [
            defaultTable(
              context: context,
              responsive: true,
              source: InstrumenItemDataTable(
                onActionPressed: (index, actionType) {
                  final item = prov.filteredInstrumenItems[index];
                  if (actionType == "edit") {
                    prov.setEditForm(item);
                    _editInstrumenItemDialog(context, prov);
                  } else if (actionType == "delete") {
                    showDialog(
                      context: context,
                      builder: (context) => customDeleteItemDialog(
                        context: context,
                        // `pertanyaan` non-nullable di InstrumenItemModel,
                        // jadi `?? "Tanpa pertanyaan"` tidak pernah tercapai.
                        pertanyaan: item.pertanyaan,
                        onCancel: () => Navigator.pop(context),
                        onDelete: () async {
                          Navigator.pop(context);
                          await prov.deleteInstrumenItem(item.instrumenItemId);
                          prov.getInstrumenItems();
                        },
                      ),
                    );
                  }
                },
                data: prov.filteredInstrumenItems,
              ),
              sortAscending: prov.sortAscending,
              sortColumnIndex: prov.sortColumnIndex,
              columnCount: 5,
              columns: _tableHeader(prov),
            ),
          ],
        );
}

Future<dynamic> _editInstrumenItemDialog(
    BuildContext context, InstrumenItemProvider prov) {
  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return defaultEditFieldDialog(
            onClose: () {
              prov.clearEditForm();
              Navigator.pop(context);
            },
            contents: [
              DialogManageInstrumenItem(prov: prov),
            ],
          );
        },
      );
    },
  );
}

class DialogManageInstrumenItem extends StatefulWidget {
  final InstrumenItemProvider prov;
  const DialogManageInstrumenItem({super.key, required this.prov});

  @override
  State<DialogManageInstrumenItem> createState() =>
      _DialogManageInstrumenItemState();
}

class _DialogManageInstrumenItemState extends State<DialogManageInstrumenItem> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.prov,
      child: Consumer<InstrumenItemProvider>(
        builder: (context, prov, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkBlock.fullWrap(
                padding: const EdgeInsets.all(15),
                children: [
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formDropdown(
                      primaryText: "Pilih Instrumen",
                      secondaryText: "Select Instrument *",
                      value: prov.selectedInstrumenFilter,
                      items: prov.instrumens
                          .map((instrumen) => DropdownMenuItem(
                                value: instrumen.instrumenId,
                                child: Text(instrumen.namaInstrumen),
                              ))
                          .toList(),
                      onChanged: (value) {
                        prov.selectedInstrumenEdit = value;
                      },
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Pertanyaan",
                      secondaryText: "Question *",
                      controller: prov.editPertanyaan,
                      hint: "Masukkan Pertanyaan",
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Teks Pertanyaan",
                      secondaryText: "Question Text *",
                      controller: prov.editTeksPertanyaan,
                      hint: "Masukkan Teks Pertanyaan",
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formTextField(
                      primaryText: "Nomor Item",
                      secondaryText: "Item Number *",
                      controller: prov.editNomerItem,
                      hint: "Masukkan Nomor Item",
                      keyboardType: TextInputType.number,
                    ),
                  ]),
                  SkBlock.lineWrap(responsive: true, children: [
                    SkBlock.formScoringCategoryTextField(
                      primaryText: "Kategori Skoring",
                      secondaryText:
                          "Scoring Category * (contoh: 1-10, 0-10, A-E)",
                      controller: prov.editKategoriSkoring,
                      hint: "Masukkan Kategori Skoring (contoh: 1-10)",
                    ),
                  ]),
                  // defaultEditFieldDialog sekarang berbasis Dialog +
                  // ConstrainedBox, bukan AlertDialog lagi, jadi lineWrap
                  // responsif sudah aman dipakai di dalam dialog ini — dan
                  // tombolnya bisa kembali memakai lebar tetap 280 di layar
                  // lebar, menyusut penuh di layar sempit.
                  _responsiveButton(SkBlock.button(
                    context: context,
                    onTap: () async {
                      if (prov.editFormValid) {
                        bool? userConfirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return defaultConfirmationDialog(
                              content: const Text("Update item instrumen ini?"),
                              context: context,
                            );
                          },
                        );

                        if (userConfirmed == true) {
                          final success = await prov.updateInstrumenItem();
                          if (success && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return defaultSuccessDialog(
                                  context: context,
                                  content: const Text(
                                      "Item Instrumen Berhasil diupdate!"),
                                );
                              },
                            ).then((_) {
                              if (context.mounted) Navigator.pop(context);
                              prov.getInstrumenItems();
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
                    text: "UPDATE ITEM INSTRUMEN",
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    width: 280,
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
