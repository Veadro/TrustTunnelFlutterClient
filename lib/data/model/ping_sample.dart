import 'package:meta/meta.dart';

/// {@template ping_sample}
/// A single health-check ping measurement.
///
/// Records the round-trip time of a tunnel health check at a given point
/// in time. Used to populate the scrolling ping timeline chart.
/// {@endtemplate}
@immutable
class PingSample {
  /// When the measurement was taken.
  final DateTime timestamp;

  /// Round-trip time in milliseconds.
  final double rttMs;

  /// {@macro ping_sample}
  const PingSample({
    required this.timestamp,
    required this.rttMs,
  });

  @override
  int get hashCode => Object.hash(timestamp, rttMs);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PingSample &&
        other.timestamp == timestamp &&
        other.rttMs == rttMs;
  }

  @override
  String toString() => 'PingSample(timestamp: $timestamp, rttMs: $rttMs)';
}
