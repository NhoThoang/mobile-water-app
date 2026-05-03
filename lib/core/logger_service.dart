import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileLogOutput extends LogOutput {
  final int maxFileSize = 2 * 1024 * 1024; // 2MB mỗi file
  final int maxFiles = 3;

  @override
  void output(OutputEvent event) async {
    for (var line in event.lines) {
      print(line);
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/app_log_0.txt');
      
      // Kiểm tra kích thước và xoay vòng nếu cần
      if (await logFile.exists() && await logFile.length() > maxFileSize) {
        await _rotateLogs(directory.path);
      }

      final timestamp = DateTime.now().toIso8601String();
      await logFile.writeAsString(
        '[$timestamp] ${event.lines.join('\n')}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      print("Lỗi ghi log: $e");
    }
  }

  Future<void> _rotateLogs(String dirPath) async {
    // Xoay vòng: log_1 -> log_2, log_0 -> log_1
    for (int i = maxFiles - 1; i >= 1; i--) {
      final currentFile = File('$dirPath/app_log_${i - 1}.txt');
      final nextFile = File('$dirPath/app_log_$i.txt');
      
      if (await currentFile.exists()) {
        if (await nextFile.exists()) await nextFile.delete();
        await currentFile.rename(nextFile.path);
      }
    }
  }
}

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 1, printTime: true),
    output: FileLogOutput(),
  );

  static void i(String message) => _logger.i(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) => 
      _logger.e(message, error: error, stackTrace: stackTrace);
  static void w(String message) => _logger.w(message);
}
