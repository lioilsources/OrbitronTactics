import 'package:flutter/material.dart';

import '../../../../core/maneuvers/maneuver.dart';
import '../../../../core/maneuvers/maneuver_pattern.dart';
import '../../../../core/maneuvers/pattern_recognizer.dart';
import 'pattern_glyph.dart';

/// The pad a player draws a gesture on to hand the ship over to a maneuver.
///
/// Three by three dots, as on a lock screen: the finger picks up the dots it
/// crosses, and on release an exact match with one of the armed [slots] —
/// or with its mirror, for a maneuver that has one — flies it. Under the pad
/// sit the energy left and the armed gestures, so they can be learned in the
/// middle of a fight.
class ManeuverPad extends StatefulWidget {
  const ManeuverPad({
    super.key,
    required this.slots,
    required this.energy,
    required this.accent,
    required this.onManeuver,
    this.enabled = true,
    this.size = 96,
  });

  final List<ManeuverSlot> slots;

  /// What the ship has left, 0–[maxEnergy].
  final double energy;
  final Color accent;
  final bool enabled;
  final void Function(ManeuverSlot slot, {required bool mirrored}) onManeuver;
  final double size;

  static const double maxEnergy = 100;

  @override
  State<ManeuverPad> createState() => _ManeuverPadState();
}

class _ManeuverPadState extends State<ManeuverPad> {
  final _recognizer = PatternRecognizer();
  List<int> _drawn = const [];
  Offset? _finger;
  bool _rejected = false;

  bool _affords(ManeuverSlot slot) =>
      widget.energy >= slot.maneuver.costAt(slot.level);

  void _onDown(Offset local) {
    if (!widget.enabled) return;
    _recognizer.reset();
    _rejected = false;
    _onMove(local);
  }

  void _onMove(Offset local) {
    if (!widget.enabled) return;
    _recognizer.touch(local.dx / widget.size, local.dy / widget.size);
    setState(() {
      _drawn = _recognizer.gesture;
      _finger = local;
    });
  }

  void _onUp() {
    final gesture = _recognizer.end();
    setState(() {
      _drawn = const [];
      _finger = null;
    });
    if (!widget.enabled || gesture.isEmpty) return;

    for (final slot in widget.slots) {
      final pattern = slot.maneuver.pattern;
      if (Pattern.same(pattern, gesture)) {
        _start(slot, mirrored: false);
        return;
      }
      if (slot.maneuver.mirrorable &&
          Pattern.same(Pattern.mirror(pattern), gesture)) {
        _start(slot, mirrored: true);
        return;
      }
    }
    _reject();
  }

  void _start(ManeuverSlot slot, {required bool mirrored}) {
    if (!_affords(slot)) {
      _reject();
      return;
    }
    widget.onManeuver(slot, mirrored: mirrored);
  }

  Future<void> _reject() async {
    setState(() => _rejected = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (mounted) setState(() => _rejected = false);
  }

  @override
  Widget build(BuildContext context) {
    final glyph = (widget.size - 10) / 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _onDown(event.localPosition),
          onPointerMove: (event) => _onMove(event.localPosition),
          onPointerUp: (_) => _onUp(),
          onPointerCancel: (_) => _onUp(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: const Color(0xFF15152B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _rejected
                    ? Colors.redAccent
                    : widget.accent
                        .withValues(alpha: widget.enabled ? 0.5 : 0.15),
                width: _rejected ? 2 : 1,
              ),
            ),
            child: CustomPaint(
              painter: _PadPainter(
                gesture: _drawn,
                finger: _finger,
                color: widget.accent,
                enabled: widget.enabled,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: widget.size,
          height: 5,
          child: CustomPaint(
            painter: _EnergyPainter(
              energy: widget.energy,
              costs: [
                for (final slot in widget.slots)
                  slot.maneuver.costAt(slot.level),
              ],
              color: widget.accent,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final slot in widget.slots)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: PatternGlyph(
                  pattern: slot.maneuver.pattern,
                  color: widget.accent,
                  size: glyph,
                  dimmed: !_affords(slot),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter({
    required this.gesture,
    required this.finger,
    required this.color,
    required this.enabled,
  });

  final List<int> gesture;
  final Offset? finger;
  final Color color;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    Offset dotAt(int dot) {
      final (x, y) = PatternRecognizer.centreOf(dot);
      return Offset(x * size.width, y * size.height);
    }

    final idle = Paint()
      ..color = Colors.white.withValues(alpha: enabled ? 0.22 : 0.08);
    final taken = Paint()..color = color;
    for (var dot = 0; dot < Pattern.dots; dot++) {
      final drawn = gesture.contains(dot);
      canvas.drawCircle(
          dotAt(dot), size.shortestSide * (drawn ? 0.055 : 0.04),
          drawn ? taken : idle);
    }
    if (gesture.isEmpty) return;

    final trail = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(dotAt(gesture.first).dx, dotAt(gesture.first).dy);
    for (final dot in gesture.skip(1)) {
      path.lineTo(dotAt(dot).dx, dotAt(dot).dy);
    }
    canvas.drawPath(path, trail);

    final at = finger;
    if (at != null) {
      canvas.drawLine(dotAt(gesture.last), at,
          trail..color = color.withValues(alpha: 0.4));
    }
  }

  @override
  bool shouldRepaint(_PadPainter oldDelegate) =>
      oldDelegate.gesture != gesture ||
      oldDelegate.finger != finger ||
      oldDelegate.enabled != enabled;
}

/// The energy bar under the pad, with a mark at each armed maneuver's price.
class _EnergyPainter extends CustomPainter {
  _EnergyPainter({
    required this.energy,
    required this.costs,
    required this.color,
  });

  final double energy;
  final List<int> costs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(
        track, Paint()..color = Colors.white.withValues(alpha: 0.12));

    final filled = (energy / ManeuverPad.maxEnergy).clamp(0.0, 1.0);
    if (filled > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & Size(size.width * filled, size.height), radius),
        Paint()..color = color.withValues(alpha: 0.85),
      );
    }
    for (final cost in costs) {
      final at = size.width * (cost / ManeuverPad.maxEnergy).clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(at, 0),
        Offset(at, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: energy >= cost ? 0.7 : 0.35)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_EnergyPainter oldDelegate) =>
      oldDelegate.energy != energy || oldDelegate.color != color;
}
