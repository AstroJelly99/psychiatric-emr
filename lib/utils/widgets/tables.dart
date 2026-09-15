import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/widgets/button.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

/// Ambang lebar tempat tabel berhenti masuk akal dan berganti jadi daftar
/// kartu. Nilainya sengaja sama dengan ambang yang sudah dipakai
/// [mainAppBar] di lib/utils/widgets/appbar.dart supaya seluruh aplikasi
/// berubah bentuk pada titik yang sama.
const double kTableCompactBreakpoint = 640;

void sort<T>({
  required Comparable<T> Function(T d) getField,
  required bool ascending,
  required List<T>? data,
}) {
  if (data != null) {
    data.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
  }
}

/// [responsive] true memilih mode berdasarkan lebar constraint parent
/// ([LayoutBuilder]) alih-alih lebar layar ([MediaQuery]) — beda nyata,
/// karena tabel ini hidup di area konten PanelPage yang lebih sempit dari
/// layar (dipotong sidebar + padding). Opt-in, bukan default, karena
/// LayoutBuilder error di bawah leluhur `IntrinsicHeight` yang masih dipakai
/// sebagian halaman pemanggil.
Widget defaultTable(
    {required BuildContext context,
    required DataTableSource source,
    required int columnCount,
    required bool sortAscending,
    required int? sortColumnIndex,
    required List<DataColumn> columns,
    int rowsPerPage = 10,
    bool responsive = false,
    double headingRowHeight = 64}) {
  Widget build(double availableWidth) {
    if (availableWidth < kTableCompactBreakpoint) {
      return _CompactTableList(
        source: source,
        columns: columns,
        rowsPerPage: rowsPerPage,
      );
    }
    return _wideTable(
      context: context,
      source: source,
      columnCount: columnCount,
      sortAscending: sortAscending,
      sortColumnIndex: sortColumnIndex,
      columns: columns,
      rowsPerPage: rowsPerPage,
      headingRowHeight: headingRowHeight,
    );
  }

  if (!responsive) {
    return build(MediaQuery.of(context).size.width);
  }

  return LayoutBuilder(
    builder: (context, constraints) => build(
      constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width,
    ),
  );
}

Widget _wideTable(
    {required BuildContext context,
    required DataTableSource source,
    required int columnCount,
    required bool sortAscending,
    required int? sortColumnIndex,
    required List<DataColumn> columns,
    required int rowsPerPage,
    required double headingRowHeight}) {
  // Tinggi mengikuti isi, bukan selalu `rowsPerPage`. Sebelumnya tabel dengan
  // 2 baris tetap memesan tinggi untuk 10 baris, dan itu sebab utama tabel
  // terpotong di layar pendek. PaginatedDataTable2 tetap butuh tinggi yang
  // berbatas, jadi tingginya dihitung, bukan dihapus sama sekali.
  final int visibleRows =
      source.rowCount < rowsPerPage ? source.rowCount : rowsPerPage;
  final int rowsForHeight = visibleRows <= 0 ? 1 : visibleRows;
  final double tableHeight = (kMinInteractiveDimension + 7) * rowsForHeight +
      headingRowHeight +
      kMinInteractiveDimension; // baris kontrol paginasi di bawah tabel

  ScrollController controller = ScrollController();
  return Scrollbar(
    controller: controller,
    child: SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      child: SelectionArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(25)),
          child: SizedBox(
            width: defaultTableWidth(context, columnCount),
            height: tableHeight,
            child: PaginatedDataTable2(
              empty: errorTableView(),
              dividerThickness: 0,
              border: defaultTableBorder(),
              source: source,
              headingRowHeight: headingRowHeight,
              columnSpacing: 56,
              rowsPerPage: rowsPerPage,
              headingRowDecoration: const BoxDecoration(color: blueSec),
              columns: columns,
              isHorizontalScrollBarVisible: false,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              sortArrowAlwaysVisible: false,
              sortArrowAnimationDuration: const Duration(milliseconds: 500), //
              sortArrowBuilder: (ascending, sorted) => Stack(
                children: [
                  Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: SortButton(
                          ascending: true, active: sorted && ascending)),
                  Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: SortButton(
                          ascending: false, active: sorted && !ascending)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Versi layar sempit dari [defaultTable]: tiap baris jadi satu kartu
/// bertumpuk, membaca [DataTableSource] yang sama persis (tidak ada logika
/// data terduplikasi).
///
/// Sengaja [Column], bukan [ListView]: tabel selalu di dalam
/// `SingleChildScrollView` milik halaman (tinggi tak berbatas), jadi ListView
/// di situ wajib `shrinkWrap` — yang tetap melayout SELURUH anak, jadi tidak
/// ada untung virtualisasi yang biasanya jadi alasan memilih ListView. Batas
/// jumlah baris ditangani tombol "muat lebih banyak", bukan virtualisasi.
///
/// Baris ditampilkan bertahap per `rowsPerPage`: `ObatDataTable.getRow`
/// memuat satu `FutureBuilder` per baris untuk hitung interaksi, jadi
/// merender semua baris sekaligus menembak ratusan query bersamaan.
class _CompactTableList extends StatefulWidget {
  const _CompactTableList({
    required this.source,
    required this.columns,
    required this.rowsPerPage,
  });

  final DataTableSource source;
  final List<DataColumn> columns;
  final int rowsPerPage;

  @override
  State<_CompactTableList> createState() => _CompactTableListState();
}

class _CompactTableListState extends State<_CompactTableList> {
  late int _visible = widget.rowsPerPage;

  @override
  Widget build(BuildContext context) {
    final int total = widget.source.rowCount;
    if (total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: errorTableView(),
      );
    }

    final int shown = _visible < total ? _visible : total;

    final List<Widget> children = [];
    for (var i = 0; i < shown; i++) {
      final DataRow? row = widget.source.getRow(i);
      if (row == null) continue;
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRowCard(row),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "Menampilkan $shown dari $total data",
            style: const TextStyle(fontSize: 12, color: greyText),
            textAlign: TextAlign.center,
          ),
        ),
        if (shown < total)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _visible = shown + widget.rowsPerPage),
              icon: const Icon(Icons.expand_more, size: 18),
              label: const Text("MUAT LEBIH BANYAK"),
              style: OutlinedButton.styleFrom(
                foregroundColor: blueHighlight,
                side: const BorderSide(color: blueHighlight),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRowCard(DataRow row) {
    // Kolom dan sel dipasangkan berdasarkan posisi, persis seperti yang
    // dilakukan DataTable. Panjangnya dijaga supaya sumber yang mengembalikan
    // jumlah sel berbeda dari jumlah kolom tidak menjatuhkan aplikasi.
    final int fieldCount = row.cells.length < widget.columns.length
        ? row.cells.length
        : widget.columns.length;

    final List<Widget> fields = [];
    for (var j = 0; j < fieldCount; j++) {
      final DataCell cell = row.cells[j];

      Widget value = DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, color: blackPrimary),
        child: cell.child,
      );
      if (cell.onTap != null) {
        value = InkWell(onTap: cell.onTap, child: value);
      }

      fields.add(
        Padding(
          padding: EdgeInsets.only(bottom: j == fieldCount - 1 ? 0 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle.merge(
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: greyText,
                ),
                child: widget.columns[j].label,
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: value),
            ],
          ),
        ),
      );
    }

    final Widget card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Warna belang-belang dari sumber tetap dihormati supaya identitas
        // visualnya sama dengan mode tabel.
        color: row.color?.resolve(<WidgetState>{}) ?? whiteCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields,
      ),
    );

    if (row.onSelectChanged == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => row.onSelectChanged!(true),
      child: card,
    );
  }
}

Widget errorTableView() {
  return const Center(
    child: Text(
      "Tidak Ada / Gagal Memuat Data",
      style: TextStyle(fontSize: 22.0),
    ),
  );
}

TableBorder defaultTableBorder() {
  return const TableBorder(
      horizontalInside: BorderSide.none,
      verticalInside:
          BorderSide(width: 10, style: BorderStyle.solid, color: Colors.white));
}

/// Hanya dipakai oleh jalur tabel lebar. Cabang `< 640` di bawah sekarang
/// tidak pernah tercapai lewat [defaultTable] karena lebar segitu sudah
/// dialihkan ke [_CompactTableList]; cabangnya dibiarkan supaya tanda tangan
/// fungsi publik ini tidak berubah.
double defaultTableWidth(BuildContext context, int columnCount) {
  if (MediaQuery.of(context).size.width >= 1000) {
    return MediaQuery.of(context).size.width / 1.6 + (columnCount * 100);
  } else if (MediaQuery.of(context).size.width >= 640) {
    return MediaQuery.of(context).size.width + (columnCount * 100);
  } else {
    return MediaQuery.of(context).size.width * 2 + (columnCount * 100);
  }
}
