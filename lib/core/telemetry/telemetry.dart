/// Product events: what players do, never who they are.
///
/// Names are short snake_case verbs (`game_started`, `purchase`), props a
/// handful of plain values. Sending must never fail the caller, so every
/// implementation swallows its own errors.
abstract class Telemetry {
  const Telemetry();

  void event(String name, [Map<String, Object?> props = const {}]);
}

/// Sends nothing: tests, and builds without a backend.
class NoTelemetry extends Telemetry {
  const NoTelemetry();

  @override
  void event(String name, [Map<String, Object?> props = const {}]) {}
}

/// Keeps every event in memory, for tests.
class RecordingTelemetry extends Telemetry {
  final events = <({String name, Map<String, Object?> props})>[];

  @override
  void event(String name, [Map<String, Object?> props = const {}]) =>
      events.add((name: name, props: props));

  List<String> get names => [for (final e in events) e.name];
}
