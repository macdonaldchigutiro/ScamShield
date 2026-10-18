import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'check_screen.dart';
import 'learn_screen.dart';
import 'partner_screen.dart';
import 'protect_screen.dart';
import 'radar_screen.dart';
import 'sim.dart';
import 'sos_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Palette.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ScamShieldApp());
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bg,
        colorScheme: const ColorScheme.dark(
          primary: Palette.cyan,
          secondary: Palette.violet,
        ),
        useMaterial3: true,
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final ThreatSim _sim = ThreatSim();
  int _tab = 0;

  @override
  void dispose() {
    _sim.dispose();
    super.dispose();
  }

  void _about() {
    Widget point(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Palette.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Palette.text, fontWeight: FontWeight.w700)),
                    Text(body,
                        style: const TextStyle(
                            color: Palette.dim, fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF0A1226),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Palette.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOW SCAMSHIELD WORKS',
                style: TextStyle(
                    color: Palette.cyan, letterSpacing: 3, fontSize: 12)),
            const SizedBox(height: 16),
            point(Icons.shield_outlined, 'Four layers of defence',
                'Spot the scam (Check), harden your accounts (Protect), recover fast if it happens (Help), and learn the tricks (Learn).'),
            point(Icons.hub_outlined, 'All channels',
                'SMS, WhatsApp, Facebook, email and phone-call scripts, plus fake links, dial-a-code tricks and SIM swaps.'),
            point(Icons.lock_outline, 'Private by design',
                'Messages are checked on your phone. Nothing is uploaded.'),
            point(Icons.info_outline, 'No tool catches everything',
                'Use the result as a strong hint. When unsure, contact the company on an official number you find yourself.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => shieldGradient.createShader(r),
                            child: const Text('SCAMSHIELD',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 5,
                                  color: Colors.white,
                                )),
                          ),
                          const Text('DIGITAL FRAUD DEFENCE',
                              style: TextStyle(
                                  color: Palette.dim,
                                  fontSize: 10,
                                  letterSpacing: 3)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Partner view (telcos, banks, police)',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartnerScreen(sim: _sim),
                        ),
                      ),
                      icon: const Icon(Icons.business_center_outlined,
                          color: Palette.violet),
                    ),
                    IconButton(
                      tooltip: 'How it works',
                      onPressed: _about,
                      icon: const Icon(Icons.help_outline, color: Palette.dim),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _sim,
                  builder: (context, _) => IndexedStack(
                    index: _tab,
                    children: [
                      RadarScreen(sim: _sim),
                      const CheckScreen(),
                      const ProtectScreen(),
                      const SosScreen(),
                      const LearnScreen(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF070C1C),
        indicatorColor: Palette.cyan.withOpacity(0.18),
        selectedIndex: _tab,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: 'Check'),
          NavigationDestination(icon: Icon(Icons.verified_user_outlined), label: 'Protect'),
          NavigationDestination(icon: Icon(Icons.support_agent), label: 'Help'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
        ],
      ),
    );
  }
}
