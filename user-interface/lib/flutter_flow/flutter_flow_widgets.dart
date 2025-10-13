import 'package:flutter/material.dart';

class FFButtonOptions {
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry iconPadding;
  final Color color;
  final TextStyle textStyle;
  final double elevation;
  final BorderRadius borderRadius;
  final BorderSide? borderSide;
  final Color? iconColor;

  const FFButtonOptions({
    required this.height,
    required this.padding,
    required this.iconPadding,
    required this.color,
    required this.textStyle,
    required this.elevation,
    required this.borderRadius,
    this.borderSide,
    this.iconColor,
  });
}

class FFButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final FFButtonOptions options;
  final Widget? icon;

  const FFButtonWidget({
    super.key,
    required this.onPressed,
    required this.text,
    required this.options,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = TextButton.styleFrom(
      backgroundColor: options.color,
      padding: options.padding,
      shape: RoundedRectangleBorder(
        borderRadius: options.borderRadius,
        side: options.borderSide ?? BorderSide.none,
      ),
      foregroundColor: options.textStyle.color,
      textStyle: options.textStyle,
      elevation: options.elevation,
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: options.iconPadding,
            child: IconTheme.merge(
              data: IconThemeData(color: options.iconColor ?? options.textStyle.color),
              child: icon!,
            ),
          ),
        Text(text, style: options.textStyle),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: options.height),
      child: TextButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
