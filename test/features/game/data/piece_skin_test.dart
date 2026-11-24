import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/theme/board_theme.dart';
import 'package:orbitron_tactics/core/worlds/world_balance.dart';
import 'package:orbitron_tactics/features/game/data/piece_skin.dart';
import 'package:orbitron_tactics/features/game/presentation/providers/game_state_provider.dart';
import 'package:orbitron_tactics/l10n/app_localizations.dart';

Color _hex(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

void main() {
  group('PieceSkin', () {
    test('Space fights by space, every world of figures by ground', () {
      expect(PieceSkin.classic.balance, WorldBalance.space);
      for (final world in PieceSkin.values.where((w) => !w.isSpace)) {
        expect(world.balance, WorldBalance.ground, reason: world.slug);
      }
      // Rome × Carthage: pawn, knight, rook and king up close; bishop and
      // queen shoot.
      final rome = PieceSkin.romeCarthage.balance;
      expect([
        for (final type in PieceType.values)
          if (rome.statsOf(type).isMelee) type,
      ], unorderedEquals(
          [PieceType.pawn, PieceType.knight, PieceType.rook, PieceType.king]));
    });

    test('the chosen world\'s rules apply on one device only', () {
      expect(GameMode.hotSeat.fightsInChosenWorld, isTrue);
      expect(GameMode.singlePlayer.fightsInChosenWorld, isTrue);
      expect(GameMode.localWifi.fightsInChosenWorld, isFalse);
      expect(GameMode.multiplayer.fightsInChosenWorld, isFalse);
    });

    test('finds every skin by its slug', () {
      for (final skin in PieceSkin.values) {
        expect(PieceSkin.fromSlug(skin.slug), skin);
      }
    });

    test('falls back to classic without a slug or for an unknown one', () {
      expect(PieceSkin.fallback, PieceSkin.classic);
      expect(PieceSkin.fromSlug(null), PieceSkin.classic);
      expect(PieceSkin.fromSlug('no_such_pack'), PieceSkin.classic);
    });

    test('classic keeps the board theme and has no figures', () {
      expect(PieceSkin.classic.isImagePack, isFalse);
      expect(PieceSkin.classic.lightSquare, BoardTheme.lightSquare);
      expect(PieceSkin.classic.darkSquare, BoardTheme.darkSquare);
      expect(PieceSkin.classic.assetFor(PieceType.king, PlayerColor.white),
          isNull);
    });

    final packs = PieceSkin.values.where((skin) => skin.isImagePack);

    test('ships a figure for every piece and color of every pack', () {
      for (final skin in packs) {
        for (final type in PieceType.values) {
          for (final color in PlayerColor.values) {
            final asset = skin.assetFor(type, color)!;
            expect(File(asset).existsSync(), isTrue, reason: asset);
          }
        }
      }
    });

    test('every pack matches its manifest', () {
      for (final skin in packs) {
        final manifest = jsonDecode(
                File('${skin.assetFolder}manifest.json').readAsStringSync())
            as Map<String, dynamic>;
        expect(manifest['id'], skin.slug);
        final board = manifest['board'] as Map<String, dynamic>;
        expect(skin.lightSquare, _hex(board['light'] as String),
            reason: '${skin.slug} light squares');
        expect(skin.darkSquare, _hex(board['dark'] as String),
            reason: '${skin.slug} dark squares');
      }
    });

    test('every pack folder on disk is a skin', () {
      final folders = Directory('assets/pieces')
          .listSync()
          .whereType<Directory>()
          .map((dir) => dir.uri.pathSegments.where((s) => s.isNotEmpty).last);
      expect(folders.toSet(), packs.map((skin) => skin.slug).toSet());
    });

    test('pubspec bundles every pack folder', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final skin in packs) {
        expect(pubspec, contains('- ${skin.assetFolder}'));
      }
    });

    test('every skin and side has a name in every locale', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (final skin in PieceSkin.values) {
          expect(skin.displayName(l10n), isNotEmpty);
          for (final color in PlayerColor.values) {
            expect(skin.sideName(l10n, color), isNotEmpty);
          }
        }
      }
    });
  });
}
