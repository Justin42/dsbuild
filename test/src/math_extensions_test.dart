import 'dart:math';

import 'package:dsbuild/src/collection/sorted_list.dart';
import 'package:dsbuild/src/math_extensions.dart';
import 'package:test/test.dart';

void main() {
  final SortedList<num> data =
      List.generate(10, (index) => pow(index, 2)).toSortedList(true);

  group('MathExtensions', () {
    test('standardDeviation-population', () async {
      expect(data.mean, 28.5, reason: "Mean is incorrect.");
      expect(data.standardDeviation(population: true), 26.852374196707448,
          reason: "Population standard deviation `s` is incorrect.");
    });
    test('standardDeviation-sample', () async {
      expect(data.mean, 28.5, reason: "Mean is incorrect.");
      expect(data.standardDeviation(population: false), 28.3048876815766,
          reason: "Sample standard deviation `σ` is incorrect.");
    });
  });
}
