import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

class QuotaBentoGrid extends StatelessWidget {
  final double dailyEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double totalEarnings;
  final double dailyTarget;
  final double weeklyTarget;
  final double monthlyTarget;
  final double totalTarget;
  final VoidCallback onEdit;
  final VoidCallback? onRefresh;

  const QuotaBentoGrid({
    super.key,
    required this.dailyEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalEarnings,
    required this.dailyTarget,
    required this.weeklyTarget,
    required this.monthlyTarget,
    required this.totalTarget,
    required this.onEdit,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            if (onRefresh != null)
              IconButton(
                tooltip: 'Refresh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                color: isDark ? Palette.darkText : Palette.lightText,
              ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: isDark ? Palette.darkText : Palette.lightText,
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit Quota'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount;
            if (constraints.maxWidth >= 1200) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth >= 900) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth >= 700) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 2.4,
              children: [
                _QuotaCard(
                  title: 'Daily Quota',
                  value: dailyEarnings,
                  target: dailyTarget,
                  accent: Colors.blue,
                  icon: Icons.calendar_today,
                ),
                _QuotaCard(
                  title: 'Weekly Quota',
                  value: weeklyEarnings,
                  target: weeklyTarget,
                  accent: Colors.purple,
                  icon: Icons.date_range,
                ),
                _QuotaCard(
                  title: 'Monthly Quota',
                  value: monthlyEarnings,
                  target: monthlyTarget,
                  accent: Colors.orange,
                  icon: Icons.calendar_month,
                ),
                _QuotaCard(
                  title: 'Overall Total',
                  value: totalEarnings,
                  target: totalTarget,
                  accent: Colors.green,
                  icon: Icons.summarize,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final String title;
  final double value;
  final double target;
  final Color accent;
  final IconData icon;

  const _QuotaCard({
    required this.title,
    required this.value,
    required this.target,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final progress = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Palette.darkCard : Palette.lightCard,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? Palette.darkBorder : Palette.lightBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: (isDark ? Colors.white24 : Colors.black12),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Text(
                  "${(progress * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        letterSpacing: 0.3,
                        color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  "₱${value.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Palette.darkText : Palette.lightText,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  "Target: ₱${target.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


