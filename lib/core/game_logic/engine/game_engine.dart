import '../board/board_spec.dart';
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

  /// Create a new game with the given players and power field variant,
  /// on [spec]'s board.
  static GameState createGame({
    required String gameId,
    required Player playerWhite,
    required Player playerBlack,
    List<PowerField>? powerFields,
    BoardSpec spec = BoardSpec.classic8,
  }) {
    final pf = powerFields ?? PowerFieldGenerator.generate(gameId, spec: spec);
    return GameState(
      gameId: gameId,
      phase: GamePhase.formation,
      board: BoardState.empty(pf, spec: spec),
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

  /// Resolve a pending battle. [winner] is the color of the winning unit;
  /// null when both units fell together (mutual destruction), which takes
  /// both pieces off the board and earns nothing.
  /// [pendingMove] is the capture move that triggered the battle.
  /// Returns (newState, creditsEarned) — caller tracks resources separately.
  static (GameState, int) resolveBattle(
    GameState state,
    Move pendingMove,
    PlayerColor? winner,
  ) {
    assert(state.phase == GamePhase.battle);

    final attackerColor = pendingMove.piece.color;
    GameState resolved;

    if (winner == null) {
      return (_resolveMutualDestruction(state, pendingMove), 0);
    }
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

  /// Both units fell: the defender is taken as in a won capture and the
  /// attacker leaves its square as in a lost one. The turn passes and the
  /// victory conditions are checked for the attacker, who moved.
  static GameState _resolveMutualDestruction(GameState state, Move move) {
    final captured = move.capturedPiece!;
    var board = state.board
        .setPiece(move.from, null)
        .setPiece(move.to, null);

    var playerWhite = state.playerWhite;
    var playerBlack = state.playerBlack;
    final capturedIsWhite = captured.color == PlayerColor.white;
    if (captured.type == PieceType.king) {
      if (capturedIsWhite) {
        playerWhite = playerWhite.copyWith(hasKing: false);
      } else {
        playerBlack = playerBlack.copyWith(hasKing: false);
      }
    } else if (captured.type == PieceType.queen) {
      if (capturedIsWhite) {
        playerWhite = playerWhite.copyWith(hasQueen: false);
      } else {
        playerBlack = playerBlack.copyWith(hasQueen: false);
      }
    }
    // Like a lost capture, a fallen attacker changes nothing else.
    board = LastWarriorRule.apply(board, captured) ?? board;

    final next = state.copyWith(
      phase: GamePhase.playing,
      board: board,
      playerWhite: playerWhite,
      playerBlack: playerBlack,
      moveHistory: [...state.moveHistory, move],
      moveCount: state.moveCount + 1,
    );
    final victory = VictoryChecker.checkVictory(board, state.currentTurn);
    if (victory != null) {
      return next.copyWith(
        victoryCondition: victory,
        winner: state.currentTurn,
        phase: GamePhase.finished,
      );
    }
    return next.copyWith(currentTurn: state.currentTurn.opposite);
  }

  /// Create a default "chess-like" formation for quick start / testing:
  /// [spec]'s layout on [color]'s rows.
  static Formation defaultFormation(
    PlayerColor color, {
    BoardSpec spec = BoardSpec.classic8,
  }) {
    final placements = <FormationPlacement>[];

    // Classic: back row Rook, Knight, Bishop, Queen, King, Bishop, Knight,
    // Rook, then the pawn row
    for (var i = 0; i < spec.layout.length; i++) {
      final row = color == PlayerColor.white ? i : spec.rows - 1 - i;
      final types = spec.layout[i];
      for (int col = 0; col < types.length; col++) {
        final type = types[col];
        if (type == null) continue;
        placements.add(FormationPlacement(
          position: Position(row: row, col: col),
          piece: Piece(type: type, color: color),
        ));
      }
    }

    return Formation(placements: placements);
  }
}
