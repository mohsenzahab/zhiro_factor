import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'core/database/database_seeder.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop
  sqfliteFfiInit();

  // Initialize database
  await DatabaseHelper.instance.database;

  // Seed mock data on first run
  await DatabaseSeeder.seedIfEmpty();

  runApp(const ZhiroFactorApp());
}
