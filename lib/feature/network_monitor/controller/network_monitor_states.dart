import 'package:trusttunnel/data/model/connection_stats.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';

/// {@template network_monitor_state}
/// State representation for the network monitor feature.
/// {@endtemplate}
sealed class NetworkMonitorState {
  final List<ConnectionStats> connections;
  final List<PingSample> pingSamples;
  final NetworkMonitorSortField sortField;
  final bool sortAscending;

  const NetworkMonitorState._({
    required this.connections,
    required this.pingSamples,
    required this.sortField,
    required this.sortAscending,
  });

  const factory NetworkMonitorState.initial() = _InitialNetworkMonitorState;

  const factory NetworkMonitorState.idle({
    required List<ConnectionStats> connections,
    required List<PingSample> pingSamples,
    required NetworkMonitorSortField sortField,
    required bool sortAscending,
  }) = _IdleNetworkMonitorState;

  const factory NetworkMonitorState.loading({
    required List<ConnectionStats> connections,
    required List<PingSample> pingSamples,
    required NetworkMonitorSortField sortField,
    required bool sortAscending,
  }) = _LoadingNetworkMonitorState;

  bool get loading => this is _LoadingNetworkMonitorState;
}

final class _IdleNetworkMonitorState extends NetworkMonitorState {
  const _IdleNetworkMonitorState({
    required super.connections,
    required super.pingSamples,
    required super.sortField,
    required super.sortAscending,
  }) : super._();
}

final class _InitialNetworkMonitorState extends _IdleNetworkMonitorState {
  const _InitialNetworkMonitorState()
    : super(
        connections: const [],
        pingSamples: const [],
        sortField: NetworkMonitorSortField.appName,
        sortAscending: true,
      );
}

final class _LoadingNetworkMonitorState extends NetworkMonitorState {
  const _LoadingNetworkMonitorState({
    required super.connections,
    required super.pingSamples,
    required super.sortField,
    required super.sortAscending,
  }) : super._();
}

/// Columns available for sorting the connection list.
enum NetworkMonitorSortField {
  appName,
  pid,
  roundtripGap,
  throughputUp,
  throughputDown,
  totalUp,
  totalDown,
}
