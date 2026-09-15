import 'package:flutter/material.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:google_fonts/google_fonts.dart';

Widget defaultEditFieldDialog({
  required List<Widget> contents,
  required void Function() onClose,
}) {
  return defaultDialog(
    title: 'Edit Data',
    contents: contents,
    onClose: onClose,
  );
}

/// Dialog form serbaguna, dibangun di atas [Dialog], BUKAN [AlertDialog].
///
/// AlertDialog membungkus isinya dengan `IntrinsicWidth`, yang menyempitkan
/// dialog form ke lebar konten alih-alih lebar layar, dan membuat
/// `LayoutBuilder`/`SkBlock.lineWrap` di dalamnya error. Lebar di sini
/// dihitung dari [ConstrainedBox] + `maxWidth` sebagai gantinya, dan
/// `minWidth: 280` bawaan Material sengaja tidak dibawa (overflow di 320dp).
/// [actions] ditata [OverflowBar] (aman terhadap masalah intrinsic yang sama).
Widget defaultDialog({
  required List<Widget> contents,
  String title = "Information",
  void Function()? onClose,
  List<Widget>? actions,
  TextStyle? titleStyle,
  double maxWidth = 900,
}) {
  return Builder(
    builder: (context) {
      final Size screen = MediaQuery.of(context).size;
      final bool narrow = screen.width < 640;

      // Di HP margin 40px per sisi memakan seperempat layar; dikecilkan.
      final double inset = narrow ? 12 : 40;
      final double dialogWidth =
          (screen.width - inset * 2).clamp(0.0, maxWidth).toDouble();
      // Dibatasi supaya dialog tidak pernah lebih tinggi dari layar, tapi
      // tetap menyusut mengikuti isi kalau isinya pendek.
      final double maxHeight =
          screen.height * (narrow ? 0.9 : 0.85);

      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: maxHeight,
          ),
          child: Column(
            // min: tinggi mengikuti isi. stretch: isi memakai lebar penuh
            // dialog — inti dari perbaikan "field terlihat kecil".
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: titleStyle ??
                            Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onClose != null)
                      InkWell(
                        onTap: onClose,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            size: 24,
                            color: blackPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Flexible, bukan Expanded: kalau isinya pendek dialog ikut
              // pendek; kalau panjang barulah dia berhenti di maxHeight dan
              // isinya yang menggulung.
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.fromLTRB(
                      24, 0, 24, actions == null ? 24 : 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: contents,
                  ),
                ),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: actions,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Konfirmasi keluar akun.
///
/// Menggantikan `AlertDialog` polos berisi dua TextButton kecil yang dulu
/// dipakai. Ukurannya sengaja besar: ini satu-satunya aksi yang membuat dokter
/// kehilangan sesinya di tengah pemeriksaan, jadi tombolnya harus terbaca dan
/// tidak mudah tersentuh tanpa sengaja. Tombol batal ditaruh lebih dulu dan
/// dibuat setara besar, supaya jalan keluar yang aman bukan yang paling sulit.
Widget confirmLogoutDialog({
  required BuildContext context,
  required String username,
}) {
  final Size screen = MediaQuery.of(context).size;
  final bool narrow = screen.width < SkBlock.compactBreakpoint;
  final double inset = narrow ? 24 : 40;

  return Dialog(
    insetPadding: EdgeInsets.symmetric(horizontal: inset, vertical: 24),
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (screen.width - inset * 2).clamp(0.0, 420.0),
        // Nama pengguna yang panjang bisa membuat isi dialog melebihi tinggi
        // layar kecil (terukur 6px di 320×640). Dibatasi lalu digulung,
        // bukan dibiarkan meluber.
        maxHeight: screen.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    size: 38, color: Colors.red.shade600),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Keluar dari akun?",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: blackPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Anda akan keluar sebagai $username dan harus masuk kembali "
              "untuk membuka data pasien.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16,
                height: 1.45,
                color: greyText,
              ),
            ),
            const SizedBox(height: 26),
            // Menumpuk di HP lewat lineWrap; tinggi 52 supaya nyaman disentuh.
            SkBlock.lineWrap(
              responsive: true,
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "BATAL",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: blackPrimary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "YA, KELUAR",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

AlertDialog defaultDeactivateDialog({
  required void Function() onDelete,
  required void Function() onCancel,
}) =>
    AlertDialog(
      title: const Text("Non Aktifkan Data"),
      content: const Text("Apakah anda ingin menonaktifkan data ini ?"),
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
            "TIDAK",
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
            "YA",
            style: GoogleFonts.nunito(
              color: blackPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

AlertDialog defaultActivateDialog({
  required void Function() onActive,
  required void Function() onCancel,
}) =>
    AlertDialog(
      title: const Text("Aktifkan Data"),
      content: const Text("Apakah anda ingin mengaktifkan data ini ?"),
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
            "TIDAK",
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
          onTap: onActive,
          child: Text(
            "YA",
            style: GoogleFonts.nunito(
              color: blackPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

Future<T?> showErrorDialog<T>({required BuildContext context}) => showDialog(
      context: context,
      builder: (context) => defaultErrorDialog(),
    );

// [message] opsional: alasan sebenarnya (mis. dari `provider.errorMessage`),
// ditampilkan menggantikan "Coba ulangi lagi" yang generik. Tanpa ini dokter
// melihat dialog yang sama persis untuk SEMUA jenis kegagalan — termasuk
// yang sebetulnya bisa diperbaiki sendiri (mis. isian terlalu panjang) —
// dan tidak ada petunjuk sama sekali harus mengubah apa.
AlertDialog defaultErrorDialog({String? message}) => AlertDialog(
      title: const Text("Terjadi Kesalahan"),
      content: Text(message ?? "Coba ulangi lagi"),
    );

Future<T?> showInvalidDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
}) =>
    showDialog(
      context: context,
      builder: (context) => defaultInvalidDialog(
        context: context,
        title: title,
        content: content,
      ),
    );

AlertDialog defaultDownloadConfirmationDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
}) {
  return AlertDialog(
    icon: const Icon(Icons.download_rounded, color: blueHighlight, size: 40),
    title: title ??
        Text(
          "Download Excel",
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackPrimary,
          ),
        ),
    content: content ??
        Text(
          "Apakah anda yakin ingin mendownload laporan dalam format Excel?",
          style: GoogleFonts.nunito(fontSize: 14),
        ),
    actions: [
      SkBlock.freeButton(
        border: Border.all(
          color: blueHighlight,
          width: 4,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: blackPrimary,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        onTap: () => Navigator.of(context).pop(false),
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
        onTap: () => Navigator.of(context).pop(true),
        child: Text(
          "DOWNLOAD",
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

AlertDialog defaultInvalidDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
}) {
  return AlertDialog(
    title: title ?? const Text("Field Kosong !"),
    content: content ?? const Text("Pastikan field tidak kosong."),
    actions: [
      SkBlock.freeButton(
        color: blueHighlight,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        onTap: () => Navigator.of(context).pop(),
        child: Text(
          "OKE",
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

AlertDialog defaultConfirmationDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
}) {
  return AlertDialog(
    title: title ?? const Text("Konfirmasi Data"),
    content: content ?? const Text("Tambahkan data ini ?"),
    actions: [
      SkBlock.freeButton(
        border: Border.all(
          color: blueHighlight,
          width: 4,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: blackPrimary,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        onTap: () => Navigator.of(context).pop(false),
        child: Text(
          "TIDAK",
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
        onTap: () => Navigator.of(context).pop(true),
        child: Text(
          "YA",
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

AlertDialog defaultSuccessDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  void Function()? onFinish,
}) {
  return AlertDialog(
    title: title ?? const Text("Berhasil!"),
    content: content ?? const Text("Data Berhasil ditambahkan!"),
    actions: [
      SkBlock.freeButton(
        color: blueHighlight,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        onTap: () => Navigator.of(context).pop(true),
        child: Text(
          "OKE",
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

AlertDialog customDeleteInstrumenDialog({
  required BuildContext context,
  required String namaInstrumen,
  required void Function() onDelete,
  required void Function() onCancel,
}) {
  return AlertDialog(
    title: const Text("Hapus Instrumen?"),
    content: Text(
      "Anda yakin ingin menonaktifkan instrumen $namaInstrumen?",
    ),
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

AlertDialog customDeleteItemDialog({
  required BuildContext context,
  required String pertanyaan,
  required void Function() onDelete,
  required void Function() onCancel,
}) {
  return AlertDialog(
    title: const Text("Hapus Item Instrumen?"),
    content: Text("Anda yakin ingin menghapus item \"$pertanyaan\"?"),
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
