import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/features/battle/presentation/widgets/ship_bank.dart';

void main() {
  group('ShipBank', () {
    /// Feeds [bank] a ship moving at [speed] arena widths per second in
    /// 16 ms ticks from [fromMs] to [toMs]; returns where the ship ends.
    double fly(ShipBank bank, double x, double speed, int fromMs, int toMs) {
      for (var ms = fromMs; ms <= toMs; ms += 16) {
        x += speed * 16 / 1000;
        bank.update(x, ms);
      }
      return x;
    }

    test('banks into a turn and levels out when the ship stops', () {
      final bank = ShipBank()..update(0.5, 0);

      final x = fly(bank, 0.5, 1.0, 16, 160);
      expect(bank.value, greaterThan(0.5));

      fly(bank, x, 0, 176, 600);
      expect(bank.value.abs(), lessThan(0.05));
    });

    test('banks left when moving left, never past full', () {
      final bank = ShipBank()..update(0.9, 0);

      fly(bank, 0.9, -2.5, 16, 320);

      expect(bank.value, lessThan(-0.9));
      expect(bank.value, greaterThanOrEqualTo(-1.0));
    });

    test('ignores readings at a battle time it has already seen', () {
      final bank = ShipBank()..update(0.5, 0);
      bank.update(0.52, 16);
      final value = bank.value;

      bank.update(0.9, 16);

      expect(bank.value, value);
    });
  });
}
