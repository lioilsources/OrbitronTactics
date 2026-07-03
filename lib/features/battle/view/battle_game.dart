import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../model/battle_simulation.dart';
import '../net/battle_controller.dart';

/// Mutable on-screen control state, written by the UI controls each frame and
/// read by [BattleGame] to feed the [BattleController].
class BattleInputState {
  double turn = 0; // -1..1
  bool thrust = false;
  bool fire = false;
  bool shield = false;

  BattleInput toBattleInput() =>
      BattleInput(turn: turn, thrust: thrust, fire: fire, shield: shield);
}

/// Thin Flame view over the authoritative [BattleController].
///
/// The game owns no simulation state of its own: each frame it pushes the
/// local input into the controller, advances it ([BattleController.tick]) and
/// renders [BattleController.latestSnapshot]. The host's tick steps the real
/// simulation; the guest's tick just ships input and renders received
/// snapshots.
class BattleGame extends FlameGame {
  final BattleController controller;
  final BattleConfig config;
  final BattleRole localRole;
  final BattleInputState input;
  final void Function(BattleRole winner) onFinished;

  bool _notified = false;

  BattleGame({
    required this.controller,
    required this.config,
    required this.localRole,
    required this.input,
    required this.onFinished,
  });

  @override
  Future<void> onLoad() async {
    add(_ArenaRenderer(this));
  }

  @override
  void update(double dt) {
    super.update(dt);
    controller.localInput = input.toBattleInput();
    controller.tick();

    if (controller.finished && !_notified) {
      _notified = true;
      onFinished(controller.winner!);
    }
  }
}

/// Draws the latest snapshot, scaling the logical arena into the widget.
class _ArenaRenderer extends Component {
  final BattleGame game;
  _ArenaRenderer(this.game);

  final Paint _bg = Paint()..color = const Color(0xFF0B0B1A);
  final Paint _asteroid = Paint()..color = const Color(0xFF6B6B7B);
  final Paint _projectile = Paint()..color = const Color(0xFFFFE08A);
  final Paint _attacker = Paint()..color = const Color(0xFF5BC0FF);
  final Paint _defender = Paint()..color = const Color(0xFFFF6B6B);
  final Paint _hpBack = Paint()..color = const Color(0x55FFFFFF);
  final Paint _hpFront = Paint()..color = const Color(0xFF7CFF7C);
  final Paint _shield = Paint()
    ..color = const Color(0x887CE0FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void render(Canvas canvas) {
    final snap = game.controller.latestSnapshot;
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) return;

    final scale = math.min(
        size.x / game.config.arenaWidth, size.y / game.config.arenaHeight);
    final offsetX = (size.x - game.config.arenaWidth * scale) / 2;
    final offsetY = (size.y - game.config.arenaHeight * scale) / 2;

    Offset toScreen(double x, double y) =>
        Offset(offsetX + x * scale, offsetY + y * scale);

    // Arena background.
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, game.config.arenaWidth * scale,
          game.config.arenaHeight * scale),
      _bg,
    );

    if (snap == null) return;

    for (final a in snap.asteroids) {
      canvas.drawCircle(toScreen(a.x, a.y), a.radius * scale, _asteroid);
    }
    for (final p in snap.projectiles) {
      canvas.drawCircle(
          toScreen(p.x, p.y), game.config.projectileRadius * scale,
          _projectile);
    }

    _drawShip(canvas, toScreen, scale, snap.attacker, snap.attacker.angle,
        _attacker);
    _drawShip(canvas, toScreen, scale, snap.defender, snap.defender.angle,
        _defender);
  }

  void _drawShip(Canvas canvas, Offset Function(double, double) toScreen,
      double scale, ShipSnapshot ship, double angle, Paint paint) {
    final center = toScreen(ship.x, ship.y);
    final r = game.config.shipRadius * scale;

    // Triangle pointing along the ship's facing.
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final a = angle + i * 2 * math.pi / 3;
      final len = i == 0 ? r : r * 0.7;
      final pt = Offset(
          center.dx + math.cos(a) * len, center.dy + math.sin(a) * len);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Shield ring while active.
    if (ship.shielded) {
      canvas.drawCircle(center, r * 1.5, _shield);
    }

    // HP bar above the ship.
    final hpFrac = (ship.hp / ship.maxHp).clamp(0.0, 1.0);
    final barW = r * 2.4;
    final barH = math.max(2.0, r * 0.18);
    final barLeft = center.dx - barW / 2;
    final barTop = center.dy - r - barH * 2;
    canvas.drawRect(Rect.fromLTWH(barLeft, barTop, barW, barH), _hpBack);
    canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barW * hpFrac, barH), _hpFront);
  }
}
