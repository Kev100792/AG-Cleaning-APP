import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;

  AppConfig({required this.supabaseUrl, required this.supabaseAnonKey});

  static Future<AppConfig> load() async {
    // 1) essaie d'abord les --dart-define si présents
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isNotEmpty && key.isNotEmpty) {
      return AppConfig(supabaseUrl: url, supabaseAnonKey: key);
    }
    // 2) sinon, charge assets/config/local.json
    final raw = await rootBundle.loadString('assets/config/local.json');
    final map = (json.decode(raw) as Map).cast<String, dynamic>();
    return AppConfig(
      supabaseUrl: map['SUPABASE_URL'] as String,
      supabaseAnonKey: map['SUPABASE_ANON_KEY'] as String,
    );
  }
}
