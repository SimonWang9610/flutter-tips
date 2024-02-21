import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/painter.dart';
import 'package:flutter_tips/onscreen/render.dart';

sealed class OnscreenElement {}

final class PartyBanner extends OnscreenElement {
  final String name;
  final String slogan;

  PartyBanner(this.name, this.slogan);

  @override
  String toString() {
    return "PartyBanner($name, $slogan)";
  }
}

final class PartyLogo extends OnscreenElement {
  final String url;
  PartyLogo(this.url);

  @override
  String toString() {
    return "PartyLogo($url)";
  }
}

final class PartyEmpty extends OnscreenElement {
  PartyEmpty();

  @override
  String toString() {
    return "PartyEmpty";
  }
}

class OnscreenBoxData extends ContainerBoxParentData<RenderBox> {
  OnscreenPosition? position;
}

class OnscreenElementWidget extends ParentDataWidget<OnscreenBoxData> {
  final OnscreenPosition position;

  const OnscreenElementWidget({
    super.key,
    required this.position,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is OnscreenBoxData);

    final parentData = renderObject.parentData as OnscreenBoxData;
    if (parentData.position != position) {
      parentData.position = position;
      final targetParent = renderObject.parent;

      if (targetParent is RenderObject) {
        targetParent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => OnscreenBoard;
}

typedef OnscreenPositionedElementBuilder = Widget Function(
    OnscreenPosition position);

class OnscreenBoard extends MultiChildRenderObjectWidget {
  final OnscreenPadding padding;
  final OnscreenBackgroundPainter? backgroundPainter;
  final OnscreenFocusNode? focusNode;
  final Size? preferredSize;

  OnscreenBoard.builder({
    super.key,
    required this.padding,
    required OnscreenPositionedElementBuilder builder,
    this.backgroundPainter,
    this.focusNode,
    this.preferredSize,
    EdgeInsets? margin,
    bool addRepaintBoundary = true,
  }) : super(
          children: wrap(
            builder,
            addRepaintBoundary: addRepaintBoundary,
            margin: margin,
          ),
        );

  @override
  RenderOnscreen createRenderObject(BuildContext context) {
    return RenderOnscreen(
      padding: padding,
      backgroundPainter: backgroundPainter,
      preferredSize: preferredSize,
      focusNode: focusNode,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOnscreen renderObject) {
    renderObject
      ..focusNode = focusNode
      ..padding = padding
      ..backgroundPainter = backgroundPainter
      ..preferredSize = preferredSize;
  }

  static List<Widget> wrap(
    OnscreenPositionedElementBuilder builder, {
    bool addRepaintBoundary = true,
    EdgeInsets? margin,
  }) {
    final elements = OnscreenPosition.values.map((pos) {
      Widget w = builder(pos);
      Key? key = w.key != null ? ValueKey(w.key) : null;

      if (margin != null) {
        w = Padding(padding: margin, child: w);
      }

      if (addRepaintBoundary) {
        w = RepaintBoundary(child: w);
      }

      return OnscreenElementWidget(
        key: key,
        position: pos,
        child: w,
      );
    });

    return elements.toList();
  }
}
