import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/game_logic/models/game_phase.dart';
import '../../../../../core/game_logic/models/game_state.dart';
import '../../../../../core/game_logic/models/move.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../../../../core/game_logic/services/threat_analyzer.dart';
import '../../providers/board_interaction_provider.dart';
import '../../providers/game_state_provider.dart';
import '../../providers/piece_skin_provider.dart';
import 'board_background_painter.dart';
import 'board_layout.dart';
import 'board_overlay_painter.dart';
import 'piece_renderer.dart';
import 'tap_resolver.dart';

/// Ephemeral data for a piece-move animation.
class _MoveAnimationData {
  final Position from;
  final Position to;
  final Piece piece;
  _MoveAnimationData({required this.from, required this.to, required this.piece});
}

/// Ephemeral data for a capture-ghost animation.
class _CaptureAnimationData {
  final Position position;
  final Piece piece;
  _CaptureAnimationData({required this.position, required this.piece});
}

/// The main interactive game board widget.
/// Composes background painter, piece layer, overlay painter, and gesture handling.
class GameBoard extends ConsumerStatefulWidget {
  final bool flipBoard;

  const GameBoard({super.key, this.flipBoard = false});

  @override
  ConsumerState<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends ConsumerState<GameBoard>
    with TickerProviderStateMixin {
  // Move animation (piece slides from A to B)
  late final AnimationController _moveController;
  late final Animation<double> _moveAnimation;

  // Capture ghost animation (captured piece fades out + shrinks)
  late final AnimationController _captureController;
  late final Animation<double> _captureOpacity;
  late final Animation<double> _captureScale;

  // Power field glow (pulsing opacity)
  late final AnimationController _powerFieldGlowController;
  late final Animation<double> _powerFieldGlow;

  // Current animation state (null when idle)
  _MoveAnimationData? _currentMoveAnim;
  _CaptureAnimationData? _currentCaptureAnim;

  /// The move animated from a tap on this board; its state change must not
  /// be animated a second time by [_onGameStateChanged].
  ({Position from, Position to})? _locallyAnimated;

  @override
  void initState() {
    super.initState();

    // Move: 200ms ease-in-out slide
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    );
    _moveController.addStatusListener(_onMoveAnimDone);

    // Capture ghost: 300ms fade-out + shrink
    _captureController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _captureOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _captureController, curve: Curves.easeOut),
    );
    _captureScale = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _captureController, curve: Curves.easeIn),
    );
    _captureController.addStatusListener(_onCaptureAnimDone);

    // Power field glow: repeating pulse
    _powerFieldGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _powerFieldGlow = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _powerFieldGlowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _captureController.dispose();
    _powerFieldGlowController.dispose();
    super.dispose();
  }

  void _onMoveAnimDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _locallyAnimated = null;
      setState(() {
        _currentMoveAnim = null;
      });
    }
  }

  void _onCaptureAnimDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _currentCaptureAnim = null;
      });
      _captureController.reset();
    }
  }

  /// Animates moves that did not start with a tap on this board: the AI's
  /// moves and remote moves.
  void _onGameStateChanged(GameState? prev, GameState next) {
    if (prev == null) return;

    final Move? move;
    if (next.phase == GamePhase.battle && prev.phase != GamePhase.battle) {
      // A capture reaches the move history only after its battle; play the
      // approach now, as the arena opens.
      move = ref.read(gameStateProvider.notifier).pendingBattleMove;
    } else if (next.moveHistory.length > prev.moveHistory.length &&
        prev.phase != GamePhase.battle) {
      // History growing out of a battle is its resolution — the approach
      // was already animated when the battle started.
      move = next.moveHistory.last;
    } else {
      return;
    }
    if (move == null) return;

    final local = _locallyAnimated;
    if (local != null && local.from == move.from && local.to == move.to) {
      _locallyAnimated = null;
      return;
    }
    _animateMove(move);
  }

  /// Slides the moving piece to its target and fades out a captured piece.
  void _animateMove(Move move) {
    final captured = move.capturedPiece;
    setState(() {
      _currentMoveAnim = _MoveAnimationData(
        from: move.from,
        to: move.to,
        piece: move.piece,
      );
      if (captured != null) {
        _currentCaptureAnim = _CaptureAnimationData(
          position: move.to,
          piece: captured,
        );
      }
    });
    _moveController.forward(from: 0.0);
    if (captured != null) {
      _captureController.forward(from: 0.0);
    }
  }

  /// Whether the piece at [p] should be hidden because it's the
  /// destination of the current move animation.
  bool _isAnimatingTo(Position p) => _currentMoveAnim?.to == p;

  /// Top left of the piece drawn on [p]. A flat board insets the piece in
  /// its cell; a standing figure fills its whole [BoardLayout.pieceBox].
  Offset _pieceOrigin(BoardLayout layout, Position p) => layout.standing
      ? layout.pieceBox(p).topLeft
      : layout.pieceBox(p).topLeft +
          Offset(layout.cellSize * 0.075, layout.cellSize * 0.075);

  /// [piece] as drawn on [layout]'s cells.
  Widget _piece(
    BoardLayout layout,
    Piece piece,
    PieceSkinSettings look, {
    bool isThreatened = false,
  }) =>
      PieceRenderer.build(
        piece,
        layout.cellSize,
        isThreatened: isThreatened,
        skin: look.skin,
        classicMarks: look.classicMarks,
        figureHeight:
            layout.standing ? layout.tilt!.figureHeight * layout.cellSize : null,
      );

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final interaction = ref.watch(boardInteractionProvider);
    final look = ref.watch(pieceSkinProvider);
    ref.listen<GameState>(gameStateProvider, _onGameStateChanged);

    // Compute threatened positions (only during playing phase)
    final threatenedPositions = gameState.phase == GamePhase.playing
        ? ThreatAnalyzer.getThreatenedPositions(
            gameState.board, gameState.currentTurn)
        : <Position>{};

    // Get last move for highlighting
    Position? lastMoveFrom;
    Position? lastMoveTo;
    if (gameState.moveHistory.isNotEmpty) {
      final lastMove = gameState.moveHistory.last;
      lastMoveFrom = lastMove.from;
      lastMoveTo = lastMove.to;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tilt = boardTiltFor(gameState.board.spec, look.skin);
        final layout = BoardLayout.within(
          gameState.board.geometry,
          constraints.biggest,
          flipped: widget.flipBoard,
          tilt: tilt,
        );
        final boardSize = layout.size;
        // Back to front, so a standing figure overlaps the ones behind it.
        final occupied = layout.inDrawOrder([
          for (final cell in gameState.board.geometry.cells)
            if (gameState.board.pieceAt(cell) != null && !_isAnimatingTo(cell))
              cell,
        ]);

        return Center(
          child: GestureDetector(
          onTapUp: (details) => _handleTap(details.localPosition, layout),
          child: SizedBox(
            width: boardSize.width,
            height: boardSize.height,
            child: Stack(
              children: [
                // Layer 1: Board background (squares + power fields with glow)
                AnimatedBuilder(
                  animation: _powerFieldGlowController,
                  builder: (context, _) => CustomPaint(
                    size: boardSize,
                    painter: BoardBackgroundPainter(
                      powerFields: gameState.board.powerFields,
                      board: gameState.board,
                      glowOpacity: _powerFieldGlow.value,
                      flipBoard: widget.flipBoard,
                      tilt: tilt,
                      lightSquare: look.skin.lightSquare,
                      darkSquare: look.skin.darkSquare,
                    ),
                  ),
                ),

                // Layer 2: Overlay (highlights, valid moves)
                CustomPaint(
                  size: boardSize,
                  painter: BoardOverlayPainter(
                    selectedPosition: interaction.selectedPosition,
                    validMoves: interaction.validMoves,
                    lastMoveFrom: lastMoveFrom,
                    lastMoveTo: lastMoveTo,
                    board: gameState.board,
                    flipBoard: widget.flipBoard,
                    tilt: tilt,
                  ),
                ),

                // Layer 3: Static pieces (skip piece being animated to destination)
                for (final cell in occupied)
                  Positioned(
                    key: ValueKey(('piece', cell)),
                    left: _pieceOrigin(layout, cell).dx,
                    top: _pieceOrigin(layout, cell).dy,
                    child: _piece(
                      layout,
                      gameState.board.pieceAt(cell)!,
                      look,
                      isThreatened: threatenedPositions.contains(cell),
                    ),
                  ),

                // Layer 3.5: Capture ghost (fading out + shrinking)
                if (_currentCaptureAnim != null)
                  AnimatedBuilder(
                    animation: _captureController,
                    builder: (context, _) {
                      final pos = _currentCaptureAnim!.position;
                      return Positioned(
                        left: _pieceOrigin(layout, pos).dx,
                        top: _pieceOrigin(layout, pos).dy,
                        child: Opacity(
                          opacity: _captureOpacity.value,
                          child: Transform.scale(
                            scale: _captureScale.value,
                            child: _piece(
                                layout, _currentCaptureAnim!.piece, look),
                          ),
                        ),
                      );
                    },
                  ),

                // Layer 4: Animated moving piece (slides from → to)
                if (_currentMoveAnim != null)
                  AnimatedBuilder(
                    animation: _moveAnimation,
                    builder: (context, _) {
                      final from = _currentMoveAnim!.from;
                      final to = _currentMoveAnim!.to;
                      final t = _moveAnimation.value;
                      final origin = Offset.lerp(
                        _pieceOrigin(layout, from),
                        _pieceOrigin(layout, to),
                        t,
                      )!;
                      return Positioned(
                        left: origin.dx,
                        top: origin.dy,
                        child: _piece(layout, _currentMoveAnim!.piece, look),
                      );
                    },
                  ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  /// Whether the given piece can be selected by the local player.
  /// In hot-seat mode, the current turn player can select their pieces.
  /// With a local color (multiplayer, single player), only the local
  /// player's pieces can be selected on their turn.
  bool _canSelectPiece(Piece piece, GameStateNotifier notifier) {
    final localColor = notifier.localColor;
    if (localColor != null) {
      // Multiplayer: only select own pieces, and only on own turn
      return piece.color == localColor;
    }
    // Hot-seat: select current turn player's pieces
    return piece.color == ref.read(gameStateProvider).currentTurn;
  }

  /// The standing figures a tap on their head may pick, for [resolveTap]:
  /// every piece on a [preferred] cell and every own piece.
  Map<Position, PieceType> _tapHeads(
    GameState gameState,
    Set<Position> preferred,
    GameStateNotifier notifier,
  ) =>
      {
        for (final cell in gameState.board.geometry.cells)
          if (gameState.board.pieceAt(cell) case final piece?)
            if (preferred.contains(cell) || _canSelectPiece(piece, notifier))
              cell: piece.type,
      };

  /// The cells where a tap does something, for [resolveTap]: with a
  /// selection its move targets and the selected cell, and always the own
  /// pieces that have a move.
  Set<Position> _tapTargets(
    GameState gameState,
    BoardInteractionState interaction,
    GameStateNotifier notifier,
  ) {
    final targets = <Position>{};
    final selected = interaction.selectedPosition;
    if (selected != null) {
      targets
        ..add(selected)
        ..addAll(interaction.validMoves);
    }
    for (final cell in gameState.board.geometry.cells) {
      final piece = gameState.board.pieceAt(cell);
      if (piece != null &&
          _canSelectPiece(piece, notifier) &&
          notifier.getLegalMoves(cell).isNotEmpty) {
        targets.add(cell);
      }
    }
    return targets;
  }

  void _handleTap(Offset localPosition, BoardLayout layout) {
    // Block input during animation
    if (_moveController.isAnimating) return;

    final gameState = ref.read(gameStateProvider);
    final interaction = ref.read(boardInteractionProvider);
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final interactionNotifier = ref.read(boardInteractionProvider.notifier);

    final reach = tapReachFor(layout);
    final Position? tappedPos;
    if ((reach > 0 || layout.standing) &&
        gameState.phase == GamePhase.playing) {
      final preferred = _tapTargets(gameState, interaction, gameNotifier);
      tappedPos = resolveTap(layout, localPosition,
          preferred: preferred,
          heads: layout.standing
              ? _tapHeads(gameState, preferred, gameNotifier)
              : const {},
          reach: reach);
    } else {
      tappedPos = layout.positionAt(localPosition);
    }
    if (tappedPos == null) return;

    if (gameState.phase != GamePhase.playing) return;

    // With a local color (multiplayer, single player), block input when
    // it's not our turn
    if (gameNotifier.localColor != null &&
        gameState.currentTurn != gameNotifier.localColor) {
      interactionNotifier.clearSelection();
      return;
    }

    // If a piece is already selected
    if (interaction.selectedPosition != null) {
      // If tapping the same piece, deselect
      if (interaction.selectedPosition == tappedPos) {
        interactionNotifier.clearSelection();
        return;
      }

      // If tapping a valid move target, animate then make the move
      if (interaction.validMoves.contains(tappedPos)) {
        final from = interaction.selectedPosition!;
        final move = Move(
          from: from,
          to: tappedPos,
          piece: gameState.board.pieceAt(from)!,
          capturedPiece: gameState.board.pieceAt(tappedPos),
        );

        interactionNotifier.clearSelection();

        // Start the animation BEFORE executing the move
        // (state jumps to the final position immediately)
        _locallyAnimated = (from: from, to: tappedPos);
        _animateMove(move);
        gameNotifier.tryMove(from, tappedPos);
        return;
      }

      // If tapping another friendly piece, select it instead
      final piece = gameState.board.pieceAt(tappedPos);
      if (piece != null && _canSelectPiece(piece, gameNotifier)) {
        final validMoves = gameNotifier.getLegalMoves(tappedPos);
        interactionNotifier.selectPiece(tappedPos, validMoves);
        return;
      }

      // Tapping empty/enemy square that's not a valid move — deselect
      interactionNotifier.clearSelection();
      return;
    }

    // No piece selected — try to select one
    final piece = gameState.board.pieceAt(tappedPos);
    if (piece != null && _canSelectPiece(piece, gameNotifier)) {
      final validMoves = gameNotifier.getLegalMoves(tappedPos);
      interactionNotifier.selectPiece(tappedPos, validMoves);
    }
  }
}
