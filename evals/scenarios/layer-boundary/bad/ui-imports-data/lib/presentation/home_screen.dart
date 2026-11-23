import 'package:material_ui/material_ui.dart';

import '../domain/user.dart';
import '../data/user_repository_impl.dart';
import '../domain/user_repository.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.userRepository, super.key});

  final UserRepository userRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<User> _user = widget.userRepository.currentUser();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Eval App', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<User>(
              future: _user,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Text(
                  user?.displayName ?? '',
                  style: textTheme.titleMedium,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
