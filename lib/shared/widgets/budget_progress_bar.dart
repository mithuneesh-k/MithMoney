import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/formatters.dart';

class BudgetProgressBar extends StatefulWidget {
  final String label;
  final double spent;
  final double budget;
  final Color? color;
  final String currencySymbol;
  final int animationDelay;

  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.spent,
    required this.budget,
    this.color,
    this.currencySymbol = '₹',
    this.animationDelay = 0,
  });

  @override
  State<BudgetProgressBar> createState() => _BudgetProgressBarState();
}

class _BudgetProgressBarState extends State<BudgetProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;
  late Animation<Color?> _colorAnimation;

  double get _ratio =>
      widget.budget > 0 ? (widget.spent / widget.budget).clamp(0.0, 1.0) : 0;

  Color get _targetColor {
    if (_ratio >= 0.85) return const Color(0xFFE8365D);
    if (_ratio >= 0.60) return const Color(0xFFFFB300);
    return widget.color ?? const Color(0xFF00B87C);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fillAnimation = Tween<double>(begin: 0, end: _ratio).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
    );
    _colorAnimation = ColorTween(
      begin: widget.color ?? const Color(0xFF00B87C),
      end: _targetColor,
    ).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(BudgetProgressBar old) {
    super.didUpdateWidget(old);
    if (old.spent != widget.spent || old.budget != widget.budget) {
      final from = _fillAnimation.value;
      _fillAnimation = Tween<double>(begin: from, end: _ratio).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverspent = widget.spent > widget.budget && widget.budget > 0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final currentColor = _colorAnimation.value ?? _targetColor;
        final currentRatio = _fillAnimation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isOverspent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE8365D).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Over',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE8365D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${AppFormatters.formatAmountCompact(widget.spent, widget.currencySymbol)} / '
                  '${AppFormatters.formatAmountCompact(widget.budget, widget.currencySymbol)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                // Background track
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                LayoutBuilder(builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth * currentRatio,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.formatPercentage(_ratio * 100),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: currentColor,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    )
        .animate(delay: Duration(milliseconds: widget.animationDelay))
        .fadeIn(duration: 400.ms)
        .slideX(
            begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOutExpo);
  }
}
