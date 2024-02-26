import 'dart:async';

import 'package:flutter_tips/navigation/mock_token.dart';
import 'package:flutter_tips/navigation/go_observer.dart';
import 'package:flutter_tips/navigation/restricted_route.dart';
import 'package:flutter_tips/navigation/unrestricted_route.dart';
import 'package:go_router/go_router.dart';

class RouteRedirection {
  final UnrestrictedRoute splashRoute;
  final RestrictedRoute authRoute;
  final List<RestrictedRoute> authenticatedRoutes;
  final GoObserver observer;

  RouteRedirection({
    required this.observer,
    required this.splashRoute,
    required this.authRoute,
    this.authenticatedRoutes = const [],
  });

  RouteBase get rootRoute {
    return GoRoute(
      path: '/',
      routes: [
        splashRoute.route,
        authRoute.route,
        ...authenticatedRoutes.map((e) => e.route),
      ],
      redirect: (context, state) async {
        print("Doing RouteRedirection");
        final pending = _pendingRedirectionForBootstrapping(state.location);

        if (pending) {
          return splashRoute.route.path;
        }

        final token = await MockApi.instance.token;

        final matchedPath = await _redirect(state.location, token);

        // matchedPath should never be null

        return matchedPath;
      },
    );
  }

  FutureOr<String?> _redirect(
      String targetLocation, MockAuthToken? token) async {
    if (token != null && !token.accountVerified) {
      MockApi.instance.clear();
    }

    final authPath = await authRoute.accept(targetLocation, token);

    if (authPath != null) {
      return authPath;
    }

    for (final route in authenticatedRoutes) {
      final acceptedPath = await route.accept(targetLocation, token);

      if (acceptedPath != null) {
        return acceptedPath;
      }
    }

    // should never reach here
    return null;
  }

  String? _pendingRedirection;

  bool _pendingRedirectionForBootstrapping(String targetLocation) {
    if (observer.isBootStrapping) {
      _pendingRedirection = targetLocation;
      return true;
    }

    return false;
  }

  FutureOr<String> getRedirectionForBootstrapping(MockAuthToken? token) async {
    assert(_pendingRedirection != null,
        "should invoke this method after bootstrapping");

    final target = _pendingRedirection ?? authRoute.route.path;

    _pendingRedirection = null;

    final matchedPath = await _redirect(target, token);

    return matchedPath ?? target;
  }
}
