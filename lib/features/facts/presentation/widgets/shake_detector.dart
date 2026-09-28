import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Calls [onShake] when the phone is shaken, while [child] is on screen.
///
/// Uses the user accelerometer (gravity already removed), so holding the phone
/// still at any angle reads as zero. A shake is [_peaksNeeded] jolts over
/// [_threshold] inside [_window]: a single bump — setting the phone on a table,
/// a pothole on the bus — must not open a dialog.
///
/// The sensor only runs while the app is in the foreground: listening from the
/// background would cost battery for a gesture nobody can make there.
class ShakeDetector extends StatefulWidget {
  const ShakeDetector({required this.onShake, required this.child, super.key});

  final VoidCallback onShake;
  final Widget child;

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  /// m/s² with gravity removed. A deliberate wrist shake clears 20 easily;
  /// walking with the phone in hand stays well under it.
  static const double _threshold = 17;
  static const int _peaksNeeded = 3;
  static const Duration _window = Duration(milliseconds: 800);

  /// One jolt spans several samples over the threshold; they count once.
  static const Duration _minPeakGap = Duration(milliseconds: 120);

  /// After a shake fires, ignore the tail of the same shake.
  static const Duration _cooldown = Duration(seconds: 2);

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  late final AppLifecycleListener _lifecycle;

  final List<DateTime> _peaks = <DateTime>[];
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _listen();
    _lifecycle = AppLifecycleListener(onResume: _listen, onPause: _stop);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _stop();
    super.dispose();
  }

  void _listen() {
    _subscription ??=
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          _onEvent,
          // A device without an accelerometer simply has no shake gesture.
          onError: (Object _) => _stop(),
          cancelOnError: true,
        );
  }

  void _stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _peaks.clear();
  }

  void _onEvent(UserAccelerometerEvent event) {
    final double force = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (force < _threshold) return;

    final DateTime now = DateTime.now();
    if (now.difference(_lastShake) < _cooldown) return;
    if (_peaks.isNotEmpty && now.difference(_peaks.last) < _minPeakGap) return;

    _peaks
      ..add(now)
      ..removeWhere((DateTime peak) => now.difference(peak) > _window);

    if (_peaks.length >= _peaksNeeded) {
      _peaks.clear();
      _lastShake = now;
      widget.onShake();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
