import '../models/piece.dart';
import 'bishop_validator.dart';
import 'king_validator.dart';
import 'knight_validator.dart';
import 'last_warrior_validator.dart';
import 'pawn_validator.dart';
import 'piece_validator.dart';
import 'queen_validator.dart';
import 'rook_validator.dart';

const _validators = <PieceType, PieceValidator>{
  PieceType.pawn: PawnValidator(),
  PieceType.rook: RookValidator(),
  PieceType.knight: KnightValidator(),
  PieceType.bishop: BishopValidator(),
  PieceType.queen: QueenValidator(),
  PieceType.king: KingValidator(),
};

const _lastWarriorValidator = LastWarriorValidator();

/// The movement validator for [piece]. A Last Warrior moves by its own
/// rules, whatever its type.
PieceValidator validatorFor(Piece piece) {
  if (piece.isLastWarrior) return _lastWarriorValidator;
  return _validators[piece.type]!;
}
