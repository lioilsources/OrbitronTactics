import '../models/board_state.dart';
import '../models/game_phase.dart';
import '../models/game_state.dart';
import '../models/move.dart';
import '../models/piece.dart';
import '../models/player.dart';
import '../models/position.dart';
import '../models/power_field.dart';
import '../models/formation.dart';
import '../validators/move_validator.dart';
import 'last_warrior_rule.dart';
import 'power_field_generator.dart';
import 'upgrade_engine.dart';
import 'victory_checker.dart';

/// The core game engine. All methods are pure functions:
/// (GameState, action) -> GameState
class GameEngine {
  const GameEngine._();

  /// Create a new game with the given players and power field variant.
  static GameState createGame({
    required String gameId,
    required Player playerWhite,
    required Player playerBlack,
    List<PowerField>? powerFields,
  }) {
    final pf = powerFields ?? PowerFieldGenerator.generate(gameId);
    return GameState(
      gameId: gameId,
      phase: GamePhase.formation,
      board: BoardState.empty(pf),
      currentTurn: PlayerColor.white,
      playerWhite: playerWhite,
      playerBlack: playerBlack,
      moveHistory: const [],
      moveCount: 0,
    );
  }

  /// Apply a formation to the board. When both players have locked their
  /// formations, the game transitions to playing phase.
  static GameState applyFormation(
    GameState state,
    PlayerColor color,
    Formation formation,
  ) {
    // Place pieces on the board
    var board = state.board;
    for (final placement in formation.placements) {
      board = board.setPiece(placement.position, placement.piece);
    }

    // Update player's formation lock status
    final updatedState = state.copyWith(
      board: board,
      playerWhite: color == PlayerColor.white
          ? state.playerWhite.copyWith(
              formation: formation,
              formationLocked: true,
            )
          : state.playerWhite,
      playerBlack: color == PlayerColor.black
          ? state.playerBlack.copyWith(
              formation: formation,
              formationLocked: true,
            )
          : state.playerBlack,
    );

    // If both formations are locked, start the game
    if (updatedState.playerWhite.formationLocked &&
        updatedState.playerBlack.formationLocked) {
      return updatedState.copyWith(phase: GamePhase.playing);
    }

    return updatedState;
  }

  /// Apply a validated move to the game state.
  /// When [triggerBattle] is true and a capture occurs, transitions to
  /// GamePhase.battle — caller is responsible for managing the battle.
  static GameState applyMove(
    GameState state,
    Move move, {
    bool triggerBattle = false,
  }) {
    // In localWifi mode, captures pause the board game; battle resolves it.
    if (triggerBattle && move.capturedPiece != null) {
      return state.copyWith(phase: GamePhase.battle);
    }

    var board = state.board;

    // 1. Move the piece
    board = board.movePiece(move.from, move.to);

    // 2. Handle capture — apply Last Warrior rule if royal captured
    var playerWhite = state.playerWhite;
    var playerBlack = state.playerBlack;

    if (move.capturedPiece != null) {
      final captured = move.capturedPiece!;
      final capturedColor = captured.color;

      // Update player's royal tracking
      if (captured.type == PieceType.king) {
        if (capturedColor == PlayerColor.white) {
          playerWhite = playerWhite.copyWith(hasKing: false);
        } else {
          playerBlack = playerBlack.copyWith(hasKing: false);
        }
      } else if (captured.type == PieceType.queen) {
        if (capturedColor == PlayerColor.white) {
          playerWhite = playerWhite.copyWith(hasQueen: false);
        } else {
          playerBlack = playerBlack.copyWith(hasQueen: false);
        }
      }

      // Apply Last Warrior transformation
      final transformedBoard = LastWarriorRule.apply(board, captured);
      if (transformedBoard != null) {
        board = transformedBoard;
      }
    }

    // 3. Check victory conditions
    final victory =
        VictoryChecker.checkVictory(board, state.currentTurn);

    // 4. Build new state
    final newMoveHistory = [...state.moveHistory, move];

    if (victory != null) {
      return state.copyWith(
        board: board,
        playerWhite: playerWhite,
        playerBlack: playerBlack,
        moveHistory: newMoveHistory,
        moveCount: state.moveCount + 1,
        victoryCondition: victory,
        winner: state.currentTurn,
        phase: GamePhase.finished,
      );
    }

    // 5. Switch turn
    return state.copyWith(
      board: board,
      playerWhite: playerWhite,
      playerBlack: playerBlack,
      currentTurn: state.currentTurn.opposite,
      moveHistory: newMoveHistory,
      moveCount: state.moveCount + 1,
    );
  }

  /// Convenience: validate and apply a move in one step.
  /// Returns null if the move is illegal.
  static GameState? tryMove(
    GameState state,
    Position from,
    Position to, {
    bool triggerBattle = false,
  }) {
    final move = MoveValidator.createMove(state, from, to);
    if (move == null) return null;
    return applyMove(state, move, triggerBattle: triggerBattle);
  }

  /// Resolve a pending battle. [winner] is the color of the winning unit.
  /// [pendingMove] is the capture move that triggered the battle.
  /// Returns (newState, creditsEarned) — caller tracks resources separately.
  static (GameState, int) resolveBattle(
    GameState state,
    Move pendingMove,
    PlayerColor winner,
  ) {
    assert(state.phase == GamePhase.battle);

    final attackerColor = pendingMove.piece.color;
    GameState resolved;

    if (winner == attackerColor) {
      // Attacker wins: apply the capture move normally
      resolved = applyMove(state.copyWith(phase: GamePhase.playing), pendingMove);
    } else {
      // Defender wins: remove the attacker from the board
      final board = state.board.setPiece(pendingMove.from, null);
      resolved = state.copyWith(
        phase: GamePhase.playing,
        board: board,
        currentTurn: state.currentTurn.opposite,
        moveHistory: [...state.moveHistory, pendingMove],
        moveCount: state.moveCount + 1,
      );
    }

    final loserPiece = winner == attackerColor ? pendingMove.capturedPiece! : pendingMove.piece;
    final reward = UpgradeEngine.resourcesFor(loserPiece.type);
    return (resolved, reward);
  }

  /// Create a default "chess-like" formation for quick start / testing.
  static Formation defaultFormation(PlayerColor color) {
    final backRow = color == PlayerColor.white ? 0 : 7;
    final pawnRow = color == PlayerColor.white ? 1 : 6;

    final placements = <FormationPlacement>[];

    // Back row: Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook
    const backRowPieces = [
      PieceType.rook,
      PieceType.knight,
      PieceType.bishop,
      PieceType.queen,
      PieceType.king,
      PieceType.bishop,
      PieceType.knight,
      PieceType.rook,
    ];

    for (int col = 0; col < 8; col++) {
      placements.add(FormationPlacement(
        position: Position(row: backRow, col: col),
        piece: Piece(type: backRowPieces[col], color: color),
      ));
    }

    // Pawn row
    for (int col = 0; col < 8; col++) {
      placements.add(FormationPlacement(
        position: Position(row: pawnRow, col: col),
        piece: Piece(type: PieceType.pawn, color: color),
      ));
    }

    return Formation(placements: placements);
  }
}
