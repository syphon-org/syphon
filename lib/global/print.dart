void printInfo(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print('\u001b[32m$body\u001b[0m');
}

void printWarning(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print('\u001b[34m$body\u001b[0m');
}

void printError(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print('\u001b[31m$body\u001b[0m');
}

void printDebug(String content, {String title}) {
  final body = title != null ? '[$title] $content' : content;
  print(body);
}
