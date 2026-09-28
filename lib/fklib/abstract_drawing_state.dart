import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui';
import 'drawing_widget.dart';
import 'debug.dart';
import 'line_animation.dart';
import 'painter.dart';
import 'parser.dart';
import 'path_painter_builder.dart';
import 'range.dart';
import 'path_order.dart';

/// Base class for _AnimatedDrawingState and _AnimatedDrawingWithTickerState
abstract class AbstractAnimatedDrawingState extends State<KanjiViewer> {
  AbstractAnimatedDrawingState() {
    this.onFinishAnimation = onFinishAnimationDefault;
  }

  late AnimationController controller;
  CurvedAnimation? curve;
  Curve? animationCurve;
  AnimationRange? range;
  String? assetPath;
  PathOrder? animationOrder;
  late DebugOptions debug;
  int lastPaintedPathIndex = -1;

  List<PathSegment> pathSegments = <PathSegment>[];
  List<Path> sourcePaths = <Path>[];
  List<PathSegment> pathSegmentsToAnimate = <PathSegment>[];
  List<PathSegment> pathSegmentsToPaintAsBackground = <PathSegment>[];

  late VoidCallback onFinishAnimation;
  AnimationController? _listenedController;
  VoidCallback? _controllerListener;

  /// Ensure that callback fires off only once even widget is rebuild.
  bool onFinishEvoked = false;

  void onFinishAnimationDefault() {
    if (this.widget.onFinish != null) {
      this.widget.onFinish?.call();
      if (debug.recordFrames) resetFrame(debug);
    }
  }

  void onFinishFrame(int currentPaintedPathIndex) {
    if (newPathPainted(currentPaintedPathIndex)) {
      evokeOnPaintForNewlyPaintedPaths(currentPaintedPathIndex);
    }
    if (this.controller.status == AnimationStatus.completed) {
      this.onFinishAnimation();
    }
  }

  void evokeOnPaintForNewlyPaintedPaths(int currentPaintedPathIndex) {
    final int paintedPaths = pathSegments[currentPaintedPathIndex].pathIndex -
        lastPaintedPathIndex; //TODO you should iterate over the indices of the sorted path segments not the original ones
    for (int i = lastPaintedPathIndex + 1;
        i <= lastPaintedPathIndex + paintedPaths;
        i++) {
      evokeOnPaintForPath(i);
    }
    lastPaintedPathIndex = currentPaintedPathIndex;
  }

  void evokeOnPaintForPath(int i) {
    //Only evoked in next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && i < sourcePaths.length) {
        widget.onPaint?.call(i, sourcePaths[i]);
      }
    });
  }

  bool newPathPainted(int currentPaintedPathIndex) {
    return this.widget.onPaint != null &&
        currentPaintedPathIndex != -1 &&
        pathSegments[currentPaintedPathIndex].pathIndex - lastPaintedPathIndex >
            0;
  }

  @override
  void didUpdateWidget(KanjiViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (this.animationOrder != this.widget.animationOrder) {
      applyPathOrder();
    }
  }

  @override
  void initState() {
    super.initState();
    updatePathData();
    applyAnimationCurve();
    applyDebugOptions();
  }

  void applyDebugOptions() {
    //If DebugOptions changes a hot restart is needed.
    debug = widget.debug ?? DebugOptions();
  }

  void applyAnimationCurve() {
    if (widget.controller != null && widget.animationCurve != null) {
      this.curve = CurvedAnimation(
          parent: widget.controller!, curve: widget.animationCurve!);
      this.animationCurve = widget.animationCurve;
    }
  }

  //TODO Refactor
  Animation<double> getAnimation() {
    final requestedCurve = widget.animationCurve;
    if (requestedCurve == null) {
      curve?.dispose();
      curve = null;
      animationCurve = null;
      return controller;
    }
    if (curve == null || animationCurve != requestedCurve) {
      curve?.dispose();
      curve = CurvedAnimation(parent: controller, curve: requestedCurve);
      animationCurve = requestedCurve;
    }
    return curve!;
  }

  void applyPathOrder() {
    if (this.pathSegments.isEmpty) return;

    if (checkIfDefaultOrderSortingRequired()) {
      pathSegments.sort(Extractor.getComparator(PathOrders.original));
      animationOrder = PathOrders.original;
      return;
    }
    if (widget.animationOrder != animationOrder) {
      pathSegments.sort(Extractor.getComparator(widget.animationOrder ?? PathOrders.original));
      animationOrder = widget.animationOrder;
    }
  }

  PathPainter? buildUnderlayPainter() {
    if (widget.underlayStrokes != true) return null;
    if (pathSegmentsToAnimate.isEmpty) return null;
    PathPainterBuilder builder = preparePathPainterBuilder();
    builder.setPathSegments(this.pathSegmentsToAnimate);
    builder.setIsUnderlay(true);
    return builder.build();
  }

  PathPainter? buildForegroundPainter() {
    if (pathSegmentsToAnimate.isEmpty) return null;
    PathPainterBuilder builder =
        preparePathPainterBuilder(this.widget.lineAnimation);
    builder.setPathSegments(this.pathSegmentsToAnimate);
    return builder.build();
  }

  PathPainter? buildBackgroundPainter() {
    if (pathSegmentsToPaintAsBackground.isEmpty) return null;
    PathPainterBuilder builder = preparePathPainterBuilder();
    builder.setPathSegments(this.pathSegmentsToPaintAsBackground);
    builder.setIsUnderlay(true);
    return builder.build();
  }

  PathPainterBuilder preparePathPainterBuilder([LineAnimation? lineAnimation]) {
    PathPainterBuilder builder = PathPainterBuilder(lineAnimation);
    builder.setAnimation(getAnimation());
    builder.setCustomDimensions(getCustomDimensions());
    builder.setPaints(this.widget.paints);
    builder.setOnFinishFrame(this.onFinishFrame);
    builder.setScaleToViewport(this.widget.scaleToViewport);
    builder.setDebugOptions(this.debug);
    return builder;
  }

  //TODO refactor to be range not null
  void assignPathSegmentsToPainters() {
    if (this.pathSegments.isEmpty) {
      pathSegmentsToAnimate = <PathSegment>[];
      pathSegmentsToPaintAsBackground = <PathSegment>[];
      return;
    }

    final selectedRange = widget.range;
    if (selectedRange == null) {
      this.pathSegmentsToAnimate = this.pathSegments;
      this.range = null;
      this.pathSegmentsToPaintAsBackground.clear();
      return;
    }

    checkValidRange();
    pathSegmentsToPaintAsBackground = pathSegments
        .where((x) => x.pathIndex < selectedRange.start)
        .toList();
    pathSegmentsToAnimate = pathSegments
        .where((x) => x.pathIndex >= selectedRange.start &&
            x.pathIndex <= selectedRange.end)
        .toList();
    range = selectedRange;
  }

  void checkValidRange() {
    final selectedRange = widget.range!;
    if (selectedRange.end >= sourcePaths.length) {
      throw RangeError.range(selectedRange.end, selectedRange.start,
          sourcePaths.length - 1, 'end');
    }
  }

  // TODO Refactor
  Size? getCustomDimensions() {
    if (widget.height != null || widget.width != null) {
      return Size(
        widget.width ?? 0,
        widget.height ?? 0,
      );
    } else {
      return null;
    }
  }

  Widget createCustomPaint(BuildContext context) {
    updatePathData(); //TODO Refactor - SRP broken (see method name)
    return Stack(
      children: <Widget>[
        CustomPaint(
            painter: buildUnderlayPainter(),
            size: Size.copy(MediaQuery.of(context).size)),
        CustomPaint(
            foregroundPainter: buildForegroundPainter(),
            painter: buildBackgroundPainter(),
            size: Size.copy(MediaQuery.of(context).size))
      ],
    );
  }

  // TODO Refactor
  void addListenersToAnimationController() {
    _removeControllerListener();
    _listenedController = controller;
    _controllerListener = () {
      if (!mounted) return;
      if (debug.recordFrames && controller.status == AnimationStatus.forward) {
        iterateFrame(debug);
      }
      if (controller.status == AnimationStatus.dismissed) {
        lastPaintedPathIndex = -1;
      }
      setState(() {});
    };
    controller.addListener(_controllerListener!);
  }

  void _removeControllerListener() {
    if (_controllerListener != null) {
      _listenedController?.removeListener(_controllerListener!);
    }
  }

  @override
  void dispose() {
    _removeControllerListener();
    curve?.dispose();
    super.dispose();
  }

  void updatePathData() {
    parsePathData();
    applyPathOrder();
    assignPathSegmentsToPainters();
  }

  void parsePathData() {
    SvgParser parser = new SvgParser();
    if (svgAssetProvided()) {
      if (this.widget.assetPath == this.assetPath) return;

      parseFromSvgAsset(parser);
    } else if (pathsProvided()) {
      parseFromPaths(parser);
    } else if (svgStrProvided()) {
      parseFromString(parser);
    }
  }

  void parseFromPaths(SvgParser parser) {
    parser.loadFromPaths(this
        .widget
        .paths); //Path object are parsed completely upon every state change
    sourcePaths = parser.getPaths();
    pathSegments = parser.getPathSegments();
  }

  void parseFromString(SvgParser parser) {
    parser.loadFromString(this
        .widget
        .svgStr); // Path object are parsed completely upon every state change
    sourcePaths = parser.getPaths();
    pathSegments = parser.getPathSegments();
  }

  bool pathsProvided() => this.widget.paths.isNotEmpty;

  bool svgAssetProvided() => this.widget.assetPath.isNotEmpty;

  bool svgStrProvided() => this.widget.svgStr.isNotEmpty;

  void parseFromSvgAsset(SvgParser parser) {
    final requestedPath = widget.assetPath;
    assetPath = requestedPath;
    parser.loadFromFile(requestedPath).then((_) {
      if (!mounted || widget.assetPath != requestedPath) return;
      setState(() {
        sourcePaths = parser.getPaths();
        pathSegments = parser.getPathSegments();
      });
    });
  }

  bool checkIfDefaultOrderSortingRequired() {
    // always keep paths for allAtOnce animation in original path order so we do not sort for the correct PaintOrder later on (which is pretty expensive for AllAtOncePainter)
    final bool defaultSortingWhenNoOrderDefined =
        this.widget.lineAnimation == LineAnimation.allAtOnce &&
            this.animationOrder != PathOrders.original;
    return defaultSortingWhenNoOrderDefined;
  }
}
