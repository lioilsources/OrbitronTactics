import 'package:flutter/material.dart';

/// The rules on four pages: how to win, how pieces move, battles and
/// maneuvers. Shown on the first launch and from the lobby's help button.
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _content = <({IconData icon, String title, List<String> lines})>[
    (
      icon: Icons.flag,
      title: 'Three ways to win',
      lines: [
        'Hold all five power fields at the end of your turn.',
        "Capture both the enemy's King and Queen.",
        "Get a Pawn to the enemy's back rank.",
        'Lose your King or Queen and the other becomes the Last Warrior: '
            'it moves one square in any direction.',
      ],
    ),
    (
      icon: Icons.grid_on,
      title: 'Pieces move their own way',
      lines: [
        'Pawn: sideways and back to move, diagonally forward to move or '
            'capture. Never straight ahead.',
        'Rook: up to 4 squares straight. Bishop: up to 3 diagonally, or '
            'snipe 3 squares straight ahead over anything.',
        'Knight: an L forward or sideways, only a low L back, blocked by a '
            'Rook right in front.',
        'Queen: 4 diagonally, 2 straight. King: 4 straight, 2 diagonally.',
        'Tap a piece to see where it can go. A red ! means it can be taken.',
      ],
    ),
    (
      icon: Icons.rocket_launch,
      title: 'Every capture is a battle',
      lines: [
        'The two pieces become ships and fight it out in the arena. The '
            'winner keeps the square.',
        'Drag across your half to dodge, forward to climb, back to dive.',
        'A shot only hits a ship at about its own altitude, so to hit the '
            'enemy you have to fly where it can hit you.',
        'Raise the shield when fire is coming and you cannot get away.',
      ],
    ),
    (
      icon: Icons.gesture,
      title: 'Maneuvers and your fleet',
      lines: [
        'Draw a gesture on the pad and the ship flies a maneuver on its own. '
            'Each costs energy, which recharges during the battle.',
        'Single player battles earn credits. Spend them in the Comcenter on '
            'upgrades and new maneuvers.',
        'The whole game is free. The store only sells new looks and '
            'maneuver packs.',
      ],
    ),
  ];

  bool get _last => _page == _content.length - 1;

  void _next() {
    if (_last) {
      Navigator.of(context).pop();
    } else {
      _pages.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('HOW TO PLAY',
            style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_last)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('SKIP'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final page in _content)
                    _Page(icon: page.icon, title: page.title, lines: page.lines),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _content.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? Colors.amber : Colors.white24,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_last ? "LET'S PLAY" : 'NEXT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.lines});

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        children: [
          Icon(icon, size: 56, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle, size: 6, color: Colors.amber),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                          color: Colors.grey.shade300, fontSize: 15, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
