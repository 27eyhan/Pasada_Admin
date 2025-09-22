import 'package:flutter/material.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

typedef QuotaSaveCallback = Future<void> Function({
  required double daily,
  required double weekly,
  required double monthly,
  required double total,
});

Future<void> showQuotaEditDialog({
  required BuildContext context,
  required double dailyInitial,
  required double weeklyInitial,
  required double monthlyInitial,
  required QuotaSaveCallback onSave,
}) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDark = themeProvider.isDarkMode;

  final dailyController = TextEditingController(text: dailyInitial.toStringAsFixed(0));
  final weeklyController = TextEditingController(text: weeklyInitial.toStringAsFixed(0));
  final monthlyController = TextEditingController(text: monthlyInitial.toStringAsFixed(0));
  double computedTotal = dailyInitial + weeklyInitial + monthlyInitial;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setLocalState) {
        return AlertDialog(
          backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit Quota Targets',
            style: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Palette.darkText : Palette.lightText,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumberField('Daily (₱)', dailyController, isDark, onChanged: (v) {
                setLocalState(() {
                  computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                      (double.tryParse(weeklyController.text) ?? 0) +
                      (double.tryParse(monthlyController.text) ?? 0);
                });
              }),
              const SizedBox(height: 10),
              _NumberField('Weekly (₱)', weeklyController, isDark, onChanged: (v) {
                setLocalState(() {
                  computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                      (double.tryParse(weeklyController.text) ?? 0) +
                      (double.tryParse(monthlyController.text) ?? 0);
                });
              }),
              const SizedBox(height: 10),
              _NumberField('Monthly (₱)', monthlyController, isDark, onChanged: (v) {
                setLocalState(() {
                  computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                      (double.tryParse(weeklyController.text) ?? 0) +
                      (double.tryParse(monthlyController.text) ?? 0);
                });
              }),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (auto):',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  Text(
                    '₱${computedTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: isDark ? Palette.darkText : Palette.lightText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await onSave(
                  daily: double.tryParse(dailyController.text) ?? 0,
                  weekly: double.tryParse(weeklyController.text) ?? 0,
                  monthly: double.tryParse(monthlyController.text) ?? 0,
                  total: computedTotal,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      });
    },
  );

  dailyController.dispose();
  weeklyController.dispose();
  monthlyController.dispose();
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String>? onChanged;

  const _NumberField(this.label, this.controller, this.isDark, {this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Palette.darkSurface : Palette.lightSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}


