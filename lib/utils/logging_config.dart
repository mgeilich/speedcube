import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Initializes the logging framework.
void initLogging() {
  // Set the default log level.
  // In debug mode, we might want more detail.
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
          '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('Stack trace:\n${record.stackTrace}');
      }
    }

    // In production, you could forward these to a service like Sentry or Firebase Crashlytics.
  });
}
