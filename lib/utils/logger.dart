import 'package:cached_build_runner/utils/utils.dart';
import 'package:logger/logger.dart' as logger;

/// A class that provides logging functionality.
class Logger {
  static final _logger = logger.Logger(
    filter: _LogFilter(),
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );

  static final _loggerWithBox = logger.Logger(
    filter: _LogFilter(),
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      printEmojis: false,
    ),
  );

  /// Logs a verbose message.
  ///
  /// If [showPrefix] is `true`, the message will be prefixed with a vertical bar.
  static void v(String message, {bool showPrefix = true}) {
    // ignore: avoid-non-ascii-symbols, ascii here is ok.
    _logger.t('${showPrefix ? '│ ' : ''}$message');
  }

  /// Logs a debug message.
  static void d(String message) {
    _logger.d(message);
  }

  /// Logs an information message.
  static void i(String message) {
    _logger.i(message);
  }

  static void header(String message) {
    _loggerWithBox.i(message);
  }

  /// Logs an error message.
  static void e(String message) {
    _loggerWithBox.e(message);
  }
}

class _LogFilter extends logger.LogFilter {
  /// Returns `true` if the given [event] should be logged, based on the current logging settings.
  ///
  /// This implementation logs all events with level [logger.Level.error] and events with other levels only if [Utils.isVerbose] is `true`.
  @override
  bool shouldLog(logger.LogEvent event) {
    if (event.level == logger.Level.error) return true;

    if (event.level == logger.Level.trace && Utils.isVerbose) return true;

    if (event.level == logger.Level.debug && Utils.isDebug) return true;

    return event.level != logger.Level.trace && event.level != logger.Level.debug;
  }
}
