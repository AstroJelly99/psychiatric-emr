import 'package:flutter/material.dart';
import 'package:emr_homemade/data/repositories/obat_repo.dart';
import 'package:emr_homemade/utils/widgets/tables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/obat/obat_provider.dart';
import 'package:emr_homemade/data/models/obat_model.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/loading_widgets.dart';
import 'package:data_table_2/data_table_2.dart';

class DrugManagementPage extends StatelessWidget {
  const DrugManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ObatProvider(context),
      child: Consumer<ObatProvider>(
        builder: (context, provider, child) {
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
                        text: "Manajemen Data Obat",
                        isHeader: true,
                        padding: const EdgeInsets.all(15),
                      ),
                      _insertField(context, provider),
                      SkBlock.lineWrap(responsive: true, children: [
                        SkBlock.lineBlock(
                          text: "Tabel Data Obat",
                          padding: const EdgeInsets.all(15),
                          isHeader: true,
                        ),
                      ]),
                      _filterField(context, provider),
                      _showTable(context, provider),
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

Widget _filterField(BuildContext context, ObatProvider prov) {
  return SkBlock.fullWrap(
    titleText: 'Filter Tabel',
    padding: const EdgeInsets.all(15),
    children: [
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.formTextField(
          primaryText: "Nama Obat",
          secondaryText: "Drug Name",
          controller: prov.namaObatSearch,
          hint: "Cari Nama Obat atau Kategori",
          onChanged: (value) {
            prov.performSearch(value);
          },
        ),
        SkBlock.button(
          context: context,
          onTap: () {
            prov.namaObatSearch.clear();
            prov.performSearch(''); 
          },
          color: blueSec,
          text: "RESET FILTER",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          width: 200,
        ),
      ]),
      const SizedBox(height: 10),
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.button(
          context: context,
          onTap: () => _showAllInteractionsDialog(context, prov),
          color: Colors.orange,
          text: "LIHAT SEMUA INTERAKSI OBAT",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          width: 300,
        ),
      ]),
    ],
  );
}

Widget _insertField(BuildContext context, ObatProvider prov) {
  return SkBlock.fullWrap(
    titleText: "Input Data Obat Baru",
    padding: const EdgeInsets.all(15),
    children: [
      SkBlock.lineWrap(
        responsive: true,
        children: [
          SkBlock.formTextField(
            primaryText: "Nama Obat",
            secondaryText: "Drug Name *",
            controller: prov.namaObat,
            hint: "Masukkan Nama Obat",
          ),
          SkBlock.formTextField(
            primaryText: "Nama Generik",
            secondaryText: "Generic Name",
            controller: prov.namaGenerik,
            hint: "Masukkan Nama Generik",
          ),
          SkBlock.formTextField(
            primaryText: "Kategori",
            secondaryText: "Category *",
            controller: prov.kategori,
            hint: "Masukkan Kategori",
          ),
        ],
      ),
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.formTextField(
          primaryText: "Deskripsi",
          secondaryText: "Description",
          controller: prov.deskripsi,
          hint: "Masukkan Deskripsi Obat",
        ),
        SkBlock.button(
          context: context,
          onTap: () async {
            if (prov.formValid) {
              bool? userConfirmed = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return defaultConfirmationDialog(
                    content: const Text("Tambahkan obat ini?"),
                    context: context,
                  );
                },
              );

              if (userConfirmed == true) {
                final success = await prov.createObat();
                if (success && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return defaultSuccessDialog(
                        context: context,
                        content: const Text("Obat Berhasil ditambahkan!"),
                      );
                    },
                  );
                  prov.refreshData();
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
          text: "TAMBAH OBAT",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          width: 280,
        ),
      ]),
    ],
  );
}

List<DataColumn> _tableHeader(ObatProvider prov) => [
      DataColumn2(
        size: ColumnSize.M,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.namaObat),
        label: const Text(
          "NAMA OBAT",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.M,
        onSort: (columnIndex, ascending) => prov.onTableSort(
            columnIndex, ascending, (d) => d.namaGenerik ?? ''),
        label: const Text(
          "NAMA GENERIK",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.M,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.kategori),
        label: const Text(
          "KATEGORI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn2(
        size: ColumnSize.L,
        label: Text(
          "DESKRIPSI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn2(
        size: ColumnSize.M,
        label: Text(
          "INTERAKSI",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn2(
        size: ColumnSize.S,
        label: Text(
          "STATUS",
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

Widget _showTable(BuildContext context, ObatProvider prov) {
  return prov.isLoading
      ? defaultLoading()
      : SkBlock.fullWrap(
          padding: const EdgeInsets.all(15),
          children: [
            prov.filteredObatList.isEmpty 
                ? const Center(
                    child: Column(
                      children: [
                        Icon(Icons.medication_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data obat',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : defaultTable(
                    context: context,
                    source: ObatDataTable(
                      onActionPressed: (index, actionType) async {
                        final obat = prov.filteredObatList[
                            index]; 
                        if (actionType == "edit") {
                          prov.setEditForm(obat);
                          _editObatDialog(context, prov);
                        } else if (actionType == "delete") {
                          showDialog(
                            context: context,
                            builder: (context) => customDeleteObatDialog(
                              context: context,
                              namaObat: obat.namaObat,
                              onCancel: () => Navigator.pop(context),
                              onDelete: () async {
                                Navigator.pop(context);
                                await prov.deleteObat(obat.obatId);
                                prov.refreshData();
                              },
                            ),
                          );
                        } else if (actionType == "interaction") {
                          _showAddInteractionDialog(context, prov, obat);
                        } else if (actionType == "view_interactions") {
                          _showInteractionsDialog(context, prov, obat);
                        }
                      },
                      data: prov
                          .filteredObatList, 
                      provider: prov,
                    ),
                    sortAscending: prov.sortAscending,
                    sortColumnIndex: prov.sortColumnIndex,
                    columnCount:
                        7,
                    columns: _tableHeader(prov),
                  ),
          ],
        );
}

class ObatDataTable extends DataTableSource {
  final void Function(int index, String actionType) onActionPressed;
  final List<ObatModel> data;
  final ObatProvider provider;

  ObatDataTable({
    required this.onActionPressed,
    required this.data,
    required this.provider,
  });

  @override
  DataRow getRow(int index) {
    final obat = data[index];
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return index % 2 == 0 ? Colors.white : whitePrimary;
      }),
      cells: [
        DataCell(
          Text(
            obat.namaObat,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(Text(obat.namaGenerik ?? '-')),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: blueSec.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(obat.kategori, style: const TextStyle(fontSize: 12)),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Tooltip(
              message: obat.deskripsi ?? 'Tidak ada deskripsi',
              child: Text(
                obat.deskripsi ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        DataCell(
          FutureBuilder<int>(
            future: provider.getInteractionCount(obat.obatId),
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return InkWell(
                onTap: () => onActionPressed(index, "view_interactions"),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: count > 0 ? Colors.orange[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          count > 0 ? Colors.orange[300]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        count > 0 ? Icons.warning_amber : Icons.check_circle,
                        size: 14,
                        color: count > 0 ? Colors.orange[800] : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$count interaksi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              count > 0 ? Colors.orange[900] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: obat.isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              obat.isActive ? 'Aktif' : 'Non-Aktif',
              style: TextStyle(
                fontSize: 12,
                color: obat.isActive ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ElevatedButton(
                onPressed: () => onActionPressed(index, "edit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlueDef,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),  
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => onActionPressed(index, "interaction"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child:
                    const Icon(Icons.add_circle, size: 18, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => onActionPressed(index, "delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Icon(Icons.delete, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

Future<dynamic> _editObatDialog(BuildContext context, ObatProvider prov) {
  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return defaultEditFieldDialog(
          onClose: () => Navigator.pop(context),
          contents: [DialogManageObat(prov: prov)],
        );
      });
    },
  );
}

class DialogManageObat extends StatefulWidget {
  final ObatProvider prov;
  const DialogManageObat({super.key, required this.prov});

  @override
  State<DialogManageObat> createState() => _DialogManageObatState();
}

class _DialogManageObatState extends State<DialogManageObat> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.prov,
      child: Consumer<ObatProvider>(builder: (context, prov, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkBlock.fullWrap(
              padding: const EdgeInsets.all(15),
              children: [
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                    primaryText: "Nama Obat",
                    secondaryText: "Drug Name *",
                    controller: prov.namaObatEdit,
                    hint: "Masukkan Nama Obat",
                  ),
                  SkBlock.formTextField(
                    primaryText: "Nama Generik",
                    secondaryText: "Generic Name",
                    controller: prov.namaGenerikEdit,
                    hint: "Masukkan Nama Generik",
                  ),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                    primaryText: "Kategori",
                    secondaryText: "Category *",
                    controller: prov.kategoriEdit,
                    hint: "Masukkan Kategori",
                  ),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                    primaryText: "Deskripsi",
                    secondaryText: "Description",
                    controller: prov.deskripsiEdit,
                    hint: "Masukkan Deskripsi",
                  ),
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
                            content: const Text("Update obat ini?"),
                            context: context,
                          );
                        },
                      );

                      if (userConfirmed == true) {
                        final success = await prov.updateObat();
                        if (success && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return defaultSuccessDialog(
                                context: context,
                                content: const Text("Obat Berhasil diupdate!"),
                              );
                            },
                          ).then((_) {
                            if (context.mounted) Navigator.pop(context);
                            prov.refreshData();
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
                  text: "UPDATE OBAT",
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

AlertDialog customDeleteObatDialog({
  required BuildContext context,
  required String namaObat,
  required void Function() onDelete,
  required void Function() onCancel,
}) {
  return AlertDialog(
    title: const Text("Hapus Obat?"),
    content: Text("Anda yakin ingin menonaktifkan obat $namaObat?"),
    actions: [
      SkBlock.freeButton(
        border: Border.all(
          color: blueHighlight,
          width: 4,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: blackPrimary,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        onTap: onCancel,
        child: Text(
          "BATAL",
          style: GoogleFonts.nunito(
            color: blueHighlight,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      SkBlock.freeButton(
        color: blueHighlight,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        onTap: onDelete,
        child: Text(
          "HAPUS",
          style: GoogleFonts.nunito(
            color: blackPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ],
  );
}

class _InteractionFormState {
  ObatModel? selectedObat;
  SeverityLevel selectedSeverity = SeverityLevel.MODERATE;
  final TextEditingController deskripsiController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<ObatModel> filteredDrugs = [];
  bool isSubmitting = false;
}

void _showAddInteractionDialog(
    BuildContext context, ObatProvider provider, ObatModel obat) {
  final state = _InteractionFormState();

  List<ObatModel> availableDrugs = provider.obatList
      .where((drug) => drug.obatId != obat.obatId && drug.isActive)
      .toList();
  
  state.filteredDrugs = List.from(availableDrugs);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final Size screen = MediaQuery.of(context).size;
        final bool narrow = screen.width < SkBlock.compactBreakpoint;
        final double inset = narrow ? 12 : 20;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 800,
            constraints: BoxConstraints(
              maxHeight: narrow ? screen.height * 0.9 : 700,
            ),
            // Abu muda, bukan putih: isinya kartu putih, jadi latar putih
            // bikin batas antar-bagian hilang.
            color: Colors.grey.shade100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(narrow ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [blueHighlight, blueHighlight.withValues(alpha: 0.75)],
                    ),
                  ),
                  child: SkBlock.sectionHeader(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    leading: const Icon(Icons.medication_liquid,
                        color: Colors.black, size: 26),
                    title: 'Tambah Interaksi Obat',
                    titleMaxLines: 2,
                    titleStyle: GoogleFonts.nunito(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    subtitle: 'Obat utama: ${obat.namaObat}',
                    subtitleStyle: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 26, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(narrow ? 14 : 24),
                    child: Column(
                      children: [
                        _buildDrugSelectionSection(context, state, setState, availableDrugs),
                        const SizedBox(height: 20),
                        if (state.selectedObat != null)
                          _buildSelectedDrugCard(state.selectedObat!),
                        const SizedBox(height: 20),
                        _buildSeverityDescriptionSection(state, setState),
                      ],
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(narrow ? 14 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: SkBlock.lineWrap(
                  responsive: true,
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        "BATAL",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: state.isSubmitting || state.selectedObat == null || state.deskripsiController.text.isEmpty
                          ? null
                          : () async {
                              setState(() => state.isSubmitting = true);
                              await _saveInteraction(context, provider, obat, state, setState);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueHighlight,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        disabledBackgroundColor: Colors.grey[300],
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.black),
                              ),
                            )
                          : Text(
                              "SIMPAN INTERAKSI",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildDrugSelectionSection(BuildContext context, _InteractionFormState state, 
    void Function(void Function()) setState, List<ObatModel> availableDrugs) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: blueHighlight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pilih Obat Lain untuk Interaksi',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkBlueDef,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: state.searchController,
            decoration: InputDecoration(
              labelText: 'Cari Obat Lain',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: state.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        state.searchController.clear();
                        setState(() {
                          state.filteredDrugs = availableDrugs;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                state.filteredDrugs = availableDrugs
                    .where((drug) => drug.namaObat
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                    .toList();
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: state.filteredDrugs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Tidak ada obat tersedia',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: state.filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = state.filteredDrugs[index];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: state.selectedObat?.obatId == drug.obatId
                                ? blueHighlight.withValues(alpha: 0.2)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: state.selectedObat?.obatId == drug.obatId
                                  ? blueHighlight
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: state.selectedObat?.obatId == drug.obatId
                                ? blueHighlight
                                : Colors.grey,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          drug.namaObat,
                          style: TextStyle(
                            fontWeight: state.selectedObat?.obatId == drug.obatId
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          drug.kategori,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: state.selectedObat?.obatId == drug.obatId
                            ? Icon(Icons.check_circle, color: Colors.green[700])
                            : null,
                        onTap: () {
                          setState(() {
                            state.selectedObat = drug;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSelectedDrugCard(ObatModel selectedDrug) {
  return Card(
    color: Colors.green[50],
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obat Dipilih:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedDrug.namaObat,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Kategori: ${selectedDrug.kategori}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildSeverityDescriptionSection(_InteractionFormState state, void Function(void Function()) setState) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Detail Interaksi',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkBlueDef,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tingkat Keparahan Interaksi *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<SeverityLevel>(
                value: state.selectedSeverity,
                items: SeverityLevel.values.map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(severity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_getSeverityLabel(severity)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    state.selectedSeverity = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deskripsi Interaksi (dalam Bahasa Inggris) *',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: state.deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Jelaskan efek interaksi antara kedua obat...',
                  alignLabelWithHint: true,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 4),
              Text(
                '${state.deskripsiController.text.length} karakter',
                style: TextStyle(
                  fontSize: 12,
                  color: state.deskripsiController.text.isEmpty 
                      ? Colors.red 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _saveInteraction(BuildContext context, ObatProvider provider, 
    ObatModel obat, _InteractionFormState state, void Function(void Function()) setState) async {
  
  final exists = await ObatRepo.interactionExists(
    obat.obatId,
    state.selectedObat!.obatId,
  );
  
  if (exists && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Interaksi antara kedua obat sudah ada'),
        backgroundColor: Colors.orange[700],
      ),
    );
    setState(() => state.isSubmitting = false);
    return;
  }

  final interaction = DrugInteractionModel(
    obatId1: obat.obatId,
    obatId2: state.selectedObat!.obatId,
    namaObat1: obat.namaObat,
    namaObat2: state.selectedObat!.namaObat,
    severityLevel: state.selectedSeverity,
    deskripsiInteraksi: state.deskripsiController.text,
    isActive: true,
    createdBy: 'USER',
  );

  await provider.addInteraction(interaction);
  
  if (context.mounted) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Interaksi berhasil ditambahkan antara ${obat.namaObat} dan ${state.selectedObat!.namaObat}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

void _showInteractionsDialog(BuildContext context, ObatProvider provider, ObatModel obat) {
  // Future dibuat SEKALI di sini, bukan di dalam `builder:`.
  //
  // `builder:` milik showDialog dipanggil ulang setiap kali route dialog
  // rebuild. Memanggil getInteractions() di dalamnya berarti setiap rebuild
  // menembakkan query baru dan mengembalikan snapshot ke keadaan `waiting`,
  // sehingga spinner-nya bisa muncul lagi berulang kali dan hasil yang sudah
  // tampil hilang. Di harness tes hal ini membuat dialognya tidak pernah
  // selesai memuat sama sekali.
  final Future<List<DrugInteractionModel>> future =
      provider.getInteractions(obat.obatId);
  showDialog(
    context: context,
    builder: (context) => FutureBuilder<List<DrugInteractionModel>>(
      future: future,
      builder: (context, snapshot) {
        return _InteractionsDialog(
          title: 'Interaksi Obat: ${obat.namaObat}',
          snapshot: snapshot,
          provider: provider,
          obat: obat,
        );
      },
    ),
  );
}

void _showAllInteractionsDialog(BuildContext context, ObatProvider provider) {
  // Sama seperti _showInteractionsDialog: dibuat sekali, di luar `builder:`.
  final Future<List<DrugInteractionModel>> future =
      ObatRepo.getAllInteractions();
  showDialog(
    context: context,
    builder: (context) => FutureBuilder<List<DrugInteractionModel>>(
      future: future,
      builder: (context, snapshot) {
        return _InteractionsDialog(
          title: 'Semua Interaksi Obat',
          snapshot: snapshot,
          provider: provider,
          obat: null,
        );
      },
    ),
  );
}

class _InteractionsDialog extends StatelessWidget {
  final String title;
  final AsyncSnapshot<List<DrugInteractionModel>> snapshot;
  final ObatProvider provider;
  final ObatModel? obat;

  const _InteractionsDialog({
    required this.title,
    required this.snapshot,
    required this.provider,
    this.obat,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final bool narrow = screen.width < SkBlock.compactBreakpoint;
    final double inset = narrow ? 12 : 20;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
      child: Container(
        width: 1000,
        height: narrow ? screen.height * 0.88 : 700,
        padding: EdgeInsets.all(narrow ? 14 : 24),
        child: Column(
          children: [
            SkBlock.sectionHeader(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              title: title,
              titleMaxLines: 2,
              titleStyle: GoogleFonts.nunito(
                fontSize: narrow ? 19 : 20,
                fontWeight: FontWeight.bold,
                color: darkBlueDef,
              ),
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 26),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSubtitle(snapshot),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _buildContent(context, snapshot),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(AsyncSnapshot<List<DrugInteractionModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text('Memuat data interaksi...', style: TextStyle(color: Colors.grey));
    }
    
    final count = snapshot.data?.length ?? 0;
    return Text(
      'Total $count interaksi ditemukan',
      style: const TextStyle(fontSize: 15, color: Colors.grey),
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<List<DrugInteractionModel>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat data interaksi...'),
          ],
        ),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat interaksi: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final interactions = snapshot.data ?? [];

    if (interactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada interaksi yang tercatat',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _buildInteractionsTable(context, interactions);
  }

  Widget _buildInteractionsTable(BuildContext context, List<DrugInteractionModel> interactions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth.isFinite &&
            constraints.maxWidth < SkBlock.compactBreakpoint;
        if (compact) return _buildInteractionsCards(context, interactions);
        return _buildInteractionsWideTable(context, interactions);
      },
    );
  }

  /// Versi HP: tiap interaksi jadi satu kartu bertumpuk (tabel 4 kolom tidak
  /// muat di 360dp). Teks sengaja lebih besar dari versi tabel dan tombol
  /// aksi berlabel, bukan ikon — dialog ini dibaca dokter untuk memutuskan
  /// keamanan resep, jadi keterbacaannya bukan hiasan.
  Widget _buildInteractionsCards(
      BuildContext context, List<DrugInteractionModel> interactions) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: interactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final otherDrug = interaction.obatId1 == obat?.obatId
            ? interaction.namaObat2
            : interaction.namaObat1;
        final Color severityColor =
            _getSeverityColor(interaction.severityLevel);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: severityColor.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(13),
                    topRight: Radius.circular(13),
                  ),
                ),
                child: SkBlock.sectionHeader(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  title: otherDrug,
                  titleMaxLines: 2,
                  titleStyle: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: blackPrimary,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getSeverityLabel(interaction.severityLevel),
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interaction.deskripsiInteraksi,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        height: 1.45,
                        color: blackPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _showDescriptionDialog(
                            context,
                            interaction.deskripsiInteraksi,
                            namaObat1: interaction.namaObat1,
                            namaObat2: interaction.namaObat2,
                            severity: interaction.severityLevel,
                          ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          "Baca selengkapnya",
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: blueHighlight,
                            decoration: TextDecoration.underline,
                            decorationColor: blueHighlight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SkBlock.lineWrap(
                  responsive: true,
                  spacing: 10,
                  children: [
                    if (obat != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditInteractionDialog(
                              context, provider, interaction, obat!);
                        },
                        icon: const Icon(Icons.edit, size: 20),
                        label: Text("EDIT",
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: blueHighlight,
                          side: const BorderSide(color: blueHighlight),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteInteraction(
                        context, provider, interaction, obat,
                      ),
                      icon: const Icon(Icons.delete, size: 20),
                      label: Text("HAPUS",
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractionsWideTable(
      BuildContext context, List<DrugInteractionModel> interactions) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'OBAT LAIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'TINGKAT KEPARAHAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'DESKRIPSI INTERAKSI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'AKSI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                itemCount: interactions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
                itemBuilder: (context, index) {
                  final interaction = interactions[index];
                  final otherDrug = interaction.obatId1 == obat?.obatId 
                      ? interaction.namaObat2 
                      : interaction.namaObat1;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: index.isEven ? Colors.white : Colors.grey[50],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherDrug,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Interaksi dengan ${interaction.obatId1 == obat?.obatId ? interaction.namaObat1 : interaction.namaObat2}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(interaction.severityLevel).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getSeverityColor(interaction.severityLevel),
                              ),
                            ),
                            child: Text(
                              _getSeverityLabel(interaction.severityLevel),
                              style: TextStyle(
                                color: _getSeverityColor(interaction.severityLevel),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () => _showDescriptionDialog(
                                  context,
                                  interaction.deskripsiInteraksi,
                                  namaObat1: interaction.namaObat1,
                                  namaObat2: interaction.namaObat2,
                                  severity: interaction.severityLevel,
                                ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    interaction.deskripsiInteraksi,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Klik untuk melihat lengkap',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: blueHighlight,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (obat != null) // Only show edit in specific drug dialog
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18, color: blueHighlight),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditInteractionDialog(context, provider, interaction, obat!);
                                    },
                                    tooltip: 'Edit',
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  onPressed: () => _confirmDeleteInteraction(
                                    context, provider, interaction, obat,
                                  ),
                                  tooltip: 'Hapus',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [namaObat1] / [namaObat2] / [severity] wajib: tanpa itu dialog ini hanya
/// menampilkan paragraf lepas tanpa menyebut interaksi ANTARA apa. Dokter
/// membukanya dari daftar yang bisa berisi puluhan baris, jadi konteksnya
/// harus ikut terbawa, bukan diingat sendiri.
void _showDescriptionDialog(
  BuildContext context,
  String description, {
  required String namaObat1,
  required String namaObat2,
  required SeverityLevel severity,
}) {
  final Color severityColor = _getSeverityColor(severity);

  showDialog(
    context: context,
    builder: (context) {
      final Size screen = MediaQuery.of(context).size;
      final bool narrow = screen.width < SkBlock.compactBreakpoint;
      final double inset = narrow ? 12 : 40;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (screen.width - inset * 2).clamp(0.0, 600.0),
            maxHeight: screen.height * (narrow ? 0.85 : 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header menyebut pasangan obatnya, bukan judul generik.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                color: severityColor.withValues(alpha: 0.12),
                child: SkBlock.sectionHeader(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  title: '$namaObat1 + $namaObat2',
                  titleMaxLines: 2,
                  titleStyle: GoogleFonts.nunito(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: blackPrimary,
                  ),
                  subtitle: 'Tingkat keparahan: ${_getSeverityLabel(severity)}',
                  subtitleStyle: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 26),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Text(
                    description,
                    // 17px, bukan 14px: ini teks klinis yang dibaca utuh,
                    // bukan label tabel.
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      height: 1.6,
                      color: blackPrimary,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueHighlight,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'TUTUP',
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Color _getSeverityColor(SeverityLevel severity) {
  switch (severity) {
    case SeverityLevel.MINOR:
      return Colors.yellow[700]!;
    case SeverityLevel.MODERATE:
      return Colors.orange[700]!;
    case SeverityLevel.MAJOR:
      return Colors.red[700]!;
    case SeverityLevel.CONTRAINDICATED:
      return Colors.red[900]!;
  }
}

String _getSeverityLabel(SeverityLevel severity) {
  switch (severity) {
    case SeverityLevel.MINOR:
      return 'Minor';
    case SeverityLevel.MODERATE:
      return 'Moderate';
    case SeverityLevel.MAJOR:
      return 'Major';
    case SeverityLevel.CONTRAINDICATED:
      return 'Kontraindikasi';
  }
}

void _showEditInteractionDialog(BuildContext context, ObatProvider provider,
    DrugInteractionModel interaction, ObatModel obat) {
  SeverityLevel selectedSeverity = interaction.severityLevel;
  final deskripsiController = TextEditingController(text: interaction.deskripsiInteraksi);

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final Size screen = MediaQuery.of(context).size;
        final bool narrow = screen.width < SkBlock.compactBreakpoint;
        final double inset = narrow ? 12 : 40;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (screen.width - inset * 2).clamp(0.0, 600.0),
              maxHeight: screen.height * (narrow ? 0.88 : 0.85),
            ),
            child: SingleChildScrollView(
            padding: EdgeInsets.all(narrow ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkBlock.lineBlock(
                  text: 'Edit Interaksi Obat',
                  isHeader: true,
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                Text(
                  'Interaksi antara ${interaction.namaObat1} dan ${interaction.namaObat2}',
                  style: GoogleFonts.nunito(
                      fontSize: 15, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                SkBlock.fullWrap(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const Text('Interaction Severity Level :',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SeverityLevel>(
                      value: selectedSeverity,
                      items: SeverityLevel.values.map((severity) {
                        return DropdownMenuItem(
                          value: severity,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(severity),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getSeverityLabel(severity)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSeverity = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: deskripsiController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Interaksi dalam bahasa Inggris *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SkBlock.lineWrap(
                  responsive: true,
                  spacing: 12,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SkBlock.button(
                      context: context,
                      onTap: () => Navigator.pop(context),
                      color: Colors.grey,
                      text: "BATAL",
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      width: 120,
                    ),
                    SkBlock.button(
                      context: context,
                      onTap: () {
                        if (deskripsiController.text.isEmpty) return;
                        final updatedInteraction = DrugInteractionModel(
                          interactionId: interaction.interactionId,
                          obatId1: interaction.obatId1,
                          obatId2: interaction.obatId2,
                          namaObat1: interaction.namaObat1,
                          namaObat2: interaction.namaObat2,
                          severityLevel: selectedSeverity,
                          deskripsiInteraksi: deskripsiController.text,
                          isActive: true,
                          createdBy: interaction.createdBy,
                          createDate: interaction.createDate,
                          modifiedBy: 'USER',
                        );

                        provider.updateInteraction(updatedInteraction);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      color: blueHighlight,
                      text: "UPDATE INTERAKSI",
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15,
                      ),
                      width: 200,
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        );
      },
    ),
  );
}

void _confirmDeleteInteraction(BuildContext context, ObatProvider provider,
    DrugInteractionModel interaction, ObatModel? obat) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Konfirmasi Hapus Interaksi'),
      content: Text(
          'Yakin ingin menghapus interaksi antara "${interaction.namaObat1}" dan "${interaction.namaObat2}"?'),
      actions: [
        SkBlock.button(
          context: context,
          onTap: () => Navigator.pop(context),
          color: Colors.grey,
          text: "BATAL",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          width: 120,
        ),
        SkBlock.button(
          context: context,
          onTap: () {
            provider.deleteInteraction(interaction.interactionId);
            Navigator.pop(context);
            if (obat != null) {
              Navigator.pop(context);
            }
          },
          color: Colors.red,
          text: "HAPUS",
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          width: 120,
        ),
      ],
    ),
  );
}

class AppButton extends StatelessWidget {
  final String text;
  final Color color;
  final double width;
  final TextStyle textStyle;
  final VoidCallback? onPressed;

  const AppButton({
    super.key,
    required this.text,
    required this.color,
    required this.width,
    required this.textStyle,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Text(text, style: textStyle),
      ),
    );
  }
}