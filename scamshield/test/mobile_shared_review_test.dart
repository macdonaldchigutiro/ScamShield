import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/features/scam_check/presentation/screens/shared_message_review_screen.dart';

void main() {
  testWidgets('shared-message review fits a narrow phone viewport and stays editable',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const sample = 'Please check this message before I respond.';
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: SharedMessageReviewScreen(sharedText: sample),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Shared to ScamShield'), findsOneWidget);
    expect(find.text('INVESTIGATE NOW'), findsOneWidget);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, sample);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField).first, 'Updated draft');
    expect(field.controller!.text, 'Updated draft');
  });
}
