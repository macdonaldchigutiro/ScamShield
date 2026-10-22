import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sharing/share_intent_bridge.dart';
import '../../../../theme.dart';
import 'media_investigator_screen.dart';
import 'phishing_investigator_screen.dart';
import 'scam_investigator_screen_v2.dart';
import 'shared_message_review_screen.dart';

/// Combines ScamShield's investigation tools behind one clear Check experience.
class InvestigationHubScreen extends ConsumerStatefulWidget {
  const InvestigationHubScreen({super.key});

  @override
  ConsumerState<InvestigationHubScreen> createState() =>
      _InvestigationHubScreenState();
}

class _InvestigationHubScreenState
    extends ConsumerState<InvestigationHubScreen> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final sharedText = ref.watch(sharedTextProvider);

    if (sharedText != null && sharedText.trim().isNotEmpty) {
      return SharedMessageReviewScreen(sharedText: sharedText);
    }

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
                    label: 'Message / Link / Number',
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
                const SizedBox(width: 5),
                Expanded(
                  child: _ModeButton(
                    label: 'Phishing email',
                    icon: Icons.mark_email_unread_outlined,
                    selected: _mode == 2,
                    onTap: () => setState(() => _mode = 2),
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
              PhishingInvestigatorScreen(),
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
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
        decoration: BoxDecoration(
          gradient: selected ? shieldGradient : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Palette.dim,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Palette.dim,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
