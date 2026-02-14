import 'package:flutter/foundation.dart';

@immutable
class LoginRedirect {
  /// If set, navigate to this route after login success.
  final String? goTo;

  /// If true, attempt to `pop()` the login screen on success.
  /// Useful when login was opened over an existing screen (ex: Detail).
  final bool popOnSuccess;

  const LoginRedirect({this.goTo, this.popOnSuccess = false});

  const LoginRedirect.go(String path)
      : goTo = path,
        popOnSuccess = false;

  const LoginRedirect.pop()
      : goTo = null,
        popOnSuccess = true;
}
