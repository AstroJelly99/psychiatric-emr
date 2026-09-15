import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class PanelButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String? text;
  final double? width;
  final TextAlign alignment;
  final bool activeState;
  final bool minimalState;
  final bool isAccordionHeader;
  final bool isItem;
  const PanelButton({
    super.key,
    required this.onTap,
    required this.activeState,
    required this.minimalState,
    this.isItem = false,
    this.icon,
    this.text,
    this.width,
    this.alignment = TextAlign.center,
    this.isAccordionHeader = false,
  });

  @override
  State<PanelButton> createState() => _PanelButtonState();
}

class _PanelButtonState extends State<PanelButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Ink(
          width: widget.width ?? MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(12),
          // Dulu halaman aktif cuma dibedakan putih vs whitePrimary
          // (#FFFFFF vs #F8F9FA) — beda 3 nilai warna, nyaris tak kelihatan
          // apalagi di daftar menu yang discroll. Sekarang latar biru muda +
          // garis kiri biru: sekali lirik langsung ketahuan sedang di menu
          // mana, tanpa harus baca teksnya dulu.
          decoration: BoxDecoration(
            color: widget.activeState ? blueLight : whitePrimary,
            border: Border(
              left: widget.activeState
                  ? const BorderSide(width: 4, color: blueHighlight)
                  : BorderSide.none,
              right: widget.isAccordionHeader
                  ? const BorderSide(width: 5, color: blueHighlight)
                  : BorderSide.none,
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: renderPanelButton(),
          ),
        ),
      ),
    );
  }

  Widget renderPanelButton() {
    if (widget.minimalState) {
      return Icon(
        widget.icon,
        size: 20,
        color: widget.activeState ? blueDark : Colors.grey[800],
      );
    } else {
      if (widget.isItem) {
        return Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.activeState ? blueDark : Colors.grey[800],
              ),
              const SizedBox(width: 8),
              Text(
                widget.text!,
                style: TextStyle(
                  fontWeight:
                      widget.activeState ? FontWeight.bold : FontWeight.normal,
                  color: widget.activeState ? Colors.black : Colors.grey[800],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      } else {
        return Row(
          children: [
            Icon(
              widget.icon,
              size: 20,
              color: widget.activeState ? blueDark : Colors.grey[800],
            ),
            const SizedBox(width: 8),
            Text(
              widget.text!,
              style: TextStyle(
                fontWeight:
                    widget.activeState ? FontWeight.bold : FontWeight.normal,
                color: widget.activeState ? Colors.black : Colors.grey[800],
                fontSize: 16,
              ),
            ),
          ],
        );
      }
    }
  }
}

class PanelHeader extends StatelessWidget {
  final VoidCallback onTap;
  final bool minimalState;
  const PanelHeader({
    super.key,
    required this.onTap,
    required this.minimalState,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          color: blueHighlight,
          child: Container(
            alignment: Alignment.centerLeft,
            height: 50,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topRight: Radius.circular(25)),
            ),
            child: minimalState
                ? const Icon(Icons.menu_open)
                : Text(
                    "MENU",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
