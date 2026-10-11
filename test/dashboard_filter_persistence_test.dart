import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_box/data/repositories/settings_repository.dart';
import 'package:sales_box/shared/widgets/date_range_filter_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard Filter Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default filter preferences when none saved', () async {
      final repo = SettingsRepository.instance;
      final filter = await repo.loadDashboardFilter();

      expect(filter.preset, DateRangePreset.thisMonth);
      expect(filter.category, isNull);
      expect(filter.customDateFrom, isNull);
      expect(filter.customDateTo, isNull);
    });

    test('save and load dashboard filter with preset and category', () async {
      final repo = SettingsRepository.instance;

      await repo.saveDashboardFilter(
        preset: DateRangePreset.today,
        category: 'خدمات',
      );

      final filter = await repo.loadDashboardFilter();
      expect(filter.preset, DateRangePreset.today);
      expect(filter.category, 'خدمات');
      expect(filter.customDateFrom, isNull);
      expect(filter.customDateTo, isNull);
    });

    test('save and load dashboard filter with custom date range', () async {
      final repo = SettingsRepository.instance;

      await repo.saveDashboardFilter(
        preset: DateRangePreset.custom,
        customDateFrom: '2026-10-01T00:00:00.000',
        customDateTo: '2026-10-10T23:59:59.999',
        category: 'پوشاک',
      );

      final filter = await repo.loadDashboardFilter();
      expect(filter.preset, DateRangePreset.custom);
      expect(filter.customDateFrom, '2026-10-01T00:00:00.000');
      expect(filter.customDateTo, '2026-10-10T23:59:59.999');
      expect(filter.category, 'پوشاک');
    });

    test('clearing category saves null in filter preferences', () async {
      final repo = SettingsRepository.instance;

      await repo.saveDashboardFilter(
        preset: DateRangePreset.thisWeek,
        category: 'خدمات',
      );

      var filter = await repo.loadDashboardFilter();
      expect(filter.category, 'خدمات');

      // Clear category (e.g. "همه" selected)
      await repo.saveDashboardFilter(
        preset: DateRangePreset.thisWeek,
        category: null,
      );

      filter = await repo.loadDashboardFilter();
      expect(filter.preset, DateRangePreset.thisWeek);
      expect(filter.category, isNull);
    });
  });

  group('Invoice History Filter Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default invoice history filter when none saved', () async {
      final repo = SettingsRepository.instance;
      final filter = await repo.loadInvoiceHistoryFilter();

      expect(filter.preset, DateRangePreset.thisMonth);
      expect(filter.category, isNull);
      expect(filter.customDateFrom, isNull);
      expect(filter.customDateTo, isNull);
    });

    test('save and load invoice history filter with preset, category and custom dates', () async {
      final repo = SettingsRepository.instance;

      await repo.saveInvoiceHistoryFilter(
        preset: DateRangePreset.today,
        category: 'خدمات',
      );

      var filter = await repo.loadInvoiceHistoryFilter();
      expect(filter.preset, DateRangePreset.today);
      expect(filter.category, 'خدمات');

      // Custom date range
      await repo.saveInvoiceHistoryFilter(
        preset: DateRangePreset.custom,
        customDateFrom: '2026-10-01',
        customDateTo: '2026-10-15',
        category: null,
      );

      filter = await repo.loadInvoiceHistoryFilter();
      expect(filter.preset, DateRangePreset.custom);
      expect(filter.customDateFrom, '2026-10-01');
      expect(filter.customDateTo, '2026-10-15');
      expect(filter.category, isNull);
    });
  });
}
