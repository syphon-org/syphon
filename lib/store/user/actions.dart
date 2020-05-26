import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/user/model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

final protocol = DotEnv().env['PROTOCOL'];
