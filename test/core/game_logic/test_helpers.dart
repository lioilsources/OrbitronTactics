import 'package:orbitron_tactics/core/game_logic/engine/game_engine.dart';
import 'package:orbitron_tactics/core/game_logic/models/board_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_phase.dart';
import 'package:orbitron_tactics/core/game_logic/models/game_state.dart';
import 'package:orbitron_tactics/core/game_logic/models/piece.dart';
import 'package:orbitron_tactics/core/game_logic/models/player.dart';
import 'package:orbitron_tactics/core/game_logic/models/position.dart';
import 'package:orbitron_tactics/core/game_logic/models/power_field.dart';

/// Creates a board with pieces placed at specific positions.
/// Useful for setting up test scenarios.
BoardState boardWith(
  Map<Position, Piece> pieces, {
  List<PowerField> powerFields = const [],
}) {
  final grid = List.generate(8, (_) => List<Piece?>.generate(8, (_) => null));
  for (final entry in pieces.entries) {
    grid[entry.key.row][entry.key.col] = entry.value;
  }
  return BoardState(grid: grid, powerFields: powerFields);
}

/// Creates a GameState in playing phase with the given board and turn.
GameState gameStateWith({
  required BoardState board,
  PlayerColor currentTurn = PlayerColor.white,
  bool whiteHasKing = true,
  bool whiteHasQueen = true,
  bool blackHasKing = true,
  bool blackHasQueen = true,
}) {
  return GameState(
    gameId: 'test',
    phase: GamePhase.playing,
    board: board,
    currentTurn: currentTurn,
    playerWhite: Player(
      userId: 'white',
      displayName: 'White',
      color: PlayerColor.white,
      hasKing: whiteHasKing,
      hasQueen: whiteHasQueen,
    ),
    playerBlack: Player(
      userId: 'black',
      displayName: 'Black',
      color: PlayerColor.black,
      hasKing: blackHasKing,
      hasQueen: blackHasQueen,
    ),
    moveHistory: const [],
    moveCount: 0,
  );
}

/// Convenience constructors for common pieces.
const whitePawn = Piece(type: PieceType.pawn, color: PlayerColor.white);
const blackPawn = Piece(type: PieceType.pawn, color: PlayerColor.black);
const whiteRook = Piece(type: PieceType.rook, color: PlayerColor.white);
const blackRook = Piece(type: PieceType.rook, color: PlayerColor.black);
const whiteKnight = Piece(type: PieceType.knight, color: PlayerColor.white);
const blackKnight = Piece(type: PieceType.knight, color: PlayerColor.black);
const whiteBishop = Piece(type: PieceType.bishop, color: PlayerColor.white);
const blackBishop = Piece(type: PieceType.bishop, color: PlayerColor.black);
const whiteQueen = Piece(type: PieceType.queen, color: PlayerColor.white);
const blackQueen = Piece(type: PieceType.queen, color: PlayerColor.black);
const whiteKing = Piece(type: PieceType.king, color: PlayerColor.white);
const blackKing = Piece(type: PieceType.king, color: PlayerColor.black);

const whiteLastWarrior = Piece(
    type: PieceType.king, color: PlayerColor.white, isLastWarrior: true);
const blackLastWarrior = Piece(
    type: PieceType.queen, color: PlayerColor.black, isLastWarrior: true);

/// Shorthand for Position.
Position pos(int row, int col) => Position(row: row, col: col);

/// Creates a standard starting game state with default formations.
GameState defaultGameState() {
  final state = GameEngine.createGame(
    gameId: 'test',
    playerWhite: const Player(
      userId: 'white',
      displayName: 'White',
      color: PlayerColor.white,
    ),
    playerBlack: const Player(
      userId: 'black',
      displayName: 'Black',
      color: PlayerColor.black,
    ),
    powerFields: [
      PowerField(position: pos(3, 3)),
      PowerField(position: pos(3, 4)),
      PowerField(position: pos(4, 3)),
      PowerField(position: pos(4, 4)),
      PowerField(position: pos(3, 5)),
    ],
  );

  var withWhite = GameEngine.applyFormation(
    state,
    PlayerColor.white,
    GameEngine.defaultFormation(PlayerColor.white),
  );
  return GameEngine.applyFormation(
    withWhite,
    PlayerColor.black,
    GameEngine.defaultFormation(PlayerColor.black),
  );
}
