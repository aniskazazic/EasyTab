import 'package:easytab_desktop/providers/base_provider.dart';
import 'package:easytab_desktop/models/localeimage.dart';

class LocaleImageProvider extends BaseProvider<LocaleImage> {
  LocaleImageProvider() : super("LocaleImages");

  @override
  LocaleImage fromJson(json) {
    return LocaleImage.fromJson(json);
  }
}
