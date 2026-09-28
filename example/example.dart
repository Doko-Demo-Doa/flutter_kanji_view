import 'package:flutter/material.dart';
import 'package:flutter_kanji_view/flutter_kanji_view.dart';

void main() => runApp(const MaterialApp(home: Playground()));

class Playground extends StatefulWidget {
  const Playground({super.key});

  @override
  State<Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground>
    with SingleTickerProviderStateMixin {
  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M25 12 L25 88" stroke="#222222" stroke-width="4"/>
  <path d="M50 8 L50 92" stroke="#222222" stroke-width="4"/>
  <path d="M75 12 L75 88" stroke="#222222" stroke-width="4"/>
</svg>
''';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: KanjiViewer.str(_svg, controller: _controller),
            ),
            FilledButton(
              onPressed: () => _controller.forward(from: 0),
              child: const Text('Redraw'),
            ),
          ],
        ),
      ),
    );
  }
}
