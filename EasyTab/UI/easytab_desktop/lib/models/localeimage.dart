import 'package:json_annotation/json_annotation.dart';

part 'localeimage.g.dart';

@JsonSerializable()
class LocaleImage {
  final int? id;
  final String? fileName;
  final String? contentType;
  final String? base64Content;
  final int? localeId;



  LocaleImage({
    this.id,
    this.fileName,
    this.contentType,
    this.base64Content,
    this.localeId
  });

    factory LocaleImage.fromJson(Map<String, dynamic> json) =>
      _$LocaleImageFromJson(json);

  Map<String, dynamic> toJson() => _$LocaleImageToJson(this);

}