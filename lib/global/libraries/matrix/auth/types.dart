/// https://matrix.org/docs/spec/client_server/latest#id183
///
/// Authentication Types
///
/// Can be used during actual login or interactive auth for confirmation
class MatrixAuthTypes {
  static const PASSWORD = 'm.login.password';
  static const RECAPTCHA = 'm.login.recaptcha';
  static const TOKEN = 'm.login.token';
  static const TERMS = 'm.login.terms';
  static const DUMMY = 'm.login.dummy';
  static const SSO = 'm.login.sso';
  static const EMAIL = 'm.login.email.identity';
}

enum AuthTypes {
  Password,
  SSO,
}

enum ThirdPartyIDMedium {
  email,
  msisn,
}

extension ThirdPartyIDMediumValue on ThirdPartyIDMedium {
  static String _value(ThirdPartyIDMedium val) {
    return val.toString().split('.')[1];
  }

  String get value => _value(this);
}

class LoginFlow {
  final String? type;

  LoginFlow(this.type);
}

class LoginFlowResponse {
  final List<LoginFlow> flows;

  LoginFlowResponse(this.flows);
}
