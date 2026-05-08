import 'dart:convert';
import 'dart:io';
import 'package:easytab_desktop/providers/base_provider.dart';

class FileProvider extends BaseProvider<String> {
  FileProvider() : super("File");

  @override
  String fromJson(json) => json.toString();

  Future<String> uploadImage(File file, String subfolder) async {
    final imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  Future<void> deleteImage(
    String fileUrl,
    String subfolder, {
    int? userId,
  }) async {
    // Brisanje je sada lokalno kroz update payload-a (null/empty),
    // nema više potrebe za File endpointom.
    return;
  }
}
