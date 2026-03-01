import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/data/model/connection_stats.dart';

class ConnectionRow extends StatelessWidget {
  final ConnectionStats stats;

  const ConnectionRow({
    required this.stats,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(stats.appName, style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('${stats.pid}', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('${stats.roundtripGapMs.toStringAsFixed(0)} ms', style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatThroughput(stats.throughputUp), style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatThroughput(stats.throughputDown), style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatBytes(stats.totalBytesUp), style: textStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(_formatBytes(stats.totalBytesDown), style: textStyle),
          ),
        ],
      ),
    );
  }

  static String _formatThroughput(double bytesPerSec) {
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
