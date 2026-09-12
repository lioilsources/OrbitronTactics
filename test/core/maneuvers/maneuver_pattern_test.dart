import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/maneuvers/maneuver_pattern.dart';

void main() {
  group('Pattern.between', () {
    test('finds the dot a straight drag passes over', () {
      expect(Pattern.between(0, 2), 1);
      expect(Pattern.between(6, 8), 7);
      expect(Pattern.between(0, 6), 3);
      expect(Pattern.between(1, 7), 4);
      expect(Pattern.between(0, 8), 4);
      expect(Pattern.between(2, 6), 4);
    });

    test('neighbours and knight moves pass over nothing', () {
      expect(Pattern.between(0, 1), isNull);
      expect(Pattern.between(4, 8), isNull);
      expect(Pattern.between(0, 5), isNull);
      expect(Pattern.between(3, 1), isNull);
    });
  });

  group('Pattern.isValid', () {
    test('takes three or more different dots', () {
      expect(Pattern.isValid([3, 4, 5]), isTrue);
      expect(Pattern.isValid([3, 4]), isFalse);
      expect(Pattern.isValid([3, 4, 4]), isFalse);
      expect(Pattern.isValid([3, 4, 9]), isFalse);
    });

    test('refuses a gesture that skips a dot it has not visited', () {
      expect(Pattern.isValid([0, 2, 4]), isFalse);
      // 1 is visited before the drag from 0 to 2 passes over it.
      expect(Pattern.isValid([1, 0, 2]), isTrue);
    });
  });

  test('mirror flips the gesture left to right', () {
    expect(Pattern.mirror([0, 1, 2]), [2, 1, 0]);
    expect(Pattern.mirror([3, 4, 5]), [5, 4, 3]);
    expect(Pattern.mirror([0, 3, 6, 7]), [2, 5, 8, 7]);
    expect(Pattern.mirror(Pattern.mirror([1, 5, 7, 3])), [1, 5, 7, 3]);
  });
}
