import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_store.dart';

/// `main()` keeps it on the device; elsewhere everything counts as seen.
final onboardingStoreProvider =
    Provider<OnboardingStore>((ref) => MemoryOnboardingStore());
