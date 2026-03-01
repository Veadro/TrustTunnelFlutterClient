import 'package:trusttunnel/data/model/connection_stats.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';
import 'package:trusttunnel/feature/network_monitor/controller/network_monitor_states.dart';

abstract class NetworkMonitorScopeController {
  abstract final List<ConnectionStats> connections;
  abstract final List<PingSample> pingSamples;
  abstract final NetworkMonitorSortField sortField;
  abstract final bool sortAscending;
  abstract final bool loading;

  abstract final void Function() startMonitoring;
  abstract final void Function() stopMonitoring;
  abstract final void Function(NetworkMonitorSortField field) changeSort;
}
