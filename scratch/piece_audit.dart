import 'package:logging/logging.dart';

void main() {
  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print(record.message);
  });
  final logger = Logger('PieceAudit');

  logger.info('--- Generating Perfect Cycles ---');
  
  // U: 0-8, R: 9-17, F: 18-26, D: 27-35, L: 36-44, B: 45-53
}
