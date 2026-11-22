import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/telemetry/telemetry.dart';

/// Writes events to the `app_events` table (insert-only for signed-in
/// players) and leaves each as a Sentry breadcrumb, so a crash report shows
/// what led up to it.
///
/// Telemetry never signs anyone in: an install gets its anonymous player
/// only when it first plays online, and until then its events stay
/// breadcrumbs.
class SupabaseTelemetry extends Telemetry {
  SupabaseTelemetry(this._client, {required this.appVersion});

  final SupabaseClient _client;
  final String appVersion;

  @override
  void event(String name, [Map<String, Object?> props = const {}]) {
    unawaited(Sentry.addBreadcrumb(
        Breadcrumb(category: 'event', message: name, data: props)));
    // The table takes rows only from a player.
    if (_client.auth.currentSession == null) return;
    unawaited(_send(name, props));
  }

  Future<void> _send(String name, Map<String, Object?> props) async {
    try {
      await _client.from('app_events').insert({
        'name': name,
        'props': props,
        'app_version': appVersion,
        'platform': defaultTargetPlatform.name,
      });
    } catch (error) {
      // Offline or a backend hiccup: the event is lost, the game goes on.
      debugPrint('telemetry: $name not sent ($error)');
    }
  }
}
