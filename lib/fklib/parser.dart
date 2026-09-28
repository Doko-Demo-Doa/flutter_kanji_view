import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart' as xml;
//SVG parsing

/// Parses a minimal subset of a SVG file and extracts all paths segments.
class SvgParser {
  /// Each [PathSegment] represents a continuous Path element of the parent Path
  final List<PathSegment> _pathSegments = <PathSegment>[];
  List<Path> _paths = <Path>[];

  //TODO do proper parsing and support hex-alpa and RGBA
  Color parseColor(String cStr) {
    if (cStr.isEmpty)
      throw UnsupportedError("Empty color field found.");
    if (cStr[0] == '#') {
      return Color(0xff000000 | int.parse(cStr.substring(1), radix: 16));
    } else if (cStr == 'none') {
      return Colors.transparent;
    } else {
      throw UnsupportedError(
          "Only hex color format currently supported. String:  $cStr");
    }
  }

  //Extract segments of each path and create [PathSegment] representation
  void addPathSegments(Path path, int index, double? strokeWidth, Color? color) {
    int firstPathSegmentIndex = this._pathSegments.length;
    int relativeIndex = 0;
    path.computeMetrics().forEach((pp) {
      PathSegment segment = new PathSegment()
        ..path = pp.extractPath(0, pp.length)
        ..length = pp.length
        ..firstSegmentOfPathIndex = firstPathSegmentIndex
        ..pathIndex = index
        ..relativeIndex = relativeIndex;

      if (color != null) segment.color = color;

      if (strokeWidth != null) segment.strokeWidth = strokeWidth;

      this._pathSegments.add(segment);
      relativeIndex++;
    });
  }

  void loadFromString(String svgString) {
    this._pathSegments.clear();
    int index = 0; //number of parsed path elements
    _paths = <Path>[];
    final doc = xml.XmlDocument.parse(svgString);
    // TODO: For now only <path> tags are considered for parsing (add circle, rect, arcs etc.)
    for (final node in doc.findAllElements('path')) {
      final dPath = node.getAttribute('d');
      if (dPath != null) {
        Path path = new Path();
        writeSvgPathDataToPath(dPath, new PathModifier(path));

        Color? color;
        double? strokeWidth;

        //Attributes - [1] css-styling
        final style = node.getAttribute('style');
        if (style != null) {
          //Parse color of stroke
          RegExp exp = new RegExp(r"stroke:([^;]+);");
          Match? match = exp.firstMatch(style);
          if (match != null) {
            color = parseColor(match.group(1)!);
          }
          //Parse stroke-width
          exp = new RegExp(r"stroke-width:([0-9.]+)");
          match = exp.firstMatch(style);
          if (match != null) {
            strokeWidth = double.tryParse(match.group(1)!);
          }
        }

        //Attributes - [2] svg-attributes
        final strokeElement = node.getAttribute('stroke');
        if (strokeElement != null) {
          color = parseColor(strokeElement);
        }

        final strokeWidthElement = node.getAttribute('stroke-width');
        if (strokeWidthElement != null) {
          strokeWidth = double.tryParse(strokeWidthElement);
        }

        this._paths.add(path);
        addPathSegments(path, index, strokeWidth, color);
        index++;
      }
    }
  }

  void loadFromPaths(List<Path> paths) {
    this._pathSegments.clear();
    this._paths = paths;

    int index = 0;
    paths.forEach((p) {
      addPathSegments(p, index, null,
          null); //TODO Apply `paints` already here? not so SOLID[0]
      index++;
    });
  }

  /// Parses Svg from provided asset path
  Future<void> loadFromFile(String file) async {
    this._pathSegments.clear();
    String svgString = await rootBundle.loadString(file);
    loadFromString(svgString);
  }

  /// Returns extracted [PathSegment] elements of parsed Svg
  List<PathSegment> getPathSegments() {
    return this._pathSegments;
  }

  /// Returns extracted [Path] elements of parsed Svg
  List<Path> getPaths() {
    return this._paths;
  }
}

/// Represents a segment of path, as returned by path.computeMetrics() and the associated painting parameters for each Path
class PathSegment {
  PathSegment()
      : path = Path(),
        length = 0.0,
        strokeWidth = 0.0,
        color = Colors.black,
        firstSegmentOfPathIndex = 0,
        relativeIndex = 0,
        pathIndex = 0 {
    //That is fun.
    // List colors = [Colors.red, Colors.green, Colors.yellow];
    // Random random = new Random();
    // color = colors[random.nextInt(3)];
  }

  /// A continuous path/segment
  Path path;
  double strokeWidth;
  Color color;

  /// Length of the segment path
  double length;

  /// Denotes the index of the first segment of the containing path when PathOrder.original
  int firstSegmentOfPathIndex;

  /// Corresponding containing path index
  int pathIndex;

  /// Denotes relative index to  firstSegmentOfPathIndex
  int relativeIndex;
//TODO parse/use those two and consider reducing fields and calculate more on the fly.
  /// If stroke, how to end
// StrokeCap cap;
//PaintingStyle
// PaintingStyle style;
}

/// A [PathProxy] that saves Path command in path
class PathModifier extends PathProxy {
  PathModifier(this.path);

  Path path;

  @override
  void close() {
    path.close();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }
}
