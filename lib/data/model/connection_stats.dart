import 'package:meta/meta.dart';

/// {@template connection_stats}
/// Per-connection network statistics for a single application.
///
/// Tracks throughput, total bandwidth, and roundtrip gap for an
/// individual process routed through the tunnel.
/// {@endtemplate}
@immutable
class ConnectionStats {
  /// Display name of the application.
  final String appName;

  /// Process identifier.
  final int pid;

  /// Current upload throughput in bytes per second.
  final double throughputUp;

  /// Current download throughput in bytes per second.
  final double throughputDown;

  /// Total bytes uploaded this session.
  final int totalBytesUp;

  /// Total bytes downloaded this session.
  final int totalBytesDown;

  /// Time since last data received after sending, in milliseconds.
  /// A high value may indicate the remote server is slow.
  final double roundtripGapMs;

  /// {@macro connection_stats}
  const ConnectionStats({
    required this.appName,
    required this.pid,
    required this.throughputUp,
    required this.throughputDown,
    required this.totalBytesUp,
    required this.totalBytesDown,
    required this.roundtripGapMs,
  });

  @override
  int get hashCode => Object.hash(
    appName,
    pid,
    throughputUp,
    throughputDown,
    totalBytesUp,
    totalBytesDown,
    roundtripGapMs,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConnectionStats &&
        other.appName == appName &&
        other.pid == pid &&
        other.throughputUp == throughputUp &&
        other.throughputDown == throughputDown &&
        other.totalBytesUp == totalBytesUp &&
        other.totalBytesDown == totalBytesDown &&
        other.roundtripGapMs == roundtripGapMs;
  }

  @override
  String toString() =>
      'ConnectionStats('
      'appName: $appName, '
      'pid: $pid, '
      'throughputUp: $throughputUp, '
      'throughputDown: $throughputDown, '
      'totalBytesUp: $totalBytesUp, '
      'totalBytesDown: $totalBytesDown, '
      'roundtripGapMs: $roundtripGapMs'
      ')';
}
