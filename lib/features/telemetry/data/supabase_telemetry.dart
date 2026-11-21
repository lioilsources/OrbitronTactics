import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/telemetry/telemetry.dart';

/// Writes events to the `app_events` table (insert-only for signed-in
/// players) and leaves each as a Sentry breadcrumb, so a crash report shows
/// what led up to it.
class SupabaseTelemetry extends Telemetry {
  SupabaseTelemetry(
    this._client, {
    required this.appVersion,
    required this.ensureSignedIn,
  });

  final SupabaseClient _client;
  final String appVersion;

  /// Signs the install in; the table takes rows only from a player.
  final Future<void> Function() ensureSignedIn;

  @override
  void event(String name, [Map<String, Object?> props = const {}]) {
    unawaited(Sentry.addBreadcrumb(
        Breadcrumb(category: 'event', message: name, data: props)));
    unawaited(_send(name, props));
  }

  Future<void> _send(String name, Map<String, Object?> props) async {
    try {
      await ensureSignedIn();
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
