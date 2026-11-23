// Fixture: same usage as bad-app, with the entitlements it needs.
import 'package:dio/dio.dart';

Future<void> fetchPrices() => Dio().get<String>('https://example.com/prices');
