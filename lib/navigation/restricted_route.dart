import 'dart:async';

import 'package:flutter_tips/navigation/mock_token.dart';
import 'package:flutter_tips/navigation/pages.dart';
import 'package:go_router/go_router.dart';

abstract class RestrictedRoute {
  RestrictedRoute();

  GoRoute get route;

  // return the matched path if the given target is acceptable based on the token
  FutureOr<String?> accept(String target, MockAuthToken? token);
}

class AppRoute extends RestrictedRoute {
  static const path = "/app";
  AppRoute();

  @override
  GoRoute get route => GoRoute(
        path: path,
        routes: [
          GoRoute(
            path: "/:id",
            builder: (context, state) => const MockPage(
              name: "App Page",
              url: path,
            ),
          ),
        ],
        builder: (context, state) =>
            const MockPage(name: "App Page", url: path),
      );

  @override
  FutureOr<String?> accept(String target, MockAuthToken? token) async {
    if (token == null || !token.accountVerified) {
      return null;
    }

    final hasUser = await MockApi.instance.user;

    if (hasUser && target.startsWith(path)) {
      return target;
    }

    return null;
  }
}

class AuthRoute extends RestrictedRoute {
  static const path = "/auth";

  AuthRoute();

  @override
  GoRoute get route => GoRoute(
        path: path,
        builder: (context, state) =>
            const MockPage(name: "Auth Page", url: path),
      );

  @override
  FutureOr<String?> accept(String target, MockAuthToken? token) {
    if (token == null) {
      return path;
    } else if (!token.accountVerified) {
      return "$path/verify";
    } else {
      return null;
    }
  }
}
