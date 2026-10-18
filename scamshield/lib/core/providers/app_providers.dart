import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sim.dart';

/// Owns the simulated threat engine for the lifetime of the app.
///
/// Keeping this dependency in Riverpod means screens do not create or dispose
/// shared services themselves. Later, this provider can be replaced by a real
/// threat-intelligence repository without changing every widget that uses it.
final threatSimProvider = Provider<ThreatSim>((ref) {
  final sim = ThreatSim();

  // Riverpod disposes the simulator when its provider container is destroyed.
  ref.onDispose(sim.dispose);
  return sim;
});

/// Stores the currently selected destination in the main navigation shell.
///
/// This is deliberately simple state. If navigation rules become more complex,
/// we can replace it with a dedicated controller without changing the UI API.
final selectedHomeTabProvider = StateProvider<int>((ref) => 0);
