import 'package:flutter/material.dart';

class PanelFooter extends StatelessWidget {
  const PanelFooter({super.key});

  @override
  Widget build(BuildContext context) {
    // Footer ini ikut terjepit begitu sidebar diganti Drawer: di layar HP
    // padding 24 x 2 memakan porsi besar dari lebar yang tersedia.
    final bool narrow = MediaQuery.of(context).size.width < 640;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: narrow ? 12 : 24,
        vertical: narrow ? 10 : 16,
      ),
      // `Align` dibuang: Row dengan mainAxisAlignment.end sudah merapat ke
      // kanan, dan lapisan Align hanya menambah satu kotak tanpa guna.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.copyright,
            color: Colors.grey[600],
            size: 14,
          ),
          const SizedBox(width: 4),
          // Flexible + ellipsis: teks menyusut alih-alih menabrak tepi kalau
          // lebarnya tidak cukup. Tanpa ini, Row overflow di layar sempit.
          Flexible(
            child: Text(
              "2025 EMR Homemade. Internal Use Only",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
