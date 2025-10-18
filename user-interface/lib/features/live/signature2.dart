import 'dart:io';
import 'dart:core';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Signature {
  static String? _cachedJarPath;

  // Get the JAR path - cached for performance
  static Future<String> _getJarPath() async {
    if (_cachedJarPath != null) return _cachedJarPath!;

    // For Windows builds, the JAR is in data/flutter_assets/assets/
    if (Platform.isWindows) {
      // Get the executable directory
      final exePath = Platform.resolvedExecutable;
      final exeDir = path.dirname(exePath);
      
      // Try multiple possible locations
      final possiblePaths = [
        // Release build location
        path.join(exeDir, 'data', 'flutter_assets', 'assets', 'cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar'),
        // Debug/development location
        path.join(Directory.current.path, 'assets', 'cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar'),
        // Alternative location
        path.join(exeDir, 'assets', 'cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar'),
      ];

      for (final jarPath in possiblePaths) {
        if (await File(jarPath).exists()) {
          _cachedJarPath = jarPath;
          print('✅ Found JAR at: $jarPath');
          return jarPath;
        } else {
          print('❌ JAR not found at: $jarPath');
        }
      }

      throw Exception('JAR file not found in any expected location');
    } else {
      // For other platforms (Linux, macOS)
      _cachedJarPath = path.join(Directory.current.path, 'assets', 'cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar');
      return _cachedJarPath!;
    }
  }

  // Écrire un fichier texte
  static Future<File> writeTextFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return file.writeAsString(content);
  }

  static Future<ProcessResult> runFile(List<String> args) async {
    final jarPath = await _getJarPath();
    print('🔧 Running JAR: $jarPath');
    return await Process.run('java', ['-jar', jarPath, ...args]);
  }


  // client
  static Future<String> client_verify(String base64)async {
    var result = await runFile(['client','verify',base64]);
    // if (result.stderr.toString().isNotEmpty)
    //   print(result.stdout);
    return result.stdout;
  }

  static Future<String> client_merge(String path) async {
    var result = await runFile(['client','merge',path]);
    if (result.stderr.toString().isNotEmpty){
      print(result.stdout);
      return result.stderr;
      }
    return result.stdout;
  }

  // owner
  static Future<void> owner_init(String id ,String base64) async {
    var result = await runFile(['owner','init',id,base64]);
    // print(result.stderr);
  }

  static Future<List<String>> owner_sign(String path) async {
    var result = await runFile(['owner', 'sign', path]);
    return result.stdout.trim().split('\n');
  }

}