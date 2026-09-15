import 'package:flutter/material.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onTap;
  final double borderRadius;
  final Color? color;
  final Icon? icon;
  final String? text;
  final Color? textColor;
  final FontWeight fontWeight;
  final double? width;
  final TextAlign alignment;
  const CustomElevatedButton(
      {super.key,
      required this.onTap,
      this.borderRadius = 6,
      this.color,
      this.icon,
      this.text,
      this.width,
      this.fontWeight = FontWeight.normal,
      this.alignment = TextAlign.center,
      this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        color == Colors.transparent
            ? const BoxShadow(color: Colors.transparent)
            : BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Colors.grey[300]!,
                spreadRadius: 1.0,
                blurRadius: 4.0,
              )
      ]),
      child: Material(
        type: MaterialType.canvas,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
              width: width ?? MediaQuery.of(context).size.width,
              padding: icon == null
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
              ),
              child: icon == null
                  ? text == null
                      ? const SizedBox()
                      : Text(
                          text!,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: fontWeight),
                          textAlign: alignment,
                        )
                  : text == null
                      ? icon!
                      : Row(
                          children: [
                            icon!,
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              text!,
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: fontWeight),
                            )
                          ],
                        )),
        ),
      ),
    );
  }
}

class NavbarButton extends StatelessWidget {
  final VoidCallback onTap;
  final double borderRadius;
  final Color? color;
  final Icon? icon;
  final String? text;
  final TextStyle textStyle;
  final double? width;
  final TextAlign alignment;
  const NavbarButton(
      {super.key,
      required this.onTap,
      this.borderRadius = 6,
      this.color,
      this.icon,
      this.text,
      this.width,
      this.alignment = TextAlign.center,
      this.textStyle = const TextStyle(fontSize: 16, color: Colors.black)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        color == Colors.transparent
            ? const BoxShadow(color: Colors.transparent)
            : BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Colors.grey[300]!,
                spreadRadius: 1.0,
                blurRadius: 4.0,
              )
      ]),
      child: Material(
        type: MaterialType.canvas,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
              width: width ?? MediaQuery.of(context).size.width,
              padding: icon == null
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
              ),
              child: icon == null
                  ? text == null
                      ? const SizedBox()
                      : Text(
                          text!,
                          style: textStyle,
                          textAlign: alignment,
                        )
                  : text == null
                      ? icon!
                      : Row(
                          children: [
                            icon!,
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              text!,
                              style: textStyle,
                            )
                          ],
                        )),
        ),
      ),
    );
  }
}

class SortButton extends StatefulWidget {
  final bool ascending;
  final bool active;

  const SortButton({super.key, required this.ascending, required this.active});

  @override
  State<SortButton> createState() => _SortButtonState();
}

class _SortButtonState extends State<SortButton> {
  @override
  Widget build(BuildContext context) {
    return Icon(
      widget.ascending
          ? Icons.arrow_drop_up_rounded
          : Icons.arrow_drop_down_rounded,
      size: 28,
      color: widget.active ? blackPrimary : whitePrimary,
    );
  }
}
