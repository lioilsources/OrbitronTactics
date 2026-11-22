/// A set of board cells by [BoardGeometry.indexOf], held in two 64-bit
/// words: boards of up to 128 cells.
class CellSet {
  static const int capacity = 128;

  int _low = 0;
  int _high = 0;

  CellSet();

  void add(int index) {
    assert(index >= 0 && index < capacity, 'cell $index out of range');
    if (index < 64) {
      _low |= 1 << index;
    } else {
      _high |= 1 << (index - 64);
    }
  }

  bool contains(int index) => index < 64
      ? _low & (1 << index) != 0
      : _high & (1 << (index - 64)) != 0;

  bool get isEmpty => _low == 0 && _high == 0;

  void clear() {
    _low = 0;
    _high = 0;
  }
}
