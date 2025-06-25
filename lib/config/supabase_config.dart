import 'package:supabase_flutter/supabase_flutter.dart';

// Replace with your Supabase URL and Anon Key
const String supabaseUrl = 'https://ikdzbebwghxviblblnou.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlrZHpiZWJ3Z2h4dmlibGJsbm91Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NDA4OTUsImV4cCI6MjA2NjQxNjg5NX0.yahHcuCunwFL442bvtMvukYzgLxs0Ux6AUt0ThiNE8k';

class SupabaseConfig {
  static final supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
