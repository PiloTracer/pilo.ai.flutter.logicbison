import 'package:material_ui/material_ui.dart';

import 'presentation/home_screen.dart';
import 'theme/app_theme.dart';

class EvalApp extends StatelessWidget {
  const EvalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eval App',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
