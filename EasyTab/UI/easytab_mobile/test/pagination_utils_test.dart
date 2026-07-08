import 'package:easytab_mobile/providers/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationUtils', () {
    test('calculates total pages correctly', () {
      expect(PaginationUtils.totalPages(0, 10), 1);
      expect(PaginationUtils.totalPages(25, 10), 3);
      expect(PaginationUtils.totalPages(11, 5), 3);
    });
  });
}
