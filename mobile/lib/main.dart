import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final refresh = ValueNotifier<int>(0);
  runApp(ProviderScope(child: PosApp(refreshListenable: refresh)));
}
