// ignore_for_file: must_be_immutable
part of 'sk_block.dart';

class _LineBlock extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  double spacing;
  final Color backgroundColor;
  final bool isHeader;
  final bool expanded;
  final TextAlign textAlign;
  _LineBlock({
    required this.text,
    this.fontSize = 20,
    required this.padding,
    this.spacing = 10,
    this.backgroundColor = Colors.white,
    this.isHeader = false,
    this.expanded = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    var container = Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: spacing),
      padding: padding,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: backgroundColor),
      child: Text(
        text,
        style: TextStyle(
            fontSize: fontSize,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal),
        textAlign: textAlign,
      ),
    );
    return expanded ? Expanded(child: container) : SizedBox(child: container);
  }

  void disableSpacing() {
    spacing = 0;
  }
}

class _FullWrap extends StatelessWidget {
  const _FullWrap(
      {this.titleText,
      this.horizontalWrapContent,
      required this.backgroundColor,
      required this.spacing,
      required this.padding,
      required this.items});

  /// If true, set width to wrap content in [items].
  /// If false or null set container width to fill the empty space based on the parent.
  final bool? horizontalWrapContent;

  /// Set spacing for each item in [items].
  final double spacing;

  /// Set padding for [_FullWrap] container.
  final EdgeInsetsGeometry padding;

  /// Set the title text based. if null shows nothing.
  final String? titleText;

  /// Set backgroundColor of the [_FullWrap].
  final Color backgroundColor;

  /// Set the content of the [_FullWrap].
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    bool dense = horizontalWrapContent ?? false;
    return Container(
      width: dense ? null : double.maxFinite,
      margin: EdgeInsets.only(bottom: spacing),
      padding: padding,
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: backgroundColor),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: initChildren()),
    );
  }

  List<Widget> initChildren() {
    List<Widget> res = [];
    if (titleText != null) {
      res.add(Text(
        titleText!,
        style: const TextStyle(fontSize: 16),
      ));
      res.add(const SizedBox(
        height: 25,
      ));
    }
    res.addAll(items);
    return res;
  }
}
