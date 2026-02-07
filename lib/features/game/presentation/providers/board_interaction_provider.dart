import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/game_logic/models/position.dart';

/// Tracks the selected piece and valid move highlights on the board.
class BoardInteractionState {
  final Position? selectedPosition;
  final List<Position> validMoves;

  const BoardInteractionState({
    this.selectedPosition,
    this.validMoves = const [],
  });

  BoardInteractionState copyWith({
    Position? selectedPosition,
    List<Position>? validMoves,
    bool clearSelection = false,
  }) {
    return BoardInteractionState(
      selectedPosition:
          clearSelection ? null : (selectedPosition ?? this.selectedPosition),
      validMoves: validMoves ?? this.validMoves,
    );
  }
}

class BoardInteractionNotifier extends StateNotifier<BoardInteractionState> {
  BoardInteractionNotifier() : super(const BoardInteractionState());

  void selectPiece(Position position, List<Position> validMoves) {
    state = BoardInteractionState(
      selectedPosition: position,
      validMoves: validMoves,
    );
  }

  void clearSelection() {
    state = const BoardInteractionState();
  }
}

final boardInteractionProvider =
    StateNotifierProvider<BoardInteractionNotifier, BoardInteractionState>(
        (ref) {
  return BoardInteractionNotifier();
});
