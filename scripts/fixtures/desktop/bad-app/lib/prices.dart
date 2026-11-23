// Fixture: network use with no macOS network.client entitlement.
import 'package:dio/dio.dart';

Future<void> fetchPrices() => Dio().get<String>('https://example.com/prices');
