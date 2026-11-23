// Fixture: same usage as bad-app, with the entitlements it needs.
import 'package:file_picker/file_picker.dart';

Future<void> pick() => FilePicker.platform.pickFiles();
