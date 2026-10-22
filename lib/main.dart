import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/data/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.inicializar();
  runApp(QuedamosApp(authRepository: AuthRepository(SupabaseService.cliente)));
}
