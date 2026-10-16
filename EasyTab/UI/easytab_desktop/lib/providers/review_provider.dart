import 'package:easytab_desktop/models/review.dart';
import 'package:easytab_desktop/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Reviews");

  @override
  Review fromJson(json) => Review.fromJson(json);
}
