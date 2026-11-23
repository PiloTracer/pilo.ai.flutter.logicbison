import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

const mailSubjects = ['Invoice due', 'Team lunch', 'Release notes'];

class MailScreen extends StatefulWidget {
  const MailScreen({super.key});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mail')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = MediaQuery.of(context).size.width > 800;
          final list = ListView.builder(
            itemCount: mailSubjects.length,
            itemBuilder: (context, index) {
              final subject = mailSubjects[index];
              return ListTile(
                title: Text(subject),
                selected: wide && subject == _selected,
                onTap: () {
                  if (wide) {
                    _select(subject);
                  } else {
                    _open(context, subject);
                  }
                },
              );
            },
          );
          if (!wide) {
            return list;
          }
          final selected = _selected;
          return Row(
            children: [
              Expanded(child: list),
              const VerticalDivider(),
              Expanded(
                flex: 2,
                child: selected == null
                    ? const Center(child: Text('Select a message'))
                    : MessageBody(subject: selected),
              ),
            ],
          );
        },
      ),
    );
  }

  void _select(String subject) {
    setState(() {
      _selected = subject;
    });
  }

  void _open(BuildContext context, String subject) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => MessagePage(subject: subject),
        ),
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
