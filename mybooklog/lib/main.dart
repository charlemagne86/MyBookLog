import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';

/// Entry point: the very first code that runs when the app starts.
///
/// In plain terms, three things happen here, in order:
///   1. We make sure the Flutter framework itself is fully awake and ready
///      (required before doing any setup work like connecting to a server).
///   2. We connect to Supabase — the online service that stores every user's
///      account and their saved bookshelf — using the web address and access
///      key that were baked in when the app was built.
///   3. We hand control to the app's user interface (MyApp), which takes it
///      from here.
Future<void> main() async {
  // Step 1: wake up the Flutter framework.
  WidgetsFlutterBinding.ensureInitialized();
  // Step 2: open the connection to the online database service.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  // Step 3: draw the app on screen.
  runApp(const MyApp());
}
