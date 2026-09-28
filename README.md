# flutter_kanji_view

![logo](https://user-images.githubusercontent.com/7723097/74023617-a5181480-49d2-11ea-90c8-76e16efb617b.png)

A Flutter library to draw kanji character with animation.

Requires Flutter 3.41 or newer and Dart 3.11 or newer. The package uses sound null safety.

![kanji_drawing](https://user-images.githubusercontent.com/7723097/74023142-7fd6d680-49d1-11ea-8c35-65adefdc2923.gif)

# Introduction

This library is based on biocarl's [drawing_animation](https://github.com/biocarl/drawing_animation), but with some modifications to display kanji SVG from [KanjiVG](https://kanjivg.tagaini.net/).

Moreover, it exposes a third constructor: `.str`, to display the kanji SVG data downloaded as a string (very handy if you store those SVG on your server).

## 1. Add dependency into your `pubspec.yaml`

```yml
dependencies:
  flutter_kanji_view: ^2.0.0
```

## 2. Provide the assets

(optional, not recommended since it will increase the app bundle a lot. There are over 6000 SVG files in the package):

- Download KanjiVG pack from [here](https://github.com/KanjiVG/kanjivg/releases) , get the zip file.

- Add the path into `yml`:

```yml
assets:
  - assets/0ff10.svg
```

## 3. Use the widget: Same with drawing_animation, you can use it in two ways:

- (Optional) You may want to translate the kanji character to its unicode code counterpart. Just use the `getKanjiUnicode` method provided in this package:

```dart
getKanjiUnicode('新');
```

- Without controller: Set `run` and `duration` to use the built-in animation. It repeats while `run` remains true:

```dart
KanjiViewer.svg(
  "assets/0ff10.svg",
  run: this.run,
  duration: const Duration(seconds: 3),
)
```

- With controller: You will have more control over the widget.

See [the example](example/example.dart) for a complete app with an externally controlled animation and a redraw button. Dispose your `AnimationController` when its owner is removed.

## 4. Advanced usage:

There are 3 mores for drawing SVG, mostly from the source they were from.

*** From SVG asset ***: This might be the most common use.

```dart
KanjiViewer.svg(
  'assets/0ff10.svg',
  run: true,
  duration: const Duration(seconds: 3),
)
```

*** From SVG string ***

This can be convenient when you store your SVG data somewhere on the remote server, and retrieve via API:

```dart
KanjiViewer.str(
  svgString,
  run: true,
  duration: const Duration(seconds: 3),
)
```

*** From Path data ***

```dart
// Of the List<Path>
KanjiViewer.paths(
  pathList,
  run: true,
  duration: const Duration(seconds: 3),
)
```

You can use some methods in SVGHelper class (such as `getCoordinatesGroup` and `buildPath`) for Path parsing. I'm not going to document it any time soon because of lacking time though.

TODO:

Since the core library borrows a lot from drawing_animation, their TODOs are also considered this lib's TODOs. This lib, however, add some more priority tasks that I can foresee:

- Expose `Paint` object so users can customize the stroke color / width.
- Expose a `colorSeed` array for distinct strokes. It should be a `List` of `Color` object.
