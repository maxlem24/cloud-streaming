import 'dart:io';
import 'dart:core';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Signature {


// Écrire un fichier texte
  static Future<File> writeTextFile(String filename, String content) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    return file.writeAsString(content);
  }

  static Future<ProcessResult> runFile (List<String> args) async {
    var projectDir = Directory.current.path;
    var jarPath = path.join(projectDir, 'assets', 'cloud_signature-1.0-SNAPSHOT-jar-with-dependencies.jar');


    return await Process.run('java', ['-jar', jarPath, ...args]);
  }


  // client
  static Future<String> client_verify(String base64)async {
    var result = await runFile(['client','verify',base64]);
    if (result.stderr.toString().isNotEmpty) {
      print(result.stdout);
    }
    return result.stdout;
  }

  static Future<String> client_merge(String path) async {
    var result = await runFile(['client','merge',path]);
    if (result.stderr.toString().isNotEmpty) {
      print(result.stdout);
    }
    return result.stdout;
  }

  // owner
  static Future<void> owner_init(String id ,String base64) async {
    var result = await runFile(['owner','init',id,base64]);
    // print(result.stderr);
  }

  static Future<String> owner_sign(String path) async {
    var result = await runFile(['owner', 'sign', path]);
    return result.stdout;
  }

}