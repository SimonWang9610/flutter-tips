import 'package:flutter/material.dart';

class GoObserver extends NavigatorObserver {
  bool _isBootStrapping = true;

  bool get isBootStrapping => _isBootStrapping;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _isBootStrapping = false;
    super.didPush(route, previousRoute);

    print('didPush:${previousRoute?.settings.name} -> ${route.settings.name}');
  }
}
