import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';

part 'app/fiscore_app.dart';
part 'features/auth/auth_gate.dart';
part 'core/widgets/fiscore_logo.dart';
part 'features/auth/welcome_screen.dart';
part 'features/home/signed_in_home_screen.dart';
part 'features/shell/setup_scaffold.dart';
part 'features/shell/app_scaffold.dart';
part 'features/shell/bottom_nav.dart';
part 'features/shell/active_site_header.dart';
part 'features/onboarding/workspace_setup_screen.dart';
part 'features/onboarding/site_setup_screen.dart';
part 'core/formatters.dart';
part 'features/dashboard/site_dashboard_screen.dart';
part 'features/audits/audits_screen.dart';
part 'features/violations/violations_screen.dart';
part 'features/sites/sites_overview_screen.dart';
part 'core/widgets/metric_tile.dart';
part 'core/widgets/dashboard_section.dart';
part 'core/widgets/operational_banner.dart';
part 'core/widgets/action_row.dart';
part 'core/widgets/module_placeholder.dart';
part 'features/shell/more_screen.dart';
part 'features/onboarding/restaurant_result_tile.dart';
part 'core/widgets/guidance_panel.dart';
part 'core/widgets/status_message.dart';
part 'services/app_exception.dart';
part 'services/auth_service.dart';
part 'services/cloud_functions_service.dart';
part 'data/models/site.dart';
part 'data/models/violation.dart';
part 'data/local/local_database.dart';
part 'data/local/sync_queue.dart';
part 'data/remote/firestore_paths.dart';
part 'data/repositories/tenant_repository.dart';
part 'data/repositories/site_repository.dart';
part 'data/repositories/master_restaurant_repository.dart';
part 'data/repositories/inspection_repository.dart';
part 'data/repositories/violation_repository.dart';
part 'services/violation_media_service.dart';

const _navy = Color(0xFF071A4A);
const _green = Color(0xFF087A3A);
const _softGreen = Color(0xFFEAF7EF);
const _ink = Color(0xFF071A32);
const _muted = Color(0xFF526079);
const _line = Color(0xFFE2E7EF);
const _page = Color(0xFFF7F9FC);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
