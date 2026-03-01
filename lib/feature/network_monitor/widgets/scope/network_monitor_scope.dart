import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:trusttunnel/common/controller/widget/state_consumer.dart';
import 'package:trusttunnel/data/model/connection_stats.dart';
import 'package:trusttunnel/data/model/ping_sample.dart';
import 'package:trusttunnel/feature/network_monitor/controller/network_monitor_controller.dart';
import 'package:trusttunnel/feature/network_monitor/controller/network_monitor_states.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/scope/network_monitor_scope_aspect.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/scope/network_monitor_scope_controller.dart';

/// {@template network_monitor_scope_template}
/// Provides NetworkMonitor controller to the widget tree
/// {@endtemplate}
class NetworkMonitorScope extends StatefulWidget {
  final Widget child;

  /// {@macro network_monitor_scope_template}
  const NetworkMonitorScope({
    required this.child,
    super.key,
  });

  /// Get the controller from context
  static NetworkMonitorScopeController controllerOf(
    BuildContext context, {
    bool listen = true,
    NetworkMonitorScopeAspect? aspect,
  }) => _InheritedNetworkMonitorScope.controllerOf(context, listen: listen, aspect: aspect);

  @override
  State<NetworkMonitorScope> createState() => _NetworkMonitorScopeState();
}

class _NetworkMonitorScopeState extends State<NetworkMonitorScope> {
  late final NetworkMonitorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = NetworkMonitorController();
    _controller.startMonitoring();
  }

  @override
  Widget build(BuildContext context) =>
      StateConsumer<NetworkMonitorController, NetworkMonitorState>(
        controller: _controller,
        builder: (context, state, _) => _InheritedNetworkMonitorScope(
          connections: [...state.connections],
          pingSamples: [...state.pingSamples],
          sortField: state.sortField,
          sortAscending: state.sortAscending,
          loading: state.loading,
          startMonitoring: _controller.startMonitoring,
          stopMonitoring: _controller.stopMonitoring,
          changeSort: _controller.changeSort,
          child: widget.child,
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _InheritedNetworkMonitorScope extends InheritedModel<NetworkMonitorScopeAspect>
    implements NetworkMonitorScopeController {
  const _InheritedNetworkMonitorScope({
    required this.connections,
    required this.pingSamples,
    required this.sortField,
    required this.sortAscending,
    required this.loading,
    required this.startMonitoring,
    required this.stopMonitoring,
    required this.changeSort,
    required super.child,
  });

  @override
  final List<ConnectionStats> connections;

  @override
  final List<PingSample> pingSamples;

  @override
  final NetworkMonitorSortField sortField;

  @override
  final bool sortAscending;

  @override
  final bool loading;

  @override
  final void Function() startMonitoring;

  @override
  final void Function() stopMonitoring;

  @override
  final void Function(NetworkMonitorSortField field) changeSort;

  @override
  bool updateShouldNotify(_InheritedNetworkMonitorScope oldWidget) =>
      loading != oldWidget.loading ||
      sortField != oldWidget.sortField ||
      sortAscending != oldWidget.sortAscending ||
      !listEquals(connections, oldWidget.connections) ||
      !listEquals(pingSamples, oldWidget.pingSamples);

  @override
  bool updateShouldNotifyDependent(
    covariant _InheritedNetworkMonitorScope oldWidget,
    Set<NetworkMonitorScopeAspect> dependencies,
  ) {
    if (dependencies.isEmpty) return updateShouldNotify(oldWidget);

    bool hasAnyChanges = false;

    for (final aspect in dependencies) {
      hasAnyChanges |= switch (aspect) {
        NetworkMonitorScopeAspect.connections => !listEquals(connections, oldWidget.connections),
        NetworkMonitorScopeAspect.pingSamples => !listEquals(pingSamples, oldWidget.pingSamples),
        NetworkMonitorScopeAspect.loading => loading != oldWidget.loading,
        NetworkMonitorScopeAspect.sort =>
          sortField != oldWidget.sortField || sortAscending != oldWidget.sortAscending,
      };

      if (hasAnyChanges) return true;
    }

    return false;
  }

  static _InheritedNetworkMonitorScope controllerOf(
    BuildContext context, {
    bool listen = true,
    NetworkMonitorScopeAspect? aspect,
  }) => _inheritFrom(context, listen: listen, aspect: aspect) ?? _notFoundInheritedWidgetOfExactType();

  static _InheritedNetworkMonitorScope? _inheritFrom(
    BuildContext context, {
    bool listen = true,
    NetworkMonitorScopeAspect? aspect,
  }) => (listen
      ? InheritedModel.inheritFrom<_InheritedNetworkMonitorScope>(
          context,
          aspect: aspect,
        )
      : context.getElementForInheritedWidgetOfExactType<_InheritedNetworkMonitorScope>()?.widget
            as _InheritedNetworkMonitorScope?);

  static Never _notFoundInheritedWidgetOfExactType<T extends InheritedModel<NetworkMonitorScopeAspect>>() =>
      throw ArgumentError(
        'Inherited widget out of scope and not found of $T exact type',
        'out_of_scope',
      );
}
