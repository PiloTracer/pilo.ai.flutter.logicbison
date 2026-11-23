import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

const mailSubjects = ['Invoice due', 'Team lunch', 'Release notes'];

class MailScreen extends StatelessWidget {
  const MailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mail')),
      body: ListView.builder(
        itemCount: mailSubjects.length,
        itemBuilder: (context, index) {
          final subject = mailSubjects[index];
          return ListTile(
            title: Text(subject),
            onTap: () => unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => MessagePage(subject: subject),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MessagePage extends StatelessWidget {
  const MessagePage({required this.subject, super.key});

  final String subject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: MessageBody(subject: subject),
    );
  }
}

class MessageBody extends StatelessWidget {
  const MessageBody({required this.subject, super.key});

  final String subject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text('Body of $subject'),
    );
  }
}
