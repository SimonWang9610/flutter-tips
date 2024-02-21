import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/onscreen/background.dart';
import 'package:flutter_tips/onscreen/controller.dart';
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
  Type get debugTypicalAncestorWidgetClass => _OnscreenBoard;
}

typedef OnscreenPositionedElementCreator = Widget Function(
    OnscreenPosition position);

class _OnscreenBoard extends MultiChildRenderObjectWidget {
  final OnscreenPadding padding;
  final OnscreenPainter? painter;
  final OnscreenController controller;
  final Size? preferredSize;

  _OnscreenBoard.builder({
    super.key,
    required this.padding,
    required this.controller,
    required OnscreenPositionedElementCreator creator,
    this.painter,
    this.preferredSize,
    EdgeInsets? margin,
    bool addRepaintBoundary = true,
  }) : super(
          children: wrap(
            creator,
            addRepaintBoundary: addRepaintBoundary,
            margin: margin,
          ),
        );

  @override
  RenderOnscreen createRenderObject(BuildContext context) {
    return RenderOnscreen(
      padding: padding,
      painter: painter,
      preferredSize: preferredSize,
      controller: controller,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOnscreen renderObject) {
    renderObject
      ..controller = controller
      ..padding = padding
      ..painter = painter
      ..preferredSize = preferredSize;
  }

  static List<Widget> wrap(
    OnscreenPositionedElementCreator creator, {
    bool addRepaintBoundary = true,
    EdgeInsets? margin,
  }) {
    final elements = OnscreenPosition.values.map((pos) {
      Widget w = creator(pos);
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

typedef OnscreenElementBuilder = Widget Function(
    BuildContext context, OnscreenPosition position);

class OnscreenBoard extends StatefulWidget {
  final OnscreenPadding padding;
  final OnscreenController controller;
  final OnscreenElementBuilder builder;

  final OnscreenPainter? painter;
  final Size? preferredSize;
  final EdgeInsets? margin;

  const OnscreenBoard({
    super.key,
    required this.padding,
    required this.controller,
    required this.builder,
    this.painter,
    this.preferredSize,
    this.margin,
  });

  @override
  State<OnscreenBoard> createState() => _OnscreenBoardState();
}

class _OnscreenBoardState extends State<OnscreenBoard> with OnscreenRefresher {
  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(covariant OnscreenBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach();
      widget.controller.attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OnscreenBoard.builder(
      padding: widget.padding,
      controller: widget.controller,
      margin: widget.margin,
      preferredSize: widget.preferredSize,
      painter: widget.painter,
      creator: (position) {
        return widget.builder(context, position);
      },
    );
  }
}
