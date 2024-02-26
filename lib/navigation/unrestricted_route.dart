import 'dart:async';

import 'package:flutter_tips/navigation/mock_token.dart';
import 'package:flutter_tips/navigation/pages.dart';
import 'package:go_router/go_router.dart';

abstract class UnrestrictedRoute {
  UnrestrictedRoute();

  GoRoute get route;
  FutureOr<String?> accept(String target, MockAuthToken? token);
}
