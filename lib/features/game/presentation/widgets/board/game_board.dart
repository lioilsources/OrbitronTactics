import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/game_logic/models/game_phase.dart';
import '../../../../../core/game_logic/models/piece.dart';
import '../../../../../core/game_logic/models/position.dart';
import '../../providers/board_interaction_provider.dart';
import '../../providers/game_state_provider.dart';
import 'board_background_painter.dart';
import 'board_overlay_painter.dart';
import 'piece_renderer.dart';

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

  /// Whether the piece at [row],[col] should be hidden because
  /// it's the destination of the current move animation.
  bool _isAnimatingTo(int row, int col) {
    if (_currentMoveAnim == null) return false;
    return _currentMoveAnim!.to.row == row && _currentMoveAnim!.to.col == col;
  }

  /// Convert logical row to visual row (supports board flip).
  int _visualRow(int logicalRow) => widget.flipBoard ? 7 - logicalRow : logicalRow;

  /// Convert logical col to visual col (supports board flip).
  int _visualCol(int logicalCol) => widget.flipBoard ? 7 - logicalCol : logicalCol;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final interaction = ref.watch(boardInteractionProvider);

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
        final boardSize = constraints.maxWidth;
        final squareSize = boardSize / 8;

        return GestureDetector(
          onTapUp: (details) => _handleTap(
            details.localPosition,
            squareSize,
          ),
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              children: [
                // Layer 1: Board background (squares + power fields with glow)
                AnimatedBuilder(
                  animation: _powerFieldGlowController,
                  builder: (context, _) => CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: BoardBackgroundPainter(
                      powerFields: gameState.board.powerFields,
                      board: gameState.board,
                      glowOpacity: _powerFieldGlow.value,
                      flipBoard: widget.flipBoard,
                    ),
                  ),
                ),

                // Layer 2: Overlay (highlights, valid moves)
                CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: BoardOverlayPainter(
                    selectedPosition: interaction.selectedPosition,
                    validMoves: interaction.validMoves,
                    lastMoveFrom: lastMoveFrom,
                    lastMoveTo: lastMoveTo,
                    board: gameState.board,
                    flipBoard: widget.flipBoard,
                  ),
                ),

                // Layer 3: Static pieces (skip piece being animated to destination)
                for (int row = 0; row < 8; row++)
                  for (int col = 0; col < 8; col++)
                    if (gameState.board.grid[row][col] != null)
                      if (!_isAnimatingTo(row, col))
                        Positioned(
                          left: _visualCol(col) * squareSize + squareSize * 0.075,
                          top: _visualRow(row) * squareSize + squareSize * 0.075,
                          child: PieceRenderer.build(
                            gameState.board.grid[row][col]!,
                            squareSize,
                          ),
                        ),

                // Layer 3.5: Capture ghost (fading out + shrinking)
                if (_currentCaptureAnim != null)
                  AnimatedBuilder(
                    animation: _captureController,
                    builder: (context, _) {
                      final pos = _currentCaptureAnim!.position;
                      return Positioned(
                        left: _visualCol(pos.col) * squareSize + squareSize * 0.075,
                        top: _visualRow(pos.row) * squareSize + squareSize * 0.075,
                        child: Opacity(
                          opacity: _captureOpacity.value,
                          child: Transform.scale(
                            scale: _captureScale.value,
                            child: PieceRenderer.build(
                              _currentCaptureAnim!.piece,
                              squareSize,
                            ),
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
                      final left = lerpDouble(
                        _visualCol(from.col) * squareSize + squareSize * 0.075,
                        _visualCol(to.col) * squareSize + squareSize * 0.075,
                        t,
                      )!;
                      final top = lerpDouble(
                        _visualRow(from.row) * squareSize + squareSize * 0.075,
                        _visualRow(to.row) * squareSize + squareSize * 0.075,
                        t,
                      )!;
                      return Positioned(
                        left: left,
                        top: top,
                        child: PieceRenderer.build(
                          _currentMoveAnim!.piece,
                          squareSize,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset localPosition, double squareSize) {
    // Block input during animation
    if (_moveController.isAnimating) return;

    final rawCol = (localPosition.dx / squareSize).floor().clamp(0, 7);
    final rawRow = (localPosition.dy / squareSize).floor().clamp(0, 7);

    // Convert visual position to logical position (flip if needed)
    final col = widget.flipBoard ? 7 - rawCol : rawCol;
    final row = widget.flipBoard ? 7 - rawRow : rawRow;
    final tappedPos = Position(row: row, col: col);

    final gameState = ref.read(gameStateProvider);
    final interaction = ref.read(boardInteractionProvider);
    final gameNotifier = ref.read(gameStateProvider.notifier);
    final interactionNotifier = ref.read(boardInteractionProvider.notifier);

    if (gameState.phase != GamePhase.playing) return;

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
        final movingPiece = gameState.board.pieceAt(from)!;
        final capturedPiece = gameState.board.pieceAt(tappedPos);

        interactionNotifier.clearSelection();

        // Set up animation data BEFORE executing the move
        setState(() {
          _currentMoveAnim = _MoveAnimationData(
            from: from,
            to: tappedPos,
            piece: movingPiece,
          );
          if (capturedPiece != null) {
            _currentCaptureAnim = _CaptureAnimationData(
              position: tappedPos,
              piece: capturedPiece,
            );
          }
        });

        // Execute the move (state jumps to final position immediately)
        gameNotifier.tryMove(from, tappedPos);

        // Start animations
        _moveController.forward(from: 0.0);
        if (capturedPiece != null) {
          _captureController.forward(from: 0.0);
        }
        return;
      }

      // If tapping another friendly piece, select it instead
      final piece = gameState.board.pieceAt(tappedPos);
      if (piece != null && piece.color == gameState.currentTurn) {
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
    if (piece != null && piece.color == gameState.currentTurn) {
      final validMoves = gameNotifier.getLegalMoves(tappedPos);
      interactionNotifier.selectPiece(tappedPos, validMoves);
    }
  }
}
