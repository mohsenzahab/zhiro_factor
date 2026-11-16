import 'package:flutter/material.dart';

/// Represents a single micro-detail row inside a KPI card.
class KpiDetailItem {
  final String label;
  final String value;

  const KpiDetailItem({
    required this.label,
    required this.value,
  });
}

/// KPI card for the dashboard with gradient background and optional breakdown details.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final List<KpiDetailItem>? details;
  final String? helpTooltip;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.details,
    this.helpTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (helpTooltip != null && helpTooltip!.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                _KpiHelpButton(helpTooltip: helpTooltip!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (details != null && details!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < details!.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                          height: 1,
                          thickness: 0.5,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          details![i].label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            details![i].value,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiHelpButton extends StatefulWidget {
  final String helpTooltip;

  const _KpiHelpButton({required this.helpTooltip});

  @override
  State<_KpiHelpButton> createState() => _KpiHelpButtonState();
}

class _KpiHelpButtonState extends State<_KpiHelpButton> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      key: _tooltipKey,
      richMessage: _buildTooltipSpan(widget.helpTooltip),
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      verticalOffset: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      showDuration: const Duration(seconds: 15),
      waitDuration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _tooltipKey.currentState?.ensureTooltipVisible(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.priority_high_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  InlineSpan _buildTooltipSpan(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final spans = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;
      final colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        final title = line.substring(0, colonIndex + 1);
        final desc = line.substring(colonIndex + 1);
        spans.add(
          TextSpan(
            text: title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF67E8F9),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        );
        spans.add(
          TextSpan(
            text: isLast ? desc : '$desc\n\n',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: isLast ? line : '$line\n\n',
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}
