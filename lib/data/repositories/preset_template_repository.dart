import '../../core/database/database_helper.dart';
import '../models/preset_template_model.dart';

/// Repository for Preset Template (Pre-Invoice) CRUD operations.
class PresetTemplateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Fetch all templates with their items.
  Future<List<PresetTemplateModel>> getAll() async {
    final db = await _dbHelper.database;
    final templateMaps = await db.query('preset_templates', orderBy: 'created_at DESC');

    final templates = <PresetTemplateModel>[];
    for (final tMap in templateMaps) {
      final templateId = tMap['id'] as int;
      final itemMaps = await db.query(
        'preset_template_items',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      final items = itemMaps.map((m) => PresetTemplateItem.fromMap(m)).toList();
      templates.add(PresetTemplateModel.fromMap(tMap, items: items));
    }
    return templates;
  }

  /// Fetch a single template by ID with its items.
  Future<PresetTemplateModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('preset_templates', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final itemMaps = await db.query(
      'preset_template_items',
      where: 'template_id = ?',
      whereArgs: [id],
    );
    final items = itemMaps.map((m) => PresetTemplateItem.fromMap(m)).toList();
    return PresetTemplateModel.fromMap(maps.first, items: items);
  }

  /// Insert a new template with its items. Returns the new template ID.
  Future<int> insert(PresetTemplateModel template) async {
    final db = await _dbHelper.database;
    final templateId = await db.insert('preset_templates', template.toMap());

    for (final item in template.items) {
      await db.insert('preset_template_items', item.copyWith(templateId: templateId).toMap());
    }
    return templateId;
  }

  /// Delete a template and its items (cascade handled by FK).
  Future<void> delete(int id) async {
    final db = await _dbHelper.database;
    // Delete items first (in case FK cascade isn't enabled)
    await db.delete('preset_template_items', where: 'template_id = ?', whereArgs: [id]);
    await db.delete('preset_templates', where: 'id = ?', whereArgs: [id]);
  }
}
