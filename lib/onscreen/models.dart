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

class OnscreenPadding {
  final double top;
  final double bottom;
  final double left;
  final double right;

  const OnscreenPadding({
    this.top = 0.2,
    this.bottom = 0.2,
    this.left = 0.2,
    this.right = 0.2,
  })  : assert(top >= 0 && top <= 1),
        assert(bottom >= 0 && bottom <= 1),
        assert(left >= 0 && left <= 1),
        assert(right >= 0 && right <= 1);

  const OnscreenPadding.symmetric({
    double vertical = 0.2,
    double horizontal = 0.2,
  }) : this(
          top: vertical,
          bottom: vertical,
          left: horizontal,
          right: horizontal,
        );

  double get centerX => (1 - left - right);
  double get centerY => (1 - top - bottom);
}

enum OnscreenPosition {
  topLeft(0, 0),
  topCenter(0, 1),
  topRight(0, 2),
  centerLeft(1, 0),
  center(1, 1),
  centerRight(1, 2),
  bottomLeft(2, 0),
  bottomCenter(2, 1),
  bottomRight(2, 2);

  final int x;
  final int y;

  const OnscreenPosition(this.x, this.y);

  static OnscreenPosition fromIndex(int index) {
    switch (index) {
      case 0:
        return topLeft;
      case 1:
        return topCenter;
      case 2:
        return topRight;
      case 3:
        return centerLeft;
      case 4:
        return center;
      case 5:
        return centerRight;
      case 6:
        return bottomLeft;
      case 7:
        return bottomCenter;
      case 8:
        return bottomRight;
      default:
        throw ArgumentError("Invalid index: $index");
    }
  }

  static int toIndex(OnscreenPosition position) {
    return position.x * 3 + position.y;
  }
}
