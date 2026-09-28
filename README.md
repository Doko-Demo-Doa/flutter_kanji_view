# flutter_kanji_view

![Kanji drawing animation](https://user-images.githubusercontent.com/7723097/74023142-7fd6d680-49d1-11ea-8c35-65adefdc2923.gif)

A Flutter widget for animating the strokes of kanji and other SVG drawings. It can load SVG data from an asset or a string, or draw a list of Flutter `Path` objects.

This package uses sound null safety and requires Flutter 3.41 or later and Dart 3.11 or later.

## Install

Add the package to your app's `pubspec.yaml`:

```yaml
dependencies:
  flutter_kanji_view: ^2.0.0
```

Then fetch the dependency:

```shell
flutter pub get
```

## Load an SVG asset

Download SVG files from the [KanjiVG releases](https://github.com/KanjiVG/kanjivg/releases) and add the files you need to your app. Declaring only the files you use helps keep the app bundle small.

Register each asset in your app's `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/0ff10.svg
```

Then pass its path to `KanjiViewer.svg`:

```dart
KanjiViewer.svg(
  'assets/0ff10.svg',
  run: true,
  duration: const Duration(seconds: 3),
)
```

When using `run` and `duration`, the animation repeats while `run` is `true`. Set `run` to `false` to stop it. Use `onFinish` to stop after one cycle.

## Load an SVG string

Use `KanjiViewer.str` when SVG data comes from an API or another source:

```dart
KanjiViewer.str(
  svgString,
  run: true,
  duration: const Duration(seconds: 3),
)
```

## Control the animation with a controller

Pass an `AnimationController` when you need direct control over the animation. The widget does not own the controller; create and dispose of it in the surrounding `State` object.

```dart
KanjiViewer.str(svgString, controller: controller)
```

See [`example/example.dart`](example/example.dart) for a complete app that plays and redraws an SVG using a controller.

To run the example, change to the `example` directory, fetch dependencies, and select a connected device or desktop target:

```shell
cd example
flutter pub get
flutter run -t example.dart
```

For example, on Windows desktop run `flutter run -d windows -t example.dart` (Windows desktop support and the Visual Studio **Desktop development with C++** workload are required).

## Draw Flutter paths

Pass a non-empty list of `Path` objects to `KanjiViewer.paths`:

```dart
KanjiViewer.paths(
  pathList,
  run: true,
  duration: const Duration(seconds: 3),
)
```

Optionally, provide one `Paint` per path with `paints`. The paint list must have the same length as the path list. See the API documentation for [`KanjiViewer`](https://pub.dev/documentation/flutter_kanji_view/latest/flutter_kanji_view/KanjiViewer-class.html) for animation options, path ordering, and callbacks.

## Convert a character to its Unicode code

`getKanjiUnicode` returns the hexadecimal code point for a single character:

```dart
final code = getKanjiUnicode('\u65B0'); // '065b0'
```
