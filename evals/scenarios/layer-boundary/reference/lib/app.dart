import 'package:flutter/material.dart';

import 'data/user_repository_impl.dart';
import 'domain/user_repository.dart';
import 'presentation/home_screen.dart';
import 'theme/app_theme.dart';

class EvalApp extends StatelessWidget {
  const EvalApp({super.key, this.userRepository = const UserRepositoryImpl()});

  final UserRepository userRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eval App',
      theme: AppTheme.light(),
      home: HomeScreen(userRepository: userRepository),
    );
  }
}
