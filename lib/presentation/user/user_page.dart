import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/widgets/tables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/user/user_provider.dart';
import 'package:emr_homemade/data/models/user_model.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:emr_homemade/FBBlock/sk_block.dart';
import 'package:emr_homemade/utils/widgets/alert_dialogs.dart';
import 'package:emr_homemade/utils/widgets/loading_widgets.dart';
import 'package:data_table_2/data_table_2.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(context),
      child: Consumer<UserProvider>(
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
                        text: "Manajemen Data User",
                        isHeader: true,
                        padding: const EdgeInsets.all(15),
                      ),
                      _insertField(context, provider),
                      SkBlock.lineWrap(responsive: true, children: [
                        SkBlock.lineBlock(
                          text: "Tabel Data User",
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

Widget _filterField(BuildContext context, UserProvider prov) {
  return SkBlock.fullWrap(
    titleText: 'Filter Tabel',
    padding: const EdgeInsets.all(15),
    children: [
      SkBlock.lineWrap(responsive: true, children: [
        SkBlock.formTextField(
          primaryText: "Username/Nama",
          secondaryText: "Search User",
          controller: prov.usernameSearch,
          hint: "Cari berdasarkan username atau nama",
          onChanged: (value) {
            prov.performSearch(value);
          },
        ),
        SkBlock.button(
          context: context,
          onTap: () {
            prov.usernameSearch.clear();
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
    ],
  );
}

/// Form "Input Data User Baru" diganti panel keterangan.
///
/// Sejak kredensial pindah ke Supabase Auth, `master_user.user_id` adalah
/// foreign key ke `auth.users(id)`. Membuat baris user dari aplikasi selalu
/// ditolak server karena akun Auth-nya belum ada, dan membuat akun Auth butuh
/// service_role key — key yang melewati semua Row Level Security dan karena
/// itu tidak boleh ikut dibundel ke dalam .exe yang dipasang di komputer
/// klinik. Jadi tombolnya bukan dimatikan karena bug, tapi karena memang
/// jalurnya sekarang lewat Dashboard.
Widget _insertField(BuildContext context, UserProvider prov) {
  return SkBlock.fullWrap(
    titleText: "Tambah User",
    padding: const EdgeInsets.all(15),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: blueDark, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akun baru dibuat lewat Dashboard Supabase',
                  style: GoogleFonts.nunito(
                    color: blackPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Buat akunnya dulu di Authentication > Users dengan email '
                  '<username>@klinik.local, lalu tambahkan barisnya di tabel '
                  'master_user memakai user_id yang sama. Setelah itu user '
                  'akan muncul di daftar bawah ini.',
                  style: GoogleFonts.nunito(
                    color: blackPrimary,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

List<DataColumn> _tableHeader(UserProvider prov) => [
      DataColumn2(
        size: ColumnSize.M,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.username),
        label: const Text(
          "USERNAME",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.L,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.name),
        label: const Text(
          "NAMA LENGKAP",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn2(
        size: ColumnSize.M,
        onSort: (columnIndex, ascending) =>
            prov.onTableSort(columnIndex, ascending, (d) => d.role),
        label: const Text(
          "ROLE",
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

Widget _showTable(BuildContext context, UserProvider prov) {
  return prov.isLoading
      ? defaultLoading()
      : SkBlock.fullWrap(
          padding: const EdgeInsets.all(15),
          children: [
            prov.filteredUserList.isEmpty 
                ? const Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada data user',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : defaultTable(
                    context: context,
                    source: UserDataTable(
                      onActionPressed: (index, actionType) async {
                        final user = prov.filteredUserList[index];
                        if (actionType == "edit") {
                          prov.setEditForm(user);
                          _editUserDialog(context, prov);
                        } else if (actionType == "delete") {
                          showDialog(
                            context: context,
                            builder: (context) => customDeleteUserDialog(
                              context: context,
                              userName: user.name,
                              onCancel: () => Navigator.pop(context),
                              onDelete: () async {
                                Navigator.pop(context);
                                await prov.deleteUser(user.userId);
                                prov.refreshData();
                              },
                            ),
                          );
                        }
                      },
                      data: prov.filteredUserList,
                      provider: prov,
                    ),
                    sortAscending: prov.sortAscending,
                    sortColumnIndex: prov.sortColumnIndex,
                    columnCount: 5,
                    columns: _tableHeader(prov),
                  ),
          ],
        );
}

class UserDataTable extends DataTableSource {
  final void Function(int index, String actionType) onActionPressed;
  final List<UserModel> data;
  final UserProvider provider;

  UserDataTable({
    required this.onActionPressed,
    required this.data,
    required this.provider,
  });

  @override
  DataRow getRow(int index) {
    final user = data[index];
    return DataRow(
      color: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        return index % 2 == 0 ? Colors.white : whitePrimary;
      }),
      cells: [
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              user.username,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Tooltip(
              message: user.name,
              child: Text(
                user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getRoleColor(user.role),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(user.role),
                  size: 14,
                  color: _getRoleColor(user.role),
                ),
                const SizedBox(width: 6),
                Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(user.role),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user.isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: user.isActive ? Colors.green[300]! : Colors.red[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isActive ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: user.isActive ? Colors.green[800] : Colors.red[800],
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'Aktif' : 'Non-Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: user.isActive ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
              ElevatedButton(
                onPressed: () => onActionPressed(index, "delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Icon(Icons.delete, size: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'dokter':
        return Colors.blue;
      case 'perawat':
        return Colors.green;
      case 'it':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'dokter':
        return Icons.medical_services;
      case 'perawat':
        return Icons.health_and_safety;
      case 'it':
        return Icons.computer;
      default:
        return Icons.person;
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}

Future<dynamic> _editUserDialog(BuildContext context, UserProvider prov) {
  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return defaultEditFieldDialog(
          onClose: () => Navigator.pop(context),
          contents: [DialogManageUser(prov: prov)],
        );
      });
    },
  );
}

class DialogManageUser extends StatefulWidget {
  final UserProvider prov;
  const DialogManageUser({super.key, required this.prov});

  @override
  State<DialogManageUser> createState() => _DialogManageUserState();
}

class _DialogManageUserState extends State<DialogManageUser> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.prov,
      child: Consumer<UserProvider>(builder: (context, prov, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkBlock.fullWrap(
              padding: const EdgeInsets.all(15),
              children: [
                // Username dikunci: nilainya terikat ke email akun Auth
                // (<username>@klinik.local). Mengubahnya di sini tidak ikut
                // mengubah email di Supabase Auth, jadi user itu langsung
                // tidak bisa login lagi tanpa ada error apa pun yang muncul.
                //
                // Nama ikut dikunci mengikuti keputusan bahwa halaman ini
                // read-only kecuali role.
                //
                // Field "Password Baru" dihapus: kolom master_user.password
                // sudah tidak ada sejak 0001_init.sql, jadi isinya tidak
                // pernah terkirim ke mana pun. Reset password dilakukan dari
                // Dashboard Supabase.
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                    primaryText: "Username",
                    secondaryText: "Username (terkunci, terikat akun Auth)",
                    controller: prov.usernameEdit,
                    enabled: false,
                  ),
                  SkBlock.formTextField(
                    primaryText: "Nama Lengkap",
                    secondaryText: "Full Name (terkunci)",
                    controller: prov.nameEdit,
                    enabled: false,
                  ),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  SkBlock.formTextField(
                    primaryText: "Role",
                    secondaryText: "Role *",
                    controller: prov.roleEdit,
                    hint: "Masukkan Role",
                  ),
                ]),
                SkBlock.lineWrap(responsive: true, children: [
                  Row(
                    children: [
                      Checkbox(
                        value: prov.isActiveEdit,
                        onChanged: (value) {
                          prov.isActiveEdit = value ?? true;
                          prov.refreshUi();
                        },
                        activeColor: blueDef,
                      ),
                      Text(
                        'User Aktif',
                        style: GoogleFonts.nunito(
                          color: blackPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                            content: const Text("Update user ini?"),
                            context: context,
                          );
                        },
                      );

                      if (userConfirmed == true) {
                        final success = await prov.updateUser();
                        if (success && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return defaultSuccessDialog(
                                context: context,
                                content: const Text("User Berhasil diupdate!"),
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
                  text: "UPDATE USER",
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

AlertDialog customDeleteUserDialog({
  required BuildContext context,
  required String userName,
  required void Function() onDelete,
  required void Function() onCancel,
}) {
  return AlertDialog(
    title: const Text("Nonaktifkan User?"),
    content: Text("Anda yakin ingin menonaktifkan user $userName?"),
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
          "NONAKTIFKAN",
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