import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class TreeNode {
  /// the distance from the spacer to its center-left
  final double distanceToSpacer;

  /// used to layout the text.
  /// if [icon] is not null, effective [maxWidth] would be the maximum between [maxWith] and [TextStyle.fontSize]
  final double maxWidth;

  /// the border width
  final double strokeWidth;

  /// the node border shape
  final BoxShape borderShape;
  final EdgeInsets? padding;
  final Color strokeColor;
  final Color? backgroundColor;
  final Color? iconColor;

  final String? text;
  final IconData? icon;
  final TextStyle style;

  final List<TreeNode> nodes;
  final TreeNode? parent;

  late Size size;
  late TextPainter painter;
  double textScaleFactor = 1.0;

  TreeNode({
    required this.style,
    this.distanceToSpacer = 50,
    this.maxWidth = 40,
    this.strokeWidth = 2,
    this.borderShape = BoxShape.circle,
    this.strokeColor = Colors.grey,
    this.backgroundColor,
    this.iconColor,
    this.padding,
    this.text,
    this.icon,
    this.parent,
    List<TreeNode>? nodes,
  })  : assert(() {
          if (text == null && icon == null) return false;

          if (text != null && icon != null) return false;
          return true;
        }()),
        nodes = nodes ?? [] {
    painter = TextPainter(
      text: buildTextSpan(),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      textScaleFactor: textScaleFactor,
    );

    relayout();
  }

  void addNode(TreeNode node) {
    nodes.add(node);
  }

  TextSpan buildTextSpan({double? height}) {
    final textStyle = style.copyWith(
      inherit: icon != null ? false : true,
      color: iconColor,
      fontFamily: icon?.fontFamily,
      package: icon?.fontPackage,
      height: 1.0,
    );

    return TextSpan(
      text: text ?? String.fromCharCode(icon!.codePoint),
      style: textStyle,
    );
  }

  double get width {
    if (borderShape == BoxShape.rectangle) {
      return size.width + strokeWidth * 2;
    } else {
      return size.longestSide + strokeWidth * 2;
    }
    // if (text != null || borderShape == BoxShape.circle) {
    //   return size.longestSide + strokeWidth * 2;
    // } else {
    //   return size.width + strokeWidth * 2;
    // }
  }

  double get height {
    if (borderShape == BoxShape.rectangle) {
      return size.height + strokeWidth * 2;
    } else {
      return size.longestSide + strokeWidth * 2;
    }
    // if (text != null || borderShape == BoxShape.circle) {
    //   return size.longestSide + strokeWidth * 2;
    // } else {
    //   return size.height + strokeWidth * 2;
    // }
  }

  double get longestSide => max(width, height);

  double distanceCenterToLeft() {
    final bool useLongestSide = icon != null || borderShape == BoxShape.circle;

    return useLongestSide ? longestSide / 2 : width / 2;
  }

  void relayout({Size? averageSize}) {
    double widthScale = 1.0;
    double heightScale = 1.0;

    if (averageSize != null) {
      if (averageSize.width < this.width || averageSize.height < this.height) {
        widthScale = averageSize.width / this.width;
        heightScale = averageSize.height / this.height;

        // textScaleFactor = min(min(widthScale, heightScale), textScaleFactor);
        textScaleFactor = min(widthScale, heightScale);

        if (painter.textScaleFactor != textScaleFactor) {
          painter.textScaleFactor = textScaleFactor;
        }

        if (heightScale / widthScale < 1.0) {
          painter.text = buildTextSpan(height: heightScale / widthScale);
        }
      }
    }

    // print("width scale: $widthScale, height scale: $heightScale");
    final effectiveMaxWidth = text == null && icon != null
        ? max(maxWidth, style.fontSize ?? 0)
        : maxWidth;

    painter.layout(maxWidth: effectiveMaxWidth);

    final scale = min(widthScale, heightScale);

    final width = painter.size.width +
        min(padding?.left ?? 0.0, padding?.right ?? 0.0) * scale * 2;

    final height = painter.size.height +
        min(padding?.bottom ?? 0.0, padding?.top ?? 0.0) * scale * 2;

    size = Size(width, height);
    // print("size: $size, average: $averageSize");
  }

  void paintNode(Canvas canvas, Offset center) {
    canvas.save();

    canvas.translate(center.dx, center.dy);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor;

    Paint? backgroundPaint;

    if (backgroundColor != null) {
      backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = backgroundColor!;
    }

    if (borderShape == BoxShape.rectangle) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: width,
          height: height,
        ),
        const Radius.circular(10),
      );

      if (backgroundPaint != null) {
        canvas.drawRRect(rrect.deflate(strokeWidth / 2), backgroundPaint);
      }
      canvas.drawRRect(rrect, paint);
    } else {
      if (backgroundPaint != null) {
        canvas.drawCircle(Offset.zero, longestSide / 2, backgroundPaint);
      }
      canvas.drawCircle(
        Offset.zero,
        longestSide / 2,
        paint,
      );
    }

    final textCenter = painter.size.center(Offset.zero);

    painter.paint(canvas, -textCenter);

    canvas.restore();
  }
}

class TreeViewPainter extends CustomPainter {
  final double distance;
  final TreeNode root;
  final BorderRadius? borderRadius;
  final double nodeSpacing;
  final double spacerRatio;

  TreeViewPainter({
    required this.root,
    this.borderRadius,
    this.distance = 50,
    this.nodeSpacing = 10,
    this.spacerRatio = 0.3,
  }) : super();

  late double minNodeDistance = distance;

  double maxNodeHeight = 0.0;
  double maxNodeWidth = 0.0;

  TreeSpacer spacer = TreeSpacer();

  Paint linePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.grey
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.round;

  @override
  bool shouldRepaint(covariant TreeViewPainter oldDelegate) {
    return root != oldDelegate.root ||
        distance != oldDelegate.distance ||
        borderRadius != oldDelegate.borderRadius ||
        nodeSpacing != oldDelegate.nodeSpacing;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // calculateScaleByTotal(size);
    averageLayout(size);

    _paintRoot(canvas, size);

    final List<Offset> cornerPoints = [];
    final List<Offset> linePoints = [];

    final translateStep = spacer.crossSpace / (root.nodes.length - 1);

    for (int i = 0; i < root.nodes.length; i++) {
      final node = root.nodes[i];

      final centerLeft = Offset(
          size.width - node.width, spacer.crossAxisStart + translateStep * i);
      final center = centerLeft.translate(node.width / 2, 0);

      if (i == 0 || i == root.nodes.length - 1) {
        cornerPoints.add(centerLeft);
      } else {
        linePoints.addAll([centerLeft, Offset(spacer.mainAxis, centerLeft.dy)]);
      }

      minNodeDistance = min(minNodeDistance, centerLeft.dx - spacer.mainAxis);

      node.paintNode(canvas, center);
    }

    _paintLines(canvas, cornerPoints, linePoints);
  }

  void _paintRoot(Canvas canvas, Size size) {
    final rootCenter =
        size.centerLeft(Offset.zero) + Offset(root.distanceCenterToLeft(), 0);
    root.paintNode(canvas, rootCenter);

    canvas.drawLine(rootCenter.translate(root.distanceCenterToLeft(), 0),
        Offset(spacer.mainAxis, rootCenter.dy), linePaint);
  }

  void _paintLines(Canvas canvas, List<Offset> corners, List<Offset> points) {
    assert(corners.length == 2 && points.length % 2 == 0);

    final topFirst = Offset(
        spacer.mainAxis +
            min(minNodeDistance / 2, borderRadius?.topLeft.x ?? 0.0),
        spacer.crossAxisStart);
    final topSecond = Offset(
        spacer.mainAxis,
        spacer.crossAxisStart +
            min(borderRadius?.topLeft.y ?? 0.0, minNodeDistance / 2));
    final bottomFirst = Offset(
        spacer.mainAxis,
        spacer.crossAxisEnd -
            min(borderRadius?.bottomLeft.y ?? 0.0, minNodeDistance / 2));
    final bottomSecond = Offset(
        spacer.mainAxis +
            min(borderRadius?.bottomLeft.x ?? 0.0, minNodeDistance / 2),
        spacer.crossAxisEnd);

    final path = Path()
      ..moveTo(corners.first.dx, corners.first.dy)
      ..lineTo(topFirst.dx, topFirst.dy)
      ..quadraticBezierTo(
          spacer.mainAxis, spacer.crossAxisStart, topSecond.dx, topSecond.dy)
      ..lineTo(bottomFirst.dx, bottomFirst.dy)
      ..quadraticBezierTo(spacer.mainAxis, spacer.crossAxisEnd, bottomSecond.dx,
          bottomSecond.dy)
      ..lineTo(corners.last.dx, corners.last.dy);

    canvas.drawPath(path, linePaint);

    while (points.isNotEmpty) {
      final start = points.removeLast();
      final end = points.removeLast();

      canvas.drawLine(start, end, linePaint);
    }
  }

  void averageLayout(Size canvasSize) {
    final totalNodeSpacing = (root.nodes.length - 1) * nodeSpacing;

    final averageWidth = (canvasSize.width - distance) / 2;
    final averageHeight =
        (canvasSize.height - totalNodeSpacing) / (root.nodes.length);

    final averageSize = Size(averageWidth, averageHeight);

    root.relayout(averageSize: averageSize);

    maxNodeHeight = 0.0;
    maxNodeWidth = 0.0;

    for (final node in root.nodes) {
      node.relayout(averageSize: averageSize);

      maxNodeHeight = max(maxNodeHeight, node.height);
      maxNodeWidth = max(node.width, maxNodeWidth);
    }

    _positionSpacer(canvasSize);
  }

  void _positionSpacer(Size canvasSize) {
    final mainAxis =
        (canvasSize.width - root.width - maxNodeWidth) * spacerRatio +
            root.width;

    print(
        "max height: $maxNodeHeight, last node scale: ${root.nodes.last.textScaleFactor}");

    final crossAxisStart = maxNodeHeight / 2;
    final crossAxisEnd = canvasSize.height - maxNodeHeight / 2;

    spacer = TreeSpacer(
      mainAxis: mainAxis,
      crossAxisStart: crossAxisStart,
      crossAxisEnd: crossAxisEnd,
    );
  }
}

class TreeSpacer {
  final double mainAxis;
  final double crossAxisStart;
  final double crossAxisEnd;

  TreeSpacer({
    this.mainAxis = 0.0,
    this.crossAxisEnd = 0.0,
    this.crossAxisStart = 0.0,
  }) : assert(crossAxisEnd >= crossAxisStart);

  double get crossSpace => crossAxisEnd - crossAxisStart;
}
