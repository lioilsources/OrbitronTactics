import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A ship sprite decoded for the arena painter, keyed by asset path. Freed
/// once no battle screen watches it.
final shipSpriteProvider =
    FutureProvider.autoDispose.family<ui.Image, String>((ref, asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  ref.onDispose(frame.image.dispose);
  return frame.image;
});
