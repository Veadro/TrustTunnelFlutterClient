import 'package:flutter/material.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/network_monitor_screen_view.dart';
import 'package:trusttunnel/feature/network_monitor/widgets/scope/network_monitor_scope.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) => const NetworkMonitorScope(
    child: NetworkMonitorScreenView(),
  );
}
