import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop
  sqfliteFfiInit();

  // Initialize database (with automatic rolling backups)
  await DatabaseHelper.instance.database;

  runApp(const ZhiroFactorApp());
}
