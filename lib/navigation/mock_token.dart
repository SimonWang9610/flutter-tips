class MockAuthToken {
  final bool accountVerified;

  MockAuthToken(this.accountVerified);
}

class MockApi {
  static final MockApi instance = MockApi();

  MockAuthToken? _token;

  bool _verified = false;

  bool _user = false;

  Future<MockAuthToken?> get token async {
    if (_token == null) {
      await Future.delayed(const Duration(milliseconds: 200));
      _token = MockAuthToken(_verified);
      return _token;
    } else if (_token!.accountVerified) {
      return _token!;
    } else {
      _verified = true;
      _token = MockAuthToken(_verified);
      return _token;
    }
  }

  Future<bool> get user async {
    if (!_user) {
      await Future.delayed(const Duration(milliseconds: 200));
      _user = true;
      return _user;
    } else {
      return _user;
    }
  }

  void clear() {
    _token = null;
  }
}
