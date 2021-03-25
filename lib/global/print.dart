import 'package:logger/logger.dart';

typedef PrintInfo = void Function(String message, {String tag});
typedef PrintDebug = void Function(String message, {String tag});
typedef PrintWarning = void Function(String message, {String tag});
typedef PrintError = void Function(String message, {String tag});

class SimpleLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    try {
      final body = event.message.toString();
      final color = PrettyPrinter.levelColors[event.level];
      final emoji = PrettyPrinter.levelEmojis[event.level];
      print(color('$emoji  $body'));
    } catch (error) {
      print(error.toString());
    }
  }
}

final logger = Logger(
  printer: PrettyPrinter(
      methodCount: 0, // number of method calls to be displayed
      errorMethodCount: 0, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
      ),
);

final loggerNormal = Logger(
  printer: SimpleLogPrinter(),
);

void _printInfo(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.i(body);
}

void _printDebug(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.d(body);
}

void _printWarning(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.w(body);
}

void _printError(String content, {String tag}) {
  final body = tag != null ? '$tag - $content' : content;
  logger.e(body);
}

PrintInfo printInfo = _printInfo;
PrintDebug printDebug = _printDebug;
PrintWarning printWarning = _printWarning;
PrintError printError = _printError;
