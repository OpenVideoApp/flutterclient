import 'package:logger/logger.dart';

final logger = Logger(printer: SimpleLogPrinter());

class SimpleLogPrinter extends LogPrinter {
  @override
  void log(Level level, message, error, StackTrace stackTrace) {
    //var color = PrettyPrinter.levelColors[level];
    var emoji = PrettyPrinter.levelEmojis[level];
    println('$emoji - $message');
  }
}
