import 'spot.dart';

/// Where a melee strike is at a given battle time.
enum StrikePhase { windup, dash, recover, done }

/// A melee strike in progress. The striker's logical position stays home the
/// whole time; the lunge is only drawn ([lungeAt]).
class StrikeRun {
  final int startedMs;
  final int windupMs;
  final int dashMs;
  final int recoverMs;

  /// Where the enemy was when the strike began — what the wind-up shows.
  final Spot target;

  /// Whether contact has been resolved (hit, block or miss).
  final bool resolved;

  const StrikeRun({
    required this.startedMs,
    required this.windupMs,
    required this.dashMs,
    required this.recoverMs,
    required this.target,
    this.resolved = false,
  });

  int get contactMs => startedMs + windupMs + dashMs;
  int get endMs => contactMs + recoverMs;

  StrikePhase phaseAt(int elapsedMs) {
    if (elapsedMs < startedMs + windupMs) return StrikePhase.windup;
    if (elapsedMs < contactMs) return StrikePhase.dash;
    if (elapsedMs < endMs) return StrikePhase.recover;
    return StrikePhase.done;
  }

  /// The striker ignores steering from the lunge until it is back.
  bool locksHelmAt(int elapsedMs) {
    final phase = phaseAt(elapsedMs);
    return phase == StrikePhase.dash || phase == StrikePhase.recover;
  }

  /// Shots pass through the striker during the lunge.
  bool untouchableAt(int elapsedMs) => phaseAt(elapsedMs) == StrikePhase.dash;

  /// How far out toward [target] the striker is drawn, 0 (home) to 1
  /// (contact).
  double lungeAt(int elapsedMs) => switch (phaseAt(elapsedMs)) {
        StrikePhase.windup || StrikePhase.done => 0,
        StrikePhase.dash => dashMs <= 0
            ? 1
            : (elapsedMs - startedMs - windupMs) / dashMs,
        StrikePhase.recover => recoverMs <= 0
            ? 0
            : 1 - (elapsedMs - contactMs) / recoverMs,
      };

  StrikeRun copyWith({int? recoverMs, bool? resolved}) => StrikeRun(
        startedMs: startedMs,
        windupMs: windupMs,
        dashMs: dashMs,
        recoverMs: recoverMs ?? this.recoverMs,
        target: target,
        resolved: resolved ?? this.resolved,
      );
}
