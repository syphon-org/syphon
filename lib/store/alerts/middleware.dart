import 'package:redux/redux.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// Alert Middleware
///
/// Authentication may be lost or need additional info at any point
/// after authenticating, this will catch errors that may arise
///
/// We can intercept these errors by inspecting strange or
/// unformatted alerts from matrix
///
dynamic alertMiddleware<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) async {
  switch (action.runtimeType) {
    case AddAlert:
      final alert = action.alert.error;

      // TODO: prompt user that they're going to be redirected for a terms
      // and conditions acceptance
      if (alert.contains(MatrixErrorsSoft.terms_and_conditions)) {
        final termsUrl = 'https${alert.split('https')[1]}';
        final termsUrlFormatted =
            termsUrl.replaceFirst('.', '', termsUrl.length - 1);

        if (await canLaunch(termsUrlFormatted)) {
          return await launch(termsUrlFormatted, forceSafariVC: false);
        } else {
          throw 'Could not launch ${termsUrl}';
        }
      }

      break;
    default:
      break;
  }

  next(action);
}
