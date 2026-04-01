import 'dart:convert';
import 'dart:io';
import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileProvider extends BaseProvider<String> {
  FileProvider() : super("File");

  @override
  String fromJson(json) => json.toString();

  Future<String> uploadImage(File file, String subfolder) async {
    final url = Uri.parse('${BaseProvider.baseUrl}/File?subfolder=$subfolder');
    final headers = createHeaders()..remove('Content-Type');

    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', _getExtension(file.path)),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['fileUrl'] as String;
    } else {
      throw Exception('Upload slike nije uspio: ${response.body}');
    }
  }

  String _getExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      default:
        return 'jpeg';
    }
  }

  Future<void> deleteImage(
    String fileUrl,
    String subfolder, {
    int? userId,
  }) async {
    var url =
        "${BaseProvider.baseUrl}/File/delete"
        "?fileUrl=${Uri.encodeComponent(fileUrl)}"
        "&subfolder=${Uri.encodeComponent(subfolder)}";

    if (userId != null) {
      url += "&userId=$userId";
    }

    var uri = Uri.parse(url);
    var response = await http.delete(uri, headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception("Greška pri brisanju slike");
    }
  }
}
