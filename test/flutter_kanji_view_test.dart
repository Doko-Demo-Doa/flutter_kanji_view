import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kanji_view/flutter_kanji_view.dart';
import 'package:flutter_kanji_view/fklib/parser.dart';

void main() {
  const svg = '''
<svg xmlns="http://www.w3.org/2000/svg">
  <path d="M0 0 L10 0" stroke="#ff0000" stroke-width="2"/>
  <path d="M0 10 L10 10" stroke="#0000ff" stroke-width="3"/>
</svg>
''';

  test('parses SVG paths and replaces stale paths on reload', () {
    final parser = SvgParser()..loadFromString(svg);
    expect(parser.getPaths(), hasLength(2));
    expect(parser.getPathSegments(), hasLength(2));
    expect(parser.getPathSegments().first.color, const Color(0xffff0000));
    expect(parser.getPathSegments().last.strokeWidth, 3);

    parser.loadFromString('<svg><path d="M0 0 L5 5"/></svg>');
    expect(parser.getPaths(), hasLength(1));
    expect(parser.getPathSegments(), hasLength(1));
  });

  testWidgets('renders an SVG string and reports finished paths', (tester) async {
    final painted = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 100,
        height: 100,
        child: KanjiViewer.str(
          svg,
          run: true,
          duration: const Duration(milliseconds: 100),
          onPaint: (index, _) => painted.add(index),
        ),
      ),
    ));
    // The widget starts its animation in a post-frame callback. Pump once so
    // the ticker records its start time before advancing the test clock.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(painted, containsAll([0, 1]));
  });
}
