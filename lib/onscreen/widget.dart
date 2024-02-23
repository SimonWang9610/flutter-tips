import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tips/onscreen/models.dart';
import 'package:flutter_tips/onscreen/painter.dart';
import 'package:flutter_tips/onscreen/render.dart';

class OnscreenBoxData extends ContainerBoxParentData<RenderBox> {
  OnscreenPosition? position;
}

class _OnscreenElementWidget extends ParentDataWidget<OnscreenBoxData> {
  final OnscreenPosition position;

  const _OnscreenElementWidget({
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

      return _OnscreenElementWidget(
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

class _OnscreenBoardState extends State<OnscreenBoard> {
  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OnscreenBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(this);
    }
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OnscreenBoard.builder(
      key: widget.key,
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

class OnscreenController extends ChangeNotifier {
  final Map<OnscreenPosition, OnscreenElement> _elements;

  OnscreenController({
    Map<OnscreenPosition, OnscreenElement>? elements,
    OnscreenPosition? initialFocus,
  })  : _elements = elements ?? {},
        _focusedPosition = initialFocus;

  OnscreenElement? get focusedElement =>
      focusedPosition != null ? _elements[focusedPosition!] : null;

  OnscreenPosition? _focusedPosition;
  OnscreenPosition? get focusedPosition => _focusedPosition;

  bool get hasFocus => _focusedPosition != null;

  void focus(OnscreenPosition position) {
    if (_focusedPosition != position) {
      _focusedPosition = position;
      notifyListeners();
    }
  }

  void unfocus() {
    if (_focusedPosition != null) {
      _focusedPosition = null;
      notifyListeners();
    }
  }

  OnscreenElement? getElement(OnscreenPosition position) {
    return _elements[position];
  }

  void update(OnscreenPosition position, OnscreenElement element) {
    assert(_state != null, "OnscreenController must be attached.");

    _elements[position] = element;

    if (_focusedPosition == position) {
      notifyListeners();
    }

    _state?.refresh();
  }

  void remove(OnscreenPosition position) {
    assert(_state != null, "OnscreenController must be attached.");

    _elements.remove(position);

    if (_focusedPosition == position) {
      notifyListeners();
    }

    _state?.refresh();
  }

  void addElements(Map<OnscreenPosition, OnscreenElement> elements) {
    assert(_state != null, "OnscreenController must be attached.");

    if (_elements == elements) return;

    _elements.addAll(elements);

    _state?.refresh();
    notifyListeners();
  }

  bool hasElement(OnscreenPosition position) {
    return _elements.containsKey(position);
  }

  _OnscreenBoardState? _state;

  void _attach(_OnscreenBoardState refresher) {
    _state = refresher;
  }

  void _detach() {
    _state = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}
