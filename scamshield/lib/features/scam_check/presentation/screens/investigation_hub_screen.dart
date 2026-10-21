import 'package:flutter/material.dart';

import '../../../../theme.dart';
import 'media_investigator_screen.dart';
import 'scam_investigator_screen_v2.dart';

/// Combines ScamShield's text/link/number investigator with screenshot/QR
/// investigation behind one clear Check experience.
class InvestigationHubScreen extends StatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  State<InvestigationHubScreen> createState() => _InvestigationHubScreenState();
}

class _InvestigationHubScreenState extends State<InvestigationHubScreen> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Palette.glass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Palette.glassBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Text / Link / Number',
                    icon: Icons.manage_search_rounded,
                    selected: _mode == 0,
                    onTap: () => setState(() => _mode = 0),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _ModeButton(
                    label: 'Screenshot / QR',
                    icon: Icons.image_search_rounded,
                    selected: _mode == 1,
                    onTap: () => setState(() => _mode = 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _mode,
            children: const [
              ScamInvestigatorScreen(),
              MediaInvestigatorScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? shieldGradient : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : Palette.dim,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Palette.dim,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
