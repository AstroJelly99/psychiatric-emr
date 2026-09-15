part of 'sk_block.dart';

class _FreeButton extends StatelessWidget {
  final VoidCallback onTap;
  final double borderRadius;
  final Color? color;
  final Icon? icon;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Widget? child;
  final double? width;
  const _FreeButton(
      {required this.onTap,
      this.borderRadius = 12.0,
      this.padding,
      this.border,
      this.color,
      this.icon,
      this.child,
      this.width});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: Material(
        type: MaterialType.canvas,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
              padding: padding,
              decoration: BoxDecoration(
                border: border,
                color: color ?? blueHighlight,
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
              ),
              child: icon == null
                  ? child
                  : Row(
                      children: [
                        icon!,
                        const SizedBox(
                          width: 8,
                        ),
                        child ?? const SizedBox()
                      ],
                    )),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Widget? icon;
  final SkIconAlignment? iconAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final String? text;
  final TextStyle? textStyle;
  final double? width;
  final TextAlign textAlign;
  const _Button(
      {required this.context,
      required this.onTap,
      this.borderRadius = 12,
      this.textAlign = TextAlign.center,
      required this.mainAxisAlignment,
      this.padding,
      this.color,
      this.icon,
      this.iconAlignment = SkIconAlignment.start,
      this.text,
      this.textStyle,
      this.width});

  @override
  Widget build(BuildContext context) {
    final Widget textItem = Text(
      text!,
      style: textStyle ??
          const TextStyle(
              color: null, fontSize: 16, fontWeight: FontWeight.normal),
      textAlign: textAlign,
    );

    final Widget child;
    if (icon == null) {
      if (text == null) {
        child = const SizedBox();
      } else {
        child = textItem;
      }
    } else {
      if (text == null) {
        child = icon!;
      } else {
        switch (iconAlignment) {
          case SkIconAlignment.start:
            child = Row(
              children: [
                icon!,
                const SizedBox(
                  width: 8,
                ),
                textItem
              ],
            );
            break;
          case SkIconAlignment.end:
            child = Row(
              mainAxisAlignment: mainAxisAlignment,
              children: [
                textItem,
                const SizedBox(
                  width: 8,
                ),
                icon!,
              ],
            );
          default:
            child = Row(
              children: [
                icon!,
                const SizedBox(
                  width: 8,
                ),
                textItem
              ],
            );
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: InnerShadow(
        shadows: const [
          Shadow(
              blurRadius: 10,
              offset: Offset.zero,
              color: Color.fromRGBO(0, 0, 0, 0.1)),
        ],
        child: Material(
          type: MaterialType.canvas,
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
                // Dulu tanpa `width` eksplisit tombol memesan selebar seluruh
                // layar (MediaQuery), padahal parent (Row/Column/lineWrap)
                // yang seharusnya membatasi.
                width: width ?? double.infinity,
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color ?? Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
                ),
                child: child),
          ),
        ),
      ),
    );
  }
}

class _FormFieldBasic extends _FormFieldCustom {
  const _FormFieldBasic(
      {required super.primaryText,
      super.secondaryText,
      super.height,
      required super.child});

  @override
  Widget renderChild() {
    return child;
  }
}

class _FormFieldCustom extends StatelessWidget {
  final String? primaryText;
  final String? secondaryText;
  final double? height;
  final Widget child;
  const _FormFieldCustom(
      {required this.primaryText,
      required this.child,
      this.height = 10,
      this.secondaryText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        primaryText == null
            ? const SizedBox()
            : secondaryText == null
                ? Text(
                    primaryText!,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : OverflowBar(
                    children: [
                      Text(
                        primaryText!,
                        style: GoogleFonts.nunito(
                            fontSize: 16, fontWeight: FontWeight.w300),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        " / ${secondaryText!}",
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
        SizedBox(
          height: height,
        ),
        renderChild(),
      ],
    );
  }

  Widget renderChild() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(31, 2, 1, 1)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          color: Colors.white,
        ),
        child: child);
  }
}

class _FormPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String primaryText;
  final String? hintText;
  final String? secondaryText;

  const _FormPasswordField({
    required this.primaryText,
    this.controller,
    this.hintText,
    this.secondaryText,
  });

  @override
  State<_FormPasswordField> createState() => __FormPasswordFieldState();
}

class __FormPasswordFieldState extends State<_FormPasswordField> {
  bool isVisible = true;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.secondaryText == null
            ? Text(widget.primaryText,
                style: GoogleFonts.nunito(
                    fontSize: 16, fontWeight: FontWeight.w300))
            : Row(
                children: [
                  Text(widget.primaryText,
                      style: GoogleFonts.nunito(
                          fontSize: 16, fontWeight: FontWeight.w300)),
                  Text(" / ${widget.secondaryText!}",
                      style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic))
                ],
              ),
        const SizedBox(
          height: 10,
        ),
        renderChild(),
      ],
    );
  }

  Widget renderChild() {
    return TextFormField(
        controller: widget.controller,
        validator: tffValidator,
        showCursor: true,
        cursorColor: blueDark,
        obscureText: isVisible,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: widget.hintText ?? '',
          hintStyle: GoogleFonts.nunito(
              textStyle: const TextStyle(color: Colors.grey)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1)),
              borderRadius: BorderRadius.all(Radius.circular(8))),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: blueHighlight),
              borderRadius: BorderRadius.all(Radius.circular(8))),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: blueDark,
              ),
              onPressed: () => setState(() => isVisible = !isVisible)),
        ));
  }
}

class _FormTextField extends _FormFieldCustom {
  const _FormTextField({
    required super.primaryText,
    required super.child,
    super.secondaryText,
  });

  @override
  Widget renderChild() {
    return child;
  }
}
