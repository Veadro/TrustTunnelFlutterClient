import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/data/model/connection_stats.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';
import 'package:trusttunnel/feature/network_monitor/controller/network_monitor_states.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/connection_row.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/ping_timeline_chart.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/scope/network_monitor_scope.dart';
import 'package:trusttunnel/widgets/custom_app_bar.dart';
import 'package:trusttunnel/widgets/scaffold_wrapper.dart';

class NetworkMonitorScreenView extends StatefulWidget {
  const NetworkMonitorScreenView({super.key});

  @override
  State<NetworkMonitorScreenView> createState() => _NetworkMonitorScreenViewState();
}

class _NetworkMonitorScreenViewState extends State<NetworkMonitorScreenView> {
  late List<ConnectionStats> _connections;
  late List<PingSample> _pingSamples;
  late NetworkMonitorSortField _sortField;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    final controller = NetworkMonitorScope.controllerOf(context, listen: false);
    _connections = controller.connections;
    _pingSamples = controller.pingSamples;
    _sortField = controller.sortField;
    _sortAscending = controller.sortAscending;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = NetworkMonitorScope.controllerOf(context);
    _connections = controller.connections;
    _pingSamples = controller.pingSamples;
    _sortField = controller.sortField;
    _sortAscending = controller.sortAscending;
  }

  @override
  Widget build(BuildContext context) => ScaffoldWrapper(
    child: Scaffold(
      appBar: const CustomAppBar(title: 'Network Monitor'),
      body: Column(
        children: [
          // Connection list
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1),
                Expanded(
                  child: _connections.isEmpty
                      ? Center(
                          child: Text(
                            'No active connections',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.textTheme.bodySmall?.color,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _connections.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => ConnectionRow(
                            stats: _connections[index],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Ping timeline chart
          Expanded(
            flex: 2,
            child: PingTimelineChart(samples: _pingSamples),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeader(BuildContext context) {
    final headerStyle = context.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildHeaderCell('App', NetworkMonitorSortField.appName, 3, headerStyle),
          _buildHeaderCell('PID', NetworkMonitorSortField.pid, 2, headerStyle),
          _buildHeaderCell('RTT Gap', NetworkMonitorSortField.roundtripGap, 2, headerStyle),
          _buildHeaderCell('Up', NetworkMonitorSortField.throughputUp, 2, headerStyle),
          _buildHeaderCell('Down', NetworkMonitorSortField.throughputDown, 2, headerStyle),
          _buildHeaderCell('Total Up', NetworkMonitorSortField.totalUp, 2, headerStyle),
          _buildHeaderCell('Total Down', NetworkMonitorSortField.totalDown, 2, headerStyle),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String label,
    NetworkMonitorSortField field,
    int flex,
    TextStyle? style,
  ) => Expanded(
    flex: flex,
    child: InkWell(
      onTap: () => NetworkMonitorScope.controllerOf(context, listen: false).changeSort(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: style),
          if (_sortField == field)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
        ],
      ),
    ),
  );
}
