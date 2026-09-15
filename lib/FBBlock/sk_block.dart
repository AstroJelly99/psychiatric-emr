// ignore_for_file: must_be_immutable

library sk_block;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:emr_homemade/utils/widgets/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

part 'sk_block_modules.dart';
part 'sk_block_widgets.dart';
part 'sk_block_enums.dart';
part 'inner_shadow.dart';

class SkBlock {
  SkBlock();

  /// Create a single line widget with text
  ///
  /// to create row, use lineWrap
  ///
  static Widget lineBlock(
          {required String text,
          double fontSize = 20,
          required EdgeInsetsGeometry padding,
          double spacing = 10,
          Color backgroundColor = Colors.white,
          bool isHeader = false,
          bool expanded = false,
          TextAlign textAlign = TextAlign.start}) =>
      _LineBlock(
        text: text,
        fontSize: fontSize,
        padding: padding,
        spacing: spacing,
        backgroundColor: backgroundColor,
        isHeader: isHeader,
        expanded: expanded,
        textAlign: textAlign,
      );

  static Widget columnBlock({
    double spacing = 10,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    required List<Widget> children,
  }) {
    List<Widget> uItems = [];

    for (int i = 0; i < children.length; i++) {
      uItems.add(children[i]);

      if (i != children.length - 1) {
        uItems.add(SizedBox(height: spacing));
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisAlignment: mainAxisAlignment,
        children: uItems,
      ),
    );
  }

  /// Ambang lebar tempat susunan mendatar berhenti masuk akal dan anak-anak
  /// ditumpuk vertikal. Nilainya sengaja sama dengan ambang yang sudah
  /// dipakai [mainAppBar] dan [defaultTable].
  static const double compactBreakpoint = 640;

  /// Create a single line wrap similar to row with auto spacing
  ///
  /// the default spacing value is 10
  ///
  /// Set [responsive] true untuk menumpuk anak jadi [Column] ketika lebar
  /// constraint parent di bawah [compactBreakpoint].
  ///
  /// [responsive] tetap opt-in (bukan default) karena memakai
  /// [LayoutBuilder], yang error di dalam leluhur `AlertDialog` mentah
  /// (IntrinsicWidth). Aman dipakai di [defaultDialog] (sudah `Dialog` biasa)
  /// — hindari di helper `alert_dialogs.dart` lain yang masih AlertDialog asli.
  static Widget lineWrap(
      {double spacing = 10,
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
      CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.end,
      bool responsive = false,
      required List<Widget> children}) {
    for (var widget in children) {
      if (widget is _LineBlock) {
        widget.disableSpacing();
      }
    }

    if (!responsive) {
      return Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: _lineWrapRow(
            children, spacing, mainAxisAlignment, crossAxisAlignment),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Yang menentukan adalah lebar constraint parent, bukan lebar layar:
        // lineWrap sering berada di dalam dialog atau panel yang jauh lebih
        // sempit dari layar penuh.
        final bool compact = constraints.maxWidth.isFinite &&
            constraints.maxWidth < compactBreakpoint;

        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: compact
              ? _lineWrapColumn(children, spacing)
              : _lineWrapRow(
                  children, spacing, mainAxisAlignment, crossAxisAlignment),
        );
      },
    );
  }

  static Widget _lineWrapRow(
    List<Widget> children,
    double spacing,
    MainAxisAlignment mainAxisAlignment,
    CrossAxisAlignment crossAxisAlignment,
  ) {
    final List<Widget> uItems = [];
    for (var i = 0; i < children.length; i++) {
      if (children[i] is _Button || children[i] is _FreeButton) {
        uItems.add(children[i]);
      } else {
        uItems.add(Expanded(child: children[i]));
      }
      if (i != children.length - 1) {
        uItems.add(SizedBox(width: spacing));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: uItems,
    );
  }

  static Widget _lineWrapColumn(List<Widget> children, double spacing) {
    final List<Widget> uItems = [];
    for (var i = 0; i < children.length; i++) {
      uItems.add(children[i]);
      if (i != children.length - 1) {
        // Jarak vertikal disamakan dengan spacing horizontal supaya form
        // tidak terlihat berdesakan setelah berubah jadi kolom.
        uItems.add(SizedBox(height: spacing));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      // stretch, bukan `crossAxisAlignment` milik mode baris: nilai default
      // di sana adalah CrossAxisAlignment.end, yang di dalam Column justru
      // merapatkan semua field ke kanan. Stretch juga membuat tombol
      // berlebar tetap (280/150) ikut menyusut mengikuti lebar layar.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: uItems,
    );
  }

  /// Wrap similar to [lineWrap]
  /// to mitigate overflow especially in [button]
  /// use this for auto placement when there are changes in screen size
  static Widget overflowWrap(
      {double spacing = 10,
      MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
      OverflowBarAlignment overflowAlignment = OverflowBarAlignment.start,
      required List<Widget> children}) {
    return OverflowBar(
      alignment: mainAxisAlignment,
      overflowAlignment: overflowAlignment,
      spacing: spacing,
      overflowSpacing: spacing,
      children: children,
    );
  }

  /// Baris header "ikon + judul (+ subjudul) + aksi" yang tidak overflow di
  /// layar sempit — judul dibungkus [Flexible] + ellipsis, bukan [Text]
  /// telanjang yang menuntut lebar intrinsiknya penuh.
  ///
  /// Bukan [LayoutBuilder]: sebagian pemanggil ada di dalam `AlertDialog`
  /// mentah (IntrinsicWidth), yang bikin LayoutBuilder error. Flexible +
  /// ellipsis murni aturan flex, aman di situ.
  ///
  /// [Flexible] (loose) dipakai, bukan [Expanded] (tight): blok judul tetap
  /// selebar isinya, [mainAxisAlignment] yang atur sisa ruang — sama seperti
  /// Row manual yang digantikan.
  static Widget sectionHeader({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double leadingSpacing = 12,
    double subtitleSpacing = 4,
    int titleMaxLines = 1,
    int subtitleMaxLines = 2,
  }) {
    final Widget titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle,
          maxLines: titleMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          SizedBox(height: subtitleSpacing),
          Text(
            subtitle,
            style: subtitleStyle,
            maxLines: subtitleMaxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    // [leading] + judul sengaja SATU anak, bukan sejajar [trailing]: kalau
    // ketiganya anak langsung, spaceBetween membagi celah ikon-judul juga.
    final Widget leadingAndTitle = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (leading != null) ...[
          leading,
          SizedBox(width: leadingSpacing),
        ],
        Flexible(child: titleBlock),
      ],
    );

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Flexible(child: leadingAndTitle),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Panel sambutan besar di puncak halaman (Home, Dashboard). Di bawah
  /// [compactBreakpoint] proporsinya diubah (bukan sekadar dikecilkan): ikon
  /// jadi lencana 56px sebaris judul, judul turun ke 22px — kotak ikon tetap
  /// 128px di desktop akan menyisakan terlalu sempit untuk judul di HP.
  static Widget pageHero({
    required IconData icon,
    required String title,
    required String subtitle,
    String? footnote,
    List<Color> gradientColors = const [],
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth.isFinite &&
            constraints.maxWidth < compactBreakpoint;

        final BoxDecoration decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        );

        Widget iconBox(double pad, double size) => Container(
              padding: EdgeInsets.all(pad),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(compact ? 14 : 20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(icon, size: size, color: Colors.white),
            );

        if (compact) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: decoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    iconBox(12, 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    footnote,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(32),
          decoration: decoration,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (footnote != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        footnote,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              iconBox(24, 80),
            ],
          ),
        );
      },
    );
  }

  /// Create a wrap for widgets inside a container.
  ///
  /// To create side by side containers, use SkBlock.rowWrap()
  static Widget fullWrap({
    String? titleText,
    bool horizontalWrapContent = false,
    double? height,
    double spacing = 10,
    required EdgeInsetsGeometry padding,
    required List<Widget> children,
    Color backgroundColor = Colors.white,
  }) {
    List<Widget> uItems = [];

    for (var i = 0; i < children.length; i++) {
      uItems.add(children[i]);
      uItems.add(SizedBox(
        height: spacing,
      ));
    }
    if (uItems.isNotEmpty) uItems.removeLast();

    return _FullWrap(
      titleText: titleText,
      items: uItems,
      backgroundColor: backgroundColor,
      spacing: spacing,
      padding: padding,
      horizontalWrapContent: horizontalWrapContent,
    );
  }

  /// Create a wrap for widgets inside container specifically
  /// for horizontal layouts.
  ///
  /// use this inside [fullWrap] or parent with bounded width, otherwise use [wrap]
  static Widget rowWrap(
      {required List<Widget> children, double horizontalSpacing = 10}) {
    List<Widget> uItems = List.generate(
      children.length * 2 - 1,
      (index) => index.isEven
          ? Expanded(child: children[index ~/ 2])
          : SizedBox(
              width: horizontalSpacing,
            ),
    );
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: uItems,
      ),
    );
  }

  /// Create a list of widget with custom spacing
  /// use [Axis] to control the direction of children layouts
  ///
  /// use this if parent is unbounded or unknown.
  static Widget wrap(
      {required Axis direction,
      required List<Widget> children,
      MainAxisAlignment? mainAxisAlignment,
      CrossAxisAlignment? crossAxisAlignment,
      MainAxisSize? mainAxisSize,
      double spacing = 10}) {
    List<Widget> uItems = List.generate(
        children.length * 2 - 1,
        (index) => index.isEven
            ? children[index ~/ 2]
            : switch (direction) {
                Axis.horizontal => SizedBox(
                    width: spacing,
                  ),
                Axis.vertical => SizedBox(
                    height: spacing,
                  )
              });
    return Flex(
      direction: direction,
      mainAxisSize: mainAxisSize ?? MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children: uItems,
    );
  }

  /// Create a button similar to [button]
  /// without innershadow and customizable child
  ///
  static Widget freeButton(
          {required VoidCallback onTap,
          Widget? child,
          double borderRadius = 12,
          EdgeInsetsGeometry? padding,
          BoxBorder? border,
          Color? color,
          Icon? icon,
          Color? textColor,
          double? width}) =>
      _FreeButton(
        onTap: onTap,
        borderRadius: borderRadius,
        color: color,
        padding: padding,
        border: border,
        icon: icon,
        width: width,
        child: child,
      );

  /// Create a button with innershadow
  ///
  /// similar to elevated button
  static Widget button(
          {required BuildContext context,
          required VoidCallback onTap,
          double borderRadius = 12,
          EdgeInsetsGeometry? padding,
          MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
          Color? color,
          Widget? icon,
          SkIconAlignment? iconAlignment = SkIconAlignment.start,
          String? text,
          TextStyle? textStyle,
          double? width,
          TextAlign textAlign = TextAlign.center}) =>
      _Button(
        context: context,
        onTap: onTap,
        borderRadius: borderRadius,
        padding: padding,
        mainAxisAlignment: mainAxisAlignment,
        color: color,
        icon: icon,
        iconAlignment: iconAlignment,
        text: text,
        textStyle: textStyle,
        width: width,
        textAlign: textAlign,
      );

  /// Add a title on top of a widget
  /// based on library styling
  ///
  /// usually used in a form
  static Widget field(
          {required String primaryText,
          String? secondaryText,
          double? height = 10,
          required Widget child}) =>
      _FormFieldBasic(
          primaryText: primaryText,
          secondaryText: secondaryText,
          height: height,
          child: child);

  /// Similar use as [field]
  /// with postion adjustments based on screen size.
  /// Uses [OverflowBar]
  static Widget formField(
          {required String primaryText,
          String? secondaryText,
          required Widget child}) =>
      _FormFieldCustom(
          primaryText: primaryText, secondaryText: secondaryText, child: child);

  /// [TextField] widget with title on top
  /// based on library styling
  ///
 static Widget formTextField({
  required String primaryText,
  String? secondaryText,
  TextEditingController? controller,
  TextInputType? keyboardType,
  bool enabled = true,
  bool autofocus = false,
  String? hint,
  List<TextInputFormatter>? inputFormatters,
  // null = tanpa batas (baris bisa bertambah saat Enter ditekan), seperti
  // TextField isi resep di ResepSection. Default tetap 1 supaya pemanggil
  // lama (username, kode obat, dsb) tidak berubah perilaku.
  int? maxLines = 1,
  Function(String)? onChanged
}) {
  bool passVisible = false;
  return _FormTextField(
    primaryText: primaryText,
    secondaryText: secondaryText,
    child: TextField(
      enabled: enabled,
      controller: controller,
      showCursor: true,
      inputFormatters: inputFormatters ??
          <TextInputFormatter>[
            // Mengubah regex untuk mengizinkan karakter , . - ? dan spasi
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z ,.\/-?]')),
          ],
      autofocus: autofocus,
      cursorColor: blueDark,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: passVisible,
      autocorrect: false,
      onChanged: onChanged,
      decoration: defaultInputDecorator().copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey)
      ),
    )
  );
}

/// [TextField] widget dengan title di atas
/// khusus untuk input Kategori Skoring
/// Hanya mengizinkan alphanumeric dan tanda hubung (-)
/// Contoh: 1-10, 0-10, A-E, dll
static Widget formScoringCategoryTextField({
  required String primaryText,
  String? secondaryText,
  TextEditingController? controller,
  bool enabled = true,
  bool autofocus = false,
  String? hint,
  Function(String)? onChanged
}) {
  return _FormTextField(
    primaryText: primaryText,
    secondaryText: secondaryText,
    child: TextField(
      enabled: enabled,
      controller: controller,
      showCursor: true,
      inputFormatters: <TextInputFormatter>[
        // Hanya mengizinkan huruf (a-z, A-Z), angka (0-9), dan tanda hubung (-)
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z-]')),
      ],
      autofocus: autofocus,
      cursorColor: blueDark,
      keyboardType: TextInputType.text,
      autocorrect: false,
      onChanged: onChanged,
      decoration: SkBlock.defaultInputDecorator().copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey)
      ),
    )
  );
}

  /// [TextField] widget with title on top
  /// based on library styling
  ///
  /// that replaces [TextField] with clickable Function
  static Widget formClickableTextField({
    required String primaryText,
    String? secondaryText,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? hintText,
    bool enabled = true,
    String? hint,
    VoidCallback? onTap,
  }) {
    return _FormTextField(
        primaryText: primaryText,
        secondaryText: secondaryText,
        child: TextField(
          readOnly: true,
          enabled: enabled,
          controller: controller,
          showCursor: false,
          onTap: onTap,
          autocorrect: false,
          decoration: defaultInputDecorator().copyWith(
              hintText: hint, hintStyle: const TextStyle(color: Colors.grey)),
        ));
  }

  /// [TextField] widget with title on top
  /// based on library styling
  ///
  /// that replaces [TextField] with Date Time selector
  static Widget formDateTimePickerTextField({
    required String primaryText,
    required BuildContext context,
    String? secondaryText,
    TextEditingController? controller,
    bool readOnly = true, // Field should be readonly by default
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return _FormTextField(
      primaryText: primaryText,
      secondaryText: secondaryText,
      child: TextField(
        controller: controller,
        showCursor: true,
        cursorColor: blueDark,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );

          if (pickedDate != null && context.mounted) {
            TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (pickedTime != null && controller != null) {
              final selectedDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
              String formattedDateTime =
                  DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime);
              controller.text = formattedDateTime;
            }
          }
        },
        decoration: defaultInputDecorator().copyWith(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// [TextField] widget with title on top
  /// based on library styling
  ///
  /// that replaces [TextField] with Date only selector
  static Widget formDatePickerTextField({
    String? primaryText,
    required BuildContext context,
    String? secondaryText,
    TextEditingController? controller,
    bool readOnly = true,
    InputDecoration? decoration,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return _FormTextField(
      primaryText: primaryText,
      secondaryText: secondaryText,
      child: TextField(
        controller: controller,
        showCursor: true,
        cursorColor: blueDark,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: defaultInputDecorator(
            contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 16),
            hintText: hint,
            suffixIcon: const Icon(
              Icons.calendar_month,
              color: blackPrimary,
            )).copyWith(isDense: true),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null && controller != null) {
            String formattedDate =
                pickedDate.toIso8601String().split('T').first;
            controller.text = formattedDate;
            if (onChanged != null) {
              onChanged(formattedDate);
            }
          }
        },
        onChanged: (value) {
          if (onChanged != null) {
            onChanged(value);
          }
        },
      ),
    );
  }

  static Widget formMonthPickerTextField({
    String? primaryText,
    required BuildContext context,
    String? secondaryText,
    TextEditingController? controller,
    bool readOnly = true,
    InputDecoration? decoration,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? hint,
    ValueChanged<String>? onChanged,
  }) {
    return _FormTextField(
      primaryText: primaryText,
      secondaryText: secondaryText,
      child: TextField(
        controller: controller,
        showCursor: true,
        cursorColor: blueDark,
        keyboardType: keyboardType,
        readOnly: readOnly,
        decoration: SkBlock.defaultInputDecorator(
          hintText: hint,
          suffixIcon: const Icon(
            Icons.calendar_month,
            color: blackPrimary,
          ),
          fillColor: whitePrimary,
        ),
        onTap: () async {
          final pickedDate = await showMonthYearPicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(DateTime.now().year, DateTime.now().month),
          );

          if (pickedDate != null && controller != null) {
            String formattedDate = DateFormat('MMMM-y').format(pickedDate);
            controller.text = formattedDate;
            onChanged?.call(formattedDate);
          }
        },
        onChanged: (value) {
          onChanged?.call(value);
        },
      ),
    );
  }

  /// [TextField] widget with title on top
  /// based on library styling
  ///
  /// that receives password as input
  static Widget formPasswordField({
    required String primaryText,
    String? hint,
    String? secondaryText,
    TextEditingController? controller,
  }) =>
      _FormPasswordField(
        primaryText: primaryText,
        secondaryText: secondaryText,
        controller: controller,
        hintText: hint,
      );

  static InputDecoration defaultInputDecorator(
          {String? hintText,
          TextStyle? hintStyle,
          Widget? suffixIcon,
          Color? enabledBorderColor,
          Color? focusedBorderColor,
          BorderRadius? borderRadius,
          bool enabled = true,
          EdgeInsetsGeometry? contentPadding,
          Color? fillColor}) =>
      InputDecoration(
          filled: fillColor == null ? false : true,
          fillColor: fillColor,
          hintText: hintText,
          enabled: enabled,
          hintStyle: hintStyle,
          contentPadding:
              contentPadding ?? const EdgeInsets.fromLTRB(12, 20, 12, 18),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color:
                      enabledBorderColor ?? const Color.fromRGBO(0, 0, 0, 0.1)),
              borderRadius: const BorderRadius.all(Radius.circular(8))),
          focusedBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: focusedBorderColor ?? blueHighlight),
              borderRadius: const BorderRadius.all(Radius.circular(8))),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          suffixIcon: suffixIcon);

  static InputDecoration defaultShadowInputDecorator() => InputDecoration(
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.1)),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: whitePrimary),
          borderRadius: BorderRadius.all(Radius.circular(8))),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(8),
      ));


  static Widget formDropdown<T>({
    required String primaryText,
    String? secondaryText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    bool enabled = true,
  }) {
    return _FormTextField(
      primaryText: primaryText,
      secondaryText: secondaryText,
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        decoration: SkBlock.defaultInputDecorator(
          hintText: hint,
          fillColor: whitePrimary,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
        validator: (val) {
          if (val == null) {
            return '*Required Fields';
          }
          return null;
        },
      ),
    );
  }

}

String? tffValidator(value) {
  if (value == null || value.isEmpty) {
    return '*Required Fields';
  }
  return null;
}


/// Mirip [SkBlock.button] tapi support async [onPressed].
class AppButton extends StatelessWidget {
  final Future<void> Function()? onPressed;
  final String text;
  final Color color;
  final TextStyle? textStyle;
  final double borderRadius;
  final double? width;
  final EdgeInsetsGeometry padding;
  final Widget? icon;
  final MainAxisAlignment mainAxisAlignment;
  final TextAlign textAlign;

  const AppButton({
    super.key,
    required this.text,
    required this.color,
    this.textStyle,
    this.onPressed,
    this.borderRadius = 12,
    this.width,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.icon,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: isDisabled
            ? null
            : () async {
                FocusScope.of(context).unfocus(); // Tutup keyboard
                await onPressed?.call();
              },
        child: Ink(
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade300 : color,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Inner shadow style mirip SkBlock.button
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                offset: const Offset(-2, -2),
                blurRadius: 4,
              ),
            ],
          ),
          padding: padding,
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: textAlign,
                  style: textStyle ??
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
}
