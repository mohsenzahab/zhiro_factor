import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../models/preset_template_model.dart';

/// Repository for Preset Template (Pre-Invoice) CRUD operations using Drift ORM.
class PresetTemplateRepository {
  final AppDatabase _db;

  PresetTemplateRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// Fetch all templates with their items.
  Future<List<PresetTemplateModel>> getAll() async {
    final templates = await (_db.select(_db.presetTemplates)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    final result = <PresetTemplateModel>[];
    for (final t in templates) {
      final items = await (_db.select(_db.presetTemplateItems)
            ..where((i) => i.templateId.equals(t.id)))
          .get();

      result.add(PresetTemplateModel(
        id: t.id,
        name: t.name,
        createdAt: t.createdAt,
        items: items
            .map((i) => PresetTemplateItem(
                  id: i.id,
                  templateId: i.templateId,
                  productId: i.productId,
                  productName: i.productName,
                  quantity: i.quantity,
                  unitPrice: i.unitPrice,
                ))
            .toList(),
      ));
    }
    return result;
  }

  /// Fetch a single template by ID with its items.
  Future<PresetTemplateModel?> getById(int id) async {
    final t = await (_db.select(_db.presetTemplates)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (t == null) return null;

    final items = await (_db.select(_db.presetTemplateItems)..where((i) => i.templateId.equals(id))).get();

    return PresetTemplateModel(
      id: t.id,
      name: t.name,
      createdAt: t.createdAt,
      items: items
          .map((i) => PresetTemplateItem(
                id: i.id,
                templateId: i.templateId,
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                unitPrice: i.unitPrice,
              ))
          .toList(),
    );
  }

  /// Insert a new template with its items. Returns the new template ID.
  Future<int> insert(PresetTemplateModel template) async {
    return await _db.transaction(() async {
      final templateId = await _db.into(_db.presetTemplates).insert(
            PresetTemplatesCompanion.insert(
              name: template.name.trim(),
              createdAt: Value(template.createdAt ?? DateTime.now().toIso8601String()),
            ),
          );

      for (final item in template.items) {
        await _db.into(_db.presetTemplateItems).insert(
              PresetTemplateItemsCompanion.insert(
                templateId: templateId,
                productId: Value(item.productId),
                productName: item.productName.trim(),
                quantity: Value(item.quantity),
                unitPrice: Value(item.unitPrice),
              ),
            );
      }

      return templateId;
    });
  }

  /// Delete a template and its items.
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.presetTemplateItems)..where((i) => i.templateId.equals(id))).go();
      await (_db.delete(_db.presetTemplates)..where((t) => t.id.equals(id))).go();
    });
  }
}
