import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/instrumen_model.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class InstrumenDataTable extends DataTableSource {
  final void Function(int index, String actionType) onActionPressed;
  final List<InstrumenModel> data;

  InstrumenDataTable({required this.onActionPressed, required this.data});

  @override
  DataRow getRow(int index) {
    final instrumen = data[index];
    return DataRow(
        color:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          return index % 2 == 0 ? Colors.white : whitePrimary;
        }),
        cells: [
          DataCell(Text(instrumen.versi)),
          DataCell(Text(instrumen.namaInstrumen)),
          DataCell(Text(instrumen.deskripsi)),
          DataCell(Text(instrumen.createdBy)),
          DataCell(
            Row(
              children: [
                ElevatedButton(
                    onPressed: () => onActionPressed(index, "edit"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlueDef,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10)),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    )),
                const SizedBox(width: 8),
                Tooltip(
                  message: "Atur Batas Interpretasi Skor",
                  child: ElevatedButton.icon(
                    onPressed: () => onActionPressed(index, "rules"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.rule, size: 18, color: Colors.white),
                    label: const Text(
                      "Interpretasi",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                instrumen.isActive
                    ? ElevatedButton(
                        onPressed: () => onActionPressed(index, "delete"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        child: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.white,
                        ))
                    : ElevatedButton(
                        onPressed: () => onActionPressed(index, "activate"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: blueHighlight,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        child: const Icon(
                          Icons.check,
                          size: 20,
                          color: Colors.white,
                        )),
              ],
            ),
          )
        ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
