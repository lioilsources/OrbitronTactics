import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/maneuvers/pattern_recognizer.dart';

void main() {
  late PatternRecognizer recognizer;

  setUp(() => recognizer = PatternRecognizer());

  /// Drags a finger over the centre of every dot in turn.
  void drag(List<int> dots) {
    for (final dot in dots) {
      final (x, y) = PatternRecognizer.centreOf(dot);
      recognizer.touch(x, y);
    }
  }

  group('PatternRecognizer', () {
    test('collects the dots the finger touches', () {
      drag([3, 4, 5]);

      expect(recognizer.end(), [3, 4, 5]);
    });

    test('picks up a dot dragged across', () {
      drag([0, 2]);
      expect(recognizer.gesture, [0, 1, 2]);

      recognizer.reset();
      drag([0, 8]);
      expect(recognizer.gesture, [0, 4, 8]);
    });

    test('leaves an already visited dot where it is', () {
      drag([1, 0, 2]);

      expect(recognizer.end(), [1, 0, 2]);
    });

    test('a shaking finger does not repeat a dot', () {
      final (x, y) = PatternRecognizer.centreOf(4);
      recognizer.touch(x, y);
      recognizer.touch(x + 0.02, y - 0.01);
      recognizer.touch(x - 0.01, y + 0.02);
      drag([5, 8]);

      expect(recognizer.end(), [4, 5, 8]);
    });

    test('two dots are not a gesture', () {
      drag([0, 1]);

      expect(recognizer.end(), isEmpty);
    });

    test('ending clears the gesture for the next one', () {
      drag([3, 4, 5]);
      recognizer.end();

      expect(recognizer.isEmpty, isTrue);
      expect(recognizer.end(), isEmpty);
    });

    test('a finger between dots touches nothing', () {
      recognizer.touch(0.35, 0.35);

      expect(recognizer.gesture, isEmpty);
    });
  });
}
