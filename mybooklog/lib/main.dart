import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/core/config/app_config.dart';

/// Entry point: the very first code that runs when the app starts.
///
/// In plain terms, four things happen here, in order:
///   1. We make sure the Flutter framework itself is fully awake and ready
///      (required before doing any setup work like connecting to a server).
///   2. We connect to Supabase — the online service that stores every user's
///      account and their saved bookshelf — using the web address and access
///      key that were baked in when the app was built.
///   3. We open the on-device settings store, so things like the user's
///      chosen theme color can be remembered across app restarts.
///   4. We hand control to the app's user interface (MyApp), which takes it
///      from here.
Future<void> main() async {
  // Step 1: wake up the Flutter framework.
  WidgetsFlutterBinding.ensureInitialized();
  // Step 2: open the connection to the online database service.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabasePublishableKey,
  );
  // Step 3: load on-device settings up front so they're ready on the very
  // first frame, rather than flashing default values before they load.
  final sharedPreferences = await SharedPreferences.getInstance();
  // Step 4: draw the app on screen.
  runApp(MyApp(sharedPreferences: sharedPreferences));
}
