import 'package:flutter/material.dart';

class OutlinedTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enableOutlineBorder;
  const OutlinedTextButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.style,
    this.enableOutlineBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: enableOutlineBorder
          ? style ??
              TextButton.styleFrom(
                shape: const CircleBorder(side: BorderSide()),
              )
          : null,
      // child: Padding(
      //   padding: const EdgeInsets.symmetric(
      //     horizontal: 0,
      //     vertical: 2,
      //   ),
      //   child: child,
      // ),
      child: child,
    );
  }
}
