import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';

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

  static List<({IconData icon, String title, List<String> lines})> _content(
          AppLocalizations l10n) =>
      [
        (
          icon: Icons.flag,
          title: l10n.rulesWinTitle,
          lines: [
            l10n.rulesWin1,
            l10n.rulesWin2,
            l10n.rulesWin3,
            l10n.rulesWin4,
          ],
        ),
        (
          icon: Icons.grid_on,
          title: l10n.rulesPiecesTitle,
          lines: [
            l10n.rulesPieces1,
            l10n.rulesPieces2,
            l10n.rulesPieces3,
            l10n.rulesPieces4,
            l10n.rulesPieces5,
          ],
        ),
        (
          icon: Icons.rocket_launch,
          title: l10n.rulesBattleTitle,
          lines: [
            l10n.rulesBattle1,
            l10n.rulesBattle2,
            l10n.rulesBattle3,
            l10n.rulesBattle4,
          ],
        ),
        (
          icon: Icons.gesture,
          title: l10n.rulesFleetTitle,
          lines: [
            l10n.rulesFleet1,
            l10n.rulesFleet2,
            l10n.rulesFleet3,
          ],
        ),
      ];

  static const _pageCount = 4;

  bool get _last => _page == _pageCount - 1;

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
        title: Text(context.l10n.howToPlayTitle,
            style: const TextStyle(
                letterSpacing: 3, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_last)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.skip),
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
                  for (final page in _content(context.l10n))
                    _Page(icon: page.icon, title: page.title, lines: page.lines),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pageCount; i++)
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
                  child: Text(_last ? context.l10n.letsPlay : context.l10n.next),
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
