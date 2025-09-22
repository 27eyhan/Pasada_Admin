import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasada_admin_application/config/palette.dart';
import 'package:pasada_admin_application/config/theme_provider.dart';
import 'package:provider/provider.dart';

typedef QuotaSaveCallback = Future<void> Function({
  required double daily,
  required double weekly,
  required double monthly,
  required double total,
  int? driverId,
});

Future<void> showQuotaEditDialog({
  required BuildContext context,
  required double dailyInitial,
  required double weeklyInitial,
  required double monthlyInitial,
  required List<Map<String, dynamic>> drivers, // expects [{driver_id, full_name}, ...]
  int? initialDriverId, // null means global
  required QuotaSaveCallback onSave,
}) async {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDark = themeProvider.isDarkMode;

  final dailyController = TextEditingController(text: dailyInitial.toStringAsFixed(0));
  final weeklyController = TextEditingController(text: weeklyInitial.toStringAsFixed(0));
  final monthlyController = TextEditingController(text: monthlyInitial.toStringAsFixed(0));
  double computedTotal = dailyInitial + weeklyInitial + monthlyInitial;
  int? selectedDriverId = initialDriverId;

  await showDialog(
    context: context,
    builder: (ctx) {
      bool isSaving = false;
      return StatefulBuilder(builder: (ctx, setLocalState) {
        final double screenWidth = MediaQuery.of(ctx).size.width;
        final double dialogMaxWidth = screenWidth * 0.6 < 480 ? 480 : (screenWidth * 0.6 > 900 ? 900 : screenWidth * 0.6);
        Future<void> doSave() async {
          setLocalState(() => isSaving = true);
          await onSave(
            daily: double.tryParse(dailyController.text) ?? 0,
            weekly: double.tryParse(weeklyController.text) ?? 0,
            monthly: double.tryParse(monthlyController.text) ?? 0,
            total: computedTotal,
            driverId: selectedDriverId,
          );
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        }

        return AlertDialog(
          backgroundColor: isDark ? Palette.darkCard : Palette.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: (isDark ? Colors.white12 : Colors.black12),
                child: Icon(Icons.edit_note, color: isDark ? Palette.darkText : Palette.lightText, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Edit Quota Targets',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: isDark ? Palette.darkText : Palette.lightText,
                ),
              ),
              const Spacer(),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: dialogMaxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign to',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?> (
                    value: selectedDriverId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All drivers (Global)')),
                      ...drivers.map((d) => DropdownMenuItem<int?>(
                            value: d['driver_id'] as int?,
                            child: Text(d['full_name']?.toString() ?? 'Driver ${d['driver_id']}'),
                          )),
                    ],
                    onChanged: isSaving ? null : (val) => setLocalState(() => selectedDriverId = val),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? Palette.darkSurface : Palette.lightSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Palette.darkDivider : Palette.lightDivider)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NumberField('Daily target', dailyController, isDark, onChanged: (v) {
                    setLocalState(() {
                      computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                          (double.tryParse(weeklyController.text) ?? 0) +
                          (double.tryParse(monthlyController.text) ?? 0);
                    });
                  }),
                  const SizedBox(height: 10),
                  _NumberField('Weekly target', weeklyController, isDark, onChanged: (v) {
                    setLocalState(() {
                      computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                          (double.tryParse(weeklyController.text) ?? 0) +
                          (double.tryParse(monthlyController.text) ?? 0);
                    });
                  }),
                  const SizedBox(height: 10),
                  _NumberField('Monthly target', monthlyController, isDark, onChanged: (v) {
                    setLocalState(() {
                      computedTotal = (double.tryParse(dailyController.text) ?? 0) +
                          (double.tryParse(weeklyController.text) ?? 0) +
                          (double.tryParse(monthlyController.text) ?? 0);
                    });
                  }),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Palette.darkSurface : Palette.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.summarize, size: 18, color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Total (auto-calculated)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
                            ),
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
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Palette.darkText : Palette.lightText,
                side: BorderSide(color: isDark ? Palette.darkBorder : Palette.lightBorder),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            FilledButton.icon(
              onPressed: isSaving ? null : doSave,
              icon: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(isSaving ? 'Saving...' : 'Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
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
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Palette.darkSurface : Palette.lightSurface,
            prefixText: '₱',
            prefixStyle: TextStyle(
              fontFamily: 'Inter',
              color: isDark ? Palette.darkTextSecondary : Palette.lightTextSecondary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Palette.darkDivider : Palette.lightDivider),
            ),
          ),
        ),
      ],
    );
  }
}


