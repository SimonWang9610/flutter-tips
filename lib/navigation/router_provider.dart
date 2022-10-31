import 'package:flutter/material.dart';
import 'package:flutter_tips/navigation/pages.dart';

typedef PageRouteBuilderFromSetting = Widget Function(RouteSettings);

class AppRouteState extends ChangeNotifier {
  static Map<String, PageRouteBuilderFromSetting> pages = {
    "/login": (_) => LoginPage(),
    "/": (_) => HomePage(),
    "/book": (_) => BookDetail(id: 0),
    "/404": (_) => PageNotFound(),
  };

  final List<RouteSettings> _settings = [];

  AppRouteState();

  void updateRoutes(List<RouteSettings> settings) {
    _settings.clear();
    _settings.addAll(settings);
    notifyListeners();
  }

  List<Page<dynamic>> get generatedRoutes {
    final List<Page<dynamic>> routes = [];
    bool pageNotFound = false;

    for (final setting in _settings) {
      final pageBuilder = pages[setting.name];
      if (pageBuilder != null) {
        routes.add(
          MaterialPage(child: pageBuilder(setting)),
        );
      } else {
        pageNotFound = true;
        break;
      }
    }

    if (pageNotFound) {
      const setting = RouteSettings(name: "/404");

      routes.add(
        MaterialPage(
          child: pages["/404"]!(setting),
        ),
      );
    }
    return routes;
  }
}

class MyAppRoutDelegate extends RouterDelegate<List<RouteSettings>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<RouteSettings>> {
  MyAppRoutDelegate(this.state) {
    state.addListener(notifyListeners);
  }

  @override
  void dispose() {
    state.removeListener(notifyListeners);
    state.dispose();
    super.dispose();
  }

  final AppRouteState state;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<void> setNewRoutePath(List<RouteSettings> configuration) async {
    state.updateRoutes(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: state.generatedRoutes,
      onPopPage: _handlePopRoute,
    );
  }

  bool _handlePopRoute(Route<dynamic> route, dynamic result) {
    if (route.settings.name == "/") {
      return false;
    } else {
      return true;
    }
  }
}

class ApRouteInformationParser
    extends RouteInformationParser<List<RouteSettings>> {}
