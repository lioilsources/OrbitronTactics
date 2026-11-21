import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/telemetry/telemetry.dart';

/// Where product events go. `main()` overrides it with the backend; tests
/// and previews send nothing.
final telemetryProvider = Provider<Telemetry>((ref) => const NoTelemetry());
