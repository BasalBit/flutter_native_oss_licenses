import 'package:flutter/material.dart';
import 'package:flutter_native_oss_licenses_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the merged-license screen', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Merged OSS licenses'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
