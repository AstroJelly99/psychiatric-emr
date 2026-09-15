import 'package:flutter/material.dart';
import 'package:emr_homemade/data/models/instrumen_item_model.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class InstrumenItemDataTable extends DataTableSource {
  final void Function(int index, String actionType) onActionPressed;
  final List<InstrumenItemModel> data;

  InstrumenItemDataTable(
      {required this.onActionPressed, required this.data});

  @override
  DataRow getRow(int index) {
    final item = data[index];
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return index % 2 == 0 ? Colors.white : whitePrimary;
      }),
      cells: [
        DataCell(Text(item.nomerItem.toString())),
        DataCell(Text(item.pertanyaan)),
        DataCell(Text(item.teksPertanyaan)),
        DataCell(Text(item.kategoriSkoring)),
        DataCell(
          Row(
            children: [
              ElevatedButton(
                onPressed: () => onActionPressed(index, "edit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlueDef,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => onActionPressed(index, "delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                child: const Icon(
                  Icons.delete,
                  size: 20,
                  color: Colors.white,
                ),
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