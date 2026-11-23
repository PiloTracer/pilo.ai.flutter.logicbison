// Fixture: file dialogs with no macOS files.user-selected entitlement.
import 'package:file_picker/file_picker.dart';

Future<void> pick() => FilePicker.platform.pickFiles();
