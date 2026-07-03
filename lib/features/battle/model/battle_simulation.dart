/// Pure-Dart, dependency-free authoritative simulation for the Archon-style
/// real-time battle arena.
///
/// This deliberately has **no Flame / Flutter dependency** so it can run
/// head-less in unit tests and so the rendering layer (Flame) is a thin view
/// on top of it. In the local-network co-op mode the game host runs this
/// simulation authoritatively and broadcasts [BattleSnapshot]s; the other
/// device renders the snapshots and only sends its [BattleInput].
library;

import 'dart:math' as math;

import '../../../core/game_logic/models/unit_stats.dart';

/// Which side of a battle a ship represents. The [BattleRole.attacker] is the
/// piece that initiated the capture; [BattleRole.defender] is the piece being
/// attacked. The losing role's piece is removed from the board.
enum BattleRole { attacker, defender }

/// Per-tick control input for a single ship.
class BattleInput {
  /// Steering, clamped to [-1, 1]. Negative turns left, positive turns right.
  final double turn;

  /// Whether the main thruster is firing.
  final bool thrust;

  /// Whether the weapon trigger is held (respects the fire cooldown).
  final bool fire;

  /// Whether the shield trigger is held (respects the shield cooldown).
  final bool shield;

  const BattleInput({
    this.turn = 0,
    this.thrust = false,
    this.fire = false,
    this.shield = false,
  });

  static const BattleInput idle = BattleInput();

  Map<String, dynamic> toJson() => {
        'turn': turn,
        'thrust': thrust,
        'fire': fire,
        'shield': shield,
      };

  factory BattleInput.fromJson(Map<String, dynamic> json) => BattleInput(
        turn: (json['turn'] as num).toDouble(),
        thrust: json['thrust'] as bool,
        fire: json['fire'] as bool,
        shield: json['shield'] as bool? ?? false,
      );
}

/// Tunable constants for the arena. Defaults are sized in abstract "logical"
/// units; the renderer scales them to the screen.
class BattleConfig {
  final double arenaWidth;
  final double arenaHeight;

  final double shipRadius;
  final double shipMaxHp;
  final double shipThrust; // acceleration units/s^2
  final double shipTurnRate; // rad/s
  final double shipMaxSpeed; // units/s
  final double shipDrag; // velocity multiplier per second

  final double fireCooldown; // seconds between shots
  final double projectileSpeed; // units/s
  final double projectileRadius;
  final double projectileLife; // seconds
  final double projectileDamage;

  final int asteroidCount;
  final double asteroidMinRadius;
  final double asteroidMaxRadius;
  final double asteroidMinSpeed;
  final double asteroidMaxSpeed;
  final double asteroidDamage;

  /// Maximum battle duration in ticks before a sudden-death resolution.
  final int maxTicks;

  const BattleConfig({
    this.arenaWidth = 1000,
    this.arenaHeight = 600,
    this.shipRadius = 16,
    this.shipMaxHp = 100,
    this.shipThrust = 650,
    this.shipTurnRate = 3.6,
    this.shipMaxSpeed = 360,
    this.shipDrag = 0.6,
    this.fireCooldown = 0.25,
    this.projectileSpeed = 620,
    this.projectileRadius = 4,
    this.projectileLife = 1.4,
    this.projectileDamage = 12,
    this.asteroidCount = 5,
    this.asteroidMinRadius = 20,
    this.asteroidMaxRadius = 42,
    this.asteroidMinSpeed = 40,
    this.asteroidMaxSpeed = 130,
    this.asteroidDamage = 18,
    this.maxTicks = 90 * 60, // 90 seconds at 60 ticks/s
  });
}

/// Fixed simulation timestep (60 ticks per second).
const double kBattleDt = 1 / 60;

/// Per-ship combat parameters derived from a unit's (possibly upgraded)
/// [UnitStats]. When absent the ship falls back to the [BattleConfig] globals,
/// which keeps un-leveled battles and existing tests unchanged.
class ShipSpec {
  final double maxHp;
  final double projectileDamage;
  final double fireCooldown; // seconds between shots

  /// Fraction of incoming damage absorbed passively (0..1).
  final double defenseRating;

  final double shieldDuration; // seconds of invulnerability per activation
  final double shieldCooldown; // seconds between activations

  const ShipSpec({
    required this.maxHp,
    required this.projectileDamage,
    required this.fireCooldown,
    this.defenseRating = 0,
    this.shieldDuration = 1.5,
    this.shieldCooldown = 5,
  });

  /// Derive arena parameters from a unit's (possibly upgraded) stats.
  factory ShipSpec.fromUnitStats(UnitStats stats) => ShipSpec(
        maxHp: stats.maxHp.toDouble(),
        projectileDamage: stats.damage.toDouble(),
        fireCooldown: stats.attackIntervalMs / 1000,
        defenseRating: stats.defenseRating,
        shieldDuration: stats.shieldDurationMs / 1000,
        shieldCooldown: stats.shieldCooldownMs / 1000,
      );

  Map<String, dynamic> toJson() => {
        'hp': maxHp,
        'dmg': projectileDamage,
        'fcd': fireCooldown,
        'def': defenseRating,
        'shd': shieldDuration,
        'shc': shieldCooldown,
      };

  factory ShipSpec.fromJson(Map<String, dynamic> j) => ShipSpec(
        maxHp: (j['hp'] as num).toDouble(),
        projectileDamage: (j['dmg'] as num).toDouble(),
        fireCooldown: (j['fcd'] as num).toDouble(),
        defenseRating: (j['def'] as num?)?.toDouble() ?? 0,
        shieldDuration: (j['shd'] as num?)?.toDouble() ?? 1.5,
        shieldCooldown: (j['shc'] as num?)?.toDouble() ?? 5,
      );
}

class _Ship {
  final ShipSpec spec;
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double angle; // radians
  double hp;
  double cooldown = 0;
  double shieldRemaining = 0; // seconds of active shield left
  double shieldCooldownRemaining = 0; // seconds until shield can re-activate

  _Ship({
    required this.spec,
    required this.x,
    required this.y,
    required this.angle,
  }) : hp = spec.maxHp;

  bool get shielded => shieldRemaining > 0;
}

class _Projectile {
  double x;
  double y;
  final double vx;
  final double vy;
  double life;
  final BattleRole owner;

  _Projectile({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.owner,
  });
}

class _Asteroid {
  double x;
  double y;
  double vx;
  double vy;
  final double radius;

  _Asteroid({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

/// Immutable per-entity views used for rendering and network sync.
class ShipSnapshot {
  final double x;
  final double y;
  final double angle;
  final double hp;
  final double maxHp;
  final bool shielded;

  /// Seconds until the shield can be activated again (0 = ready).
  final double shieldCooldownRemaining;

  const ShipSnapshot({
    required this.x,
    required this.y,
    required this.angle,
    required this.hp,
    this.maxHp = 100,
    this.shielded = false,
    this.shieldCooldownRemaining = 0,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'a': angle,
        'hp': hp,
        'mhp': maxHp,
        'sh': shielded,
        'shc': shieldCooldownRemaining,
      };

  factory ShipSnapshot.fromJson(Map<String, dynamic> j) => ShipSnapshot(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        angle: (j['a'] as num).toDouble(),
        hp: (j['hp'] as num).toDouble(),
        maxHp: (j['mhp'] as num?)?.toDouble() ?? 100,
        shielded: j['sh'] as bool? ?? false,
        shieldCooldownRemaining: (j['shc'] as num?)?.toDouble() ?? 0,
      );
}

class ProjectileSnapshot {
  final double x;
  final double y;

  const ProjectileSnapshot({required this.x, required this.y});

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory ProjectileSnapshot.fromJson(Map<String, dynamic> j) =>
      ProjectileSnapshot(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
      );
}

class AsteroidSnapshot {
  final double x;
  final double y;
  final double radius;

  const AsteroidSnapshot(
      {required this.x, required this.y, required this.radius});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'r': radius};

  factory AsteroidSnapshot.fromJson(Map<String, dynamic> j) => AsteroidSnapshot(
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        radius: (j['r'] as num).toDouble(),
      );
}

/// A complete, serializable snapshot of the arena at a given [tick].
class BattleSnapshot {
  final int tick;
  final ShipSnapshot attacker;
  final ShipSnapshot defender;
  final List<ProjectileSnapshot> projectiles;
  final List<AsteroidSnapshot> asteroids;
  final bool finished;
  final BattleRole? winner;

  const BattleSnapshot({
    required this.tick,
    required this.attacker,
    required this.defender,
    required this.projectiles,
    required this.asteroids,
    required this.finished,
    required this.winner,
  });

  Map<String, dynamic> toJson() => {
        'tick': tick,
        'att': attacker.toJson(),
        'def': defender.toJson(),
        'proj': projectiles.map((p) => p.toJson()).toList(),
        'ast': asteroids.map((a) => a.toJson()).toList(),
        'fin': finished,
        'win': winner?.name,
      };

  factory BattleSnapshot.fromJson(Map<String, dynamic> j) => BattleSnapshot(
        tick: j['tick'] as int,
        attacker: ShipSnapshot.fromJson(j['att'] as Map<String, dynamic>),
        defender: ShipSnapshot.fromJson(j['def'] as Map<String, dynamic>),
        projectiles: (j['proj'] as List)
            .map((e) => ProjectileSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        asteroids: (j['ast'] as List)
            .map((e) => AsteroidSnapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
        finished: j['fin'] as bool,
        winner: (j['win'] as String?) == null
            ? null
            : BattleRole.values.byName(j['win'] as String),
      );
}

/// Deterministic authoritative simulation of a single battle.
///
/// The same [seed] always produces the same starting asteroid field, so both
/// devices show an identical arena before the first authoritative snapshot
/// arrives.
class BattleSimulation {
  final BattleConfig config;
  final math.Random _rng;

  late final _Ship _attacker;
  late final _Ship _defender;
  final List<_Projectile> _projectiles = [];
  final List<_Asteroid> _asteroids = [];

  int _tick = 0;
  bool _finished = false;
  BattleRole? _winner;

  BattleSimulation({
    required int seed,
    this.config = const BattleConfig(),
    ShipSpec? attackerSpec,
    ShipSpec? defenderSpec,
  }) : _rng = math.Random(seed) {
    final defaultSpec = ShipSpec(
      maxHp: config.shipMaxHp,
      projectileDamage: config.projectileDamage,
      fireCooldown: config.fireCooldown,
    );
    // Ships spawn on opposite sides facing each other.
    _attacker = _Ship(
      spec: attackerSpec ?? defaultSpec,
      x: config.arenaWidth * 0.15,
      y: config.arenaHeight * 0.5,
      angle: 0, // facing right
    );
    _defender = _Ship(
      spec: defenderSpec ?? defaultSpec,
      x: config.arenaWidth * 0.85,
      y: config.arenaHeight * 0.5,
      angle: math.pi, // facing left
    );

    for (int i = 0; i < config.asteroidCount; i++) {
      final radius = config.asteroidMinRadius +
          _rng.nextDouble() *
              (config.asteroidMaxRadius - config.asteroidMinRadius);
      // Spawn in the central band so asteroids don't start on top of a ship.
      final x = config.arenaWidth * (0.3 + _rng.nextDouble() * 0.4);
      final y = config.arenaHeight * (0.1 + _rng.nextDouble() * 0.8);
      final dir = _rng.nextDouble() * math.pi * 2;
      final speed = config.asteroidMinSpeed +
          _rng.nextDouble() *
              (config.asteroidMaxSpeed - config.asteroidMinSpeed);
      _asteroids.add(_Asteroid(
        x: x,
        y: y,
        vx: math.cos(dir) * speed,
        vy: math.sin(dir) * speed,
        radius: radius,
      ));
    }
  }

  int get tick => _tick;
  bool get finished => _finished;

  /// The winning role once [finished] is true, otherwise null.
  BattleRole? get winner => _winner;

  /// Advance the simulation by one fixed timestep.
  void step(BattleInput attackerInput, BattleInput defenderInput) {
    if (_finished) return;
    const dt = kBattleDt;

    _stepShip(_attacker, attackerInput, BattleRole.attacker, dt);
    _stepShip(_defender, defenderInput, BattleRole.defender, dt);
    _stepProjectiles(dt);
    _stepAsteroids(dt);
    _resolveCollisions();

    _tick++;
    _evaluateOutcome();
  }

  void _stepShip(_Ship ship, BattleInput input, BattleRole role, double dt) {
    if (ship.cooldown > 0) ship.cooldown -= dt;
    if (ship.shieldRemaining > 0) ship.shieldRemaining -= dt;
    if (ship.shieldCooldownRemaining > 0) ship.shieldCooldownRemaining -= dt;

    // Shield activation. The cooldown runs from activation, so it is floored
    // to the duration to prevent a permanently shielded ship.
    if (input.shield &&
        !ship.shielded &&
        ship.shieldCooldownRemaining <= 0 &&
        ship.spec.shieldDuration > 0) {
      ship.shieldRemaining = ship.spec.shieldDuration;
      ship.shieldCooldownRemaining =
          math.max(ship.spec.shieldCooldown, ship.spec.shieldDuration);
    }

    // Steering.
    final turn = input.turn.clamp(-1.0, 1.0);
    ship.angle += turn * config.shipTurnRate * dt;

    // Thrust.
    if (input.thrust) {
      ship.vx += math.cos(ship.angle) * config.shipThrust * dt;
      ship.vy += math.sin(ship.angle) * config.shipThrust * dt;
    }

    // Drag (exponential decay toward rest).
    final dragFactor = math.pow(config.shipDrag, dt).toDouble();
    ship.vx *= dragFactor;
    ship.vy *= dragFactor;

    // Clamp to max speed.
    final speed = math.sqrt(ship.vx * ship.vx + ship.vy * ship.vy);
    if (speed > config.shipMaxSpeed) {
      final scale = config.shipMaxSpeed / speed;
      ship.vx *= scale;
      ship.vy *= scale;
    }

    ship.x += ship.vx * dt;
    ship.y += ship.vy * dt;
    _bounceInBounds(ship, config.shipRadius, restitution: 0.4);

    // Firing.
    if (input.fire && ship.cooldown <= 0) {
      ship.cooldown = ship.spec.fireCooldown;
      final dirX = math.cos(ship.angle);
      final dirY = math.sin(ship.angle);
      _projectiles.add(_Projectile(
        x: ship.x + dirX * (config.shipRadius + config.projectileRadius + 1),
        y: ship.y + dirY * (config.shipRadius + config.projectileRadius + 1),
        vx: dirX * config.projectileSpeed + ship.vx,
        vy: dirY * config.projectileSpeed + ship.vy,
        life: config.projectileLife,
        owner: role,
      ));
    }
  }

  void _stepProjectiles(double dt) {
    for (final p in _projectiles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
    }
    _projectiles.removeWhere((p) =>
        p.life <= 0 ||
        p.x < 0 ||
        p.y < 0 ||
        p.x > config.arenaWidth ||
        p.y > config.arenaHeight);
  }

  void _stepAsteroids(double dt) {
    for (final a in _asteroids) {
      a.x += a.vx * dt;
      a.y += a.vy * dt;
      // Asteroids bounce off the arena walls.
      if (a.x - a.radius < 0) {
        a.x = a.radius;
        a.vx = a.vx.abs();
      } else if (a.x + a.radius > config.arenaWidth) {
        a.x = config.arenaWidth - a.radius;
        a.vx = -a.vx.abs();
      }
      if (a.y - a.radius < 0) {
        a.y = a.radius;
        a.vy = a.vy.abs();
      } else if (a.y + a.radius > config.arenaHeight) {
        a.y = config.arenaHeight - a.radius;
        a.vy = -a.vy.abs();
      }
    }
  }

  void _resolveCollisions() {
    // Projectiles vs the opposing ship. An active shield absorbs the hit;
    // otherwise damage is the shooter's, reduced by the target's defense.
    for (final p in _projectiles) {
      final shooter = p.owner == BattleRole.attacker ? _attacker : _defender;
      final target = p.owner == BattleRole.attacker ? _defender : _attacker;
      if (_circlesOverlap(p.x, p.y, config.projectileRadius, target.x,
          target.y, config.shipRadius)) {
        if (!target.shielded) {
          target.hp -= shooter.spec.projectileDamage *
              (1 - target.spec.defenseRating);
        }
        p.life = 0; // consume the projectile
      }
    }
    _projectiles.removeWhere((p) => p.life <= 0);

    // Projectiles vs asteroids (asteroids block shots).
    for (final p in _projectiles) {
      for (final a in _asteroids) {
        if (_circlesOverlap(
            p.x, p.y, config.projectileRadius, a.x, a.y, a.radius)) {
          p.life = 0;
          break;
        }
      }
    }
    _projectiles.removeWhere((p) => p.life <= 0);

    // Ships vs asteroids (damage + knockback).
    for (final ship in [_attacker, _defender]) {
      for (final a in _asteroids) {
        if (_circlesOverlap(
            ship.x, ship.y, config.shipRadius, a.x, a.y, a.radius)) {
          if (!ship.shielded) {
            ship.hp -= config.asteroidDamage * kBattleDt; // continuous contact
          }
          // Push the ship out along the contact normal.
          final nx = ship.x - a.x;
          final ny = ship.y - a.y;
          final len = math.sqrt(nx * nx + ny * ny);
          if (len > 0.0001) {
            ship.vx += (nx / len) * config.asteroidDamage * 6 * kBattleDt;
            ship.vy += (ny / len) * config.asteroidDamage * 6 * kBattleDt;
          }
        }
      }
    }
  }

  void _evaluateOutcome() {
    final attackerDead = _attacker.hp <= 0;
    final defenderDead = _defender.hp <= 0;

    if (attackerDead || defenderDead) {
      _finished = true;
      if (attackerDead && defenderDead) {
        // Mutual destruction favours the defender (the piece holding ground).
        _winner = BattleRole.defender;
      } else {
        _winner = attackerDead ? BattleRole.defender : BattleRole.attacker;
      }
      return;
    }

    if (_tick >= config.maxTicks) {
      // Sudden death: most hp wins, ties favour the defender.
      _finished = true;
      if (_attacker.hp > _defender.hp) {
        _winner = BattleRole.attacker;
      } else {
        _winner = BattleRole.defender;
      }
    }
  }

  void _bounceInBounds(_Ship ship, double radius, {double restitution = 0.5}) {
    if (ship.x - radius < 0) {
      ship.x = radius;
      ship.vx = ship.vx.abs() * restitution;
    } else if (ship.x + radius > config.arenaWidth) {
      ship.x = config.arenaWidth - radius;
      ship.vx = -ship.vx.abs() * restitution;
    }
    if (ship.y - radius < 0) {
      ship.y = radius;
      ship.vy = ship.vy.abs() * restitution;
    } else if (ship.y + radius > config.arenaHeight) {
      ship.y = config.arenaHeight - radius;
      ship.vy = -ship.vy.abs() * restitution;
    }
  }

  bool _circlesOverlap(double ax, double ay, double ar, double bx, double by,
      double br) {
    final dx = ax - bx;
    final dy = ay - by;
    final r = ar + br;
    return dx * dx + dy * dy <= r * r;
  }

  ShipSnapshot _shipSnapshot(_Ship ship) => ShipSnapshot(
        x: ship.x,
        y: ship.y,
        angle: ship.angle,
        hp: ship.hp.clamp(0, ship.spec.maxHp).toDouble(),
        maxHp: ship.spec.maxHp,
        shielded: ship.shielded,
        shieldCooldownRemaining: math.max(0, ship.shieldCooldownRemaining),
      );

  /// Capture the current arena state for rendering / network sync.
  BattleSnapshot snapshot() => BattleSnapshot(
        tick: _tick,
        attacker: _shipSnapshot(_attacker),
        defender: _shipSnapshot(_defender),
        projectiles: _projectiles
            .map((p) => ProjectileSnapshot(x: p.x, y: p.y))
            .toList(),
        asteroids: _asteroids
            .map((a) => AsteroidSnapshot(x: a.x, y: a.y, radius: a.radius))
            .toList(),
        finished: _finished,
        winner: _winner,
      );
}
