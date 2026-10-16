import 'package:easytab_mobile/providers/base_provider.dart';
import 'package:easytab_mobile/models/category.dart';

class CategoryProvider extends BaseProvider<Category> {
  CategoryProvider() : super("Categories");

  @override
  Category fromJson(json) {
    return Category.fromJson(json);
  }
}
