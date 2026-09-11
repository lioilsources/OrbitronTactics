/// Turns a ship's sideways movement into how far it banks, -1 (hard left)
/// to 1 (hard right). The bank eases toward the current speed, so position
/// jumps — a network opponent's 50 ms updates — still read as a smooth turn,
/// and a ship that stops levels out.
class ShipBank {
  /// Sideways speed, in arena widths per second, that banks a ship fully.
  static const double fullBankSpeed = 1.2;

  /// The bank covers most of the way to a new speed within about this long.
  static const double easeMs = 90;

  double _value = 0;
  double? _lastX;
  int? _lastMs;

  double get value => _value;

  /// Takes the ship's position at battle time [elapsedMs] and returns the
  /// bank. Readings at a battle time already seen are ignored.
  double update(double xFraction, int elapsedMs) {
    final lastX = _lastX;
    final lastMs = _lastMs;
    if (lastX == null || lastMs == null) {
      _lastX = xFraction;
      _lastMs = elapsedMs;
      return _value;
    }
    if (elapsedMs <= lastMs) return _value;

    final dt = elapsedMs - lastMs;
    final speed = (xFraction - lastX) / dt * 1000;
    final target = (speed / fullBankSpeed).clamp(-1.0, 1.0);
    _value += (target - _value) * (dt / easeMs).clamp(0.0, 1.0);
    _lastX = xFraction;
    _lastMs = elapsedMs;
    return _value;
  }
}
