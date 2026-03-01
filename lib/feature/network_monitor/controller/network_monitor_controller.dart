import 'dart:async';
import 'dart:math';

import 'package:trusttunnel/common/controller/concurrency/sequential_controller_handler.dart';
import 'package:trusttunnel/common/controller/controller/state_controller.dart';
import 'package:trusttunnel/data/model/connection_stats.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';
import 'package:trusttunnel/feature/network_monitor/controller/network_monitor_states.dart';

/// {@template network_monitor_controller}
/// Controller that generates mock network stats and ping samples.
///
/// In the future this will be replaced with real data from the native layer.
/// {@endtemplate}
final class NetworkMonitorController extends BaseStateController<NetworkMonitorState>
    with SequentialControllerHandler {
  static const _maxPingSamples = 60;
  static const _statsIntervalMs = 1000;
  static const _pingIntervalMs = 1000;

  Timer? _statsTimer;
  Timer? _pingTimer;
  final Random _random = Random();

  /// {@macro network_monitor_controller}
  NetworkMonitorController({
    super.initialState = const NetworkMonitorState.initial(),
  });

  /// Start generating mock data.
  Future<void> startMonitoring() => handle(() {
    setState(
      NetworkMonitorState.loading(
        connections: state.connections,
        pingSamples: state.pingSamples,
        sortField: state.sortField,
        sortAscending: state.sortAscending,
      ),
    );

    _statsTimer?.cancel();
    _pingTimer?.cancel();

    _statsTimer = Timer.periodic(
      const Duration(milliseconds: _statsIntervalMs),
      (_) => _updateStats(),
    );

    _pingTimer = Timer.periodic(
      const Duration(milliseconds: _pingIntervalMs),
      (_) => _addPingSample(),
    );

    // Generate initial data immediately.
    _updateStats();
    _addPingSample();
  });

  /// Stop generating mock data.
  Future<void> stopMonitoring() => handle(() {
    _statsTimer?.cancel();
    _pingTimer?.cancel();
    _statsTimer = null;
    _pingTimer = null;

    setState(
      NetworkMonitorState.idle(
        connections: state.connections,
        pingSamples: state.pingSamples,
        sortField: state.sortField,
        sortAscending: state.sortAscending,
      ),
    );
  });

  /// Change which column the connection list is sorted by.
  Future<void> changeSort(NetworkMonitorSortField field) => handle(() {
    final ascending = state.sortField == field ? !state.sortAscending : true;

    setState(
      NetworkMonitorState.idle(
        connections: _sortedConnections(state.connections, field, ascending),
        pingSamples: state.pingSamples,
        sortField: field,
        sortAscending: ascending,
      ),
    );
  });

  void _updateStats() {
    if (isDisposed) return;

    final connections = _generateMockConnections();
    final sorted = _sortedConnections(connections, state.sortField, state.sortAscending);

    setState(
      NetworkMonitorState.idle(
        connections: sorted,
        pingSamples: state.pingSamples,
        sortField: state.sortField,
        sortAscending: state.sortAscending,
      ),
    );
  }

  void _addPingSample() {
    if (isDisposed) return;

    final sample = PingSample(
      timestamp: DateTime.now(),
      rttMs: 15.0 + _random.nextDouble() * 45.0, // 15–60ms
    );

    final samples = [...state.pingSamples, sample];
    final trimmed = samples.length > _maxPingSamples
        ? samples.sublist(samples.length - _maxPingSamples)
        : samples;

    setState(
      NetworkMonitorState.idle(
        connections: state.connections,
        pingSamples: trimmed,
        sortField: state.sortField,
        sortAscending: state.sortAscending,
      ),
    );
  }

  List<ConnectionStats> _generateMockConnections() {
    const apps = [
      ('Chrome', 1234),
      ('Slack', 2345),
      ('VS Code', 3456),
      ('Spotify', 4567),
      ('Discord', 5678),
      ('Firefox', 6789),
      ('Teams', 7890),
    ];

    return apps.map((app) => ConnectionStats(
      appName: app.$1,
      pid: app.$2,
      throughputUp: _random.nextDouble() * 500000,   // 0–500 KB/s
      throughputDown: _random.nextDouble() * 2000000, // 0–2 MB/s
      totalBytesUp: (_random.nextDouble() * 50000000).toInt(),
      totalBytesDown: (_random.nextDouble() * 200000000).toInt(),
      roundtripGapMs: 5.0 + _random.nextDouble() * 200.0,
    )).toList();
  }

  List<ConnectionStats> _sortedConnections(
    List<ConnectionStats> connections,
    NetworkMonitorSortField field,
    bool ascending,
  ) {
    final sorted = [...connections]..sort((a, b) {
      final cmp = switch (field) {
        NetworkMonitorSortField.appName => a.appName.compareTo(b.appName),
        NetworkMonitorSortField.pid => a.pid.compareTo(b.pid),
        NetworkMonitorSortField.roundtripGap => a.roundtripGapMs.compareTo(b.roundtripGapMs),
        NetworkMonitorSortField.throughputUp => a.throughputUp.compareTo(b.throughputUp),
        NetworkMonitorSortField.throughputDown => a.throughputDown.compareTo(b.throughputDown),
        NetworkMonitorSortField.totalUp => a.totalBytesUp.compareTo(b.totalBytesUp),
        NetworkMonitorSortField.totalDown => a.totalBytesDown.compareTo(b.totalBytesDown),
      };
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }
}
