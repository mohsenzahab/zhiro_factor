import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/number_extensions.dart';
import '../../../../core/utils/jalali_utils.dart';
import '../../../../data/models/demand_model.dart';
import '../../cubit/demand_cubit.dart';

/// Dialog showing complete history of customer requests for a specific demand item.
class DemandHistoryDialog extends StatelessWidget {
  final DemandModel demand;
  final DemandCubit cubit;

  const DemandHistoryDialog({
    super.key,
    required this.demand,
    required this.cubit,
  });

  static void show(BuildContext context, {required DemandModel demand, required DemandCubit cubit}) {
    showDialog(
      context: context,
      builder: (_) => DemandHistoryDialog(demand: demand, cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = List<String>.from(demand.requestDates)
      ..sort((a, b) => b.compareTo(a)); // Newest first

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 580),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.history, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاریخچه درخواست‌ها',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            demand.title,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.textMuted,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Summary Chips ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.dividerDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCol(
                        label: 'تعداد کل:',
                        value: '${demand.requestCount.toString().toPersianDigits()} بار',
                        color: AppColors.primary,
                      ),
                      Container(height: 24, width: 1, color: AppColors.dividerDark),
                      _StatCol(
                        label: 'میانگین ماهانه:',
                        value: demand.averageRequestsPerMonthDisplay,
                        color: AppColors.info,
                      ),
                      Container(height: 24, width: 1, color: AppColors.dividerDark),
                      _StatCol(
                        label: 'اولین درخواست:',
                        value: demand.firstRequestDate != null
                            ? JalaliUtils.formatIso(demand.firstRequestDate!)
                            : '---',
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Dates List ──────────────────────────────────────
                const Text(
                  'ثبت‌های تقاضای مشتری:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: sortedDates.isEmpty
                      ? const Center(
                          child: Text('هیچ تاریخی ثبت نشده است', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.separated(
                          itemCount: sortedDates.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.dividerDark),
                          itemBuilder: (context, index) {
                            final dateIso = sortedDates[index];
                            final jalaliStr = JalaliUtils.formatIso(dateIso);
                            final dt = DateTime.tryParse(dateIso);
                            final timeStr = dt != null
                                ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'.toPersianDigits()
                                : '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.surfaceDark,
                                    child: Text(
                                      '${sortedDates.length - index}'.toPersianDigits(),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      jalaliStr,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (timeStr.isNotEmpty)
                                    Text(
                                      timeStr,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 14),

                // ── Add Request Quick Button ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('ثبت درخواست با تاریخ امروز'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          if (demand.id != null) {
                            await cubit.incrementRequest(demand.id!);
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, size: 20),
                      color: AppColors.primary,
                      tooltip: 'ثبت با تاریخ دلخواه',
                      onPressed: () async {
                        final picked = await showPersianDatePicker(
                          context: context,
                          initialDate: Jalali.now(),
                          firstDate: Jalali(1400, 1, 1),
                          lastDate: Jalali(1450, 12, 29),
                        );
                        if (picked != null && demand.id != null) {
                          await cubit.incrementRequest(
                            demand.id!,
                            requestDate: JalaliUtils.toIso(picked),
                          );
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCol({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
