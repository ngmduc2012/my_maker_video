// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_maker_video_example/main.dart';

void main() {
  testWidgets('Verify example screen renders', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.text('Plugin my_maker_video example app'), findsOneWidget);
    expect(find.text('PART I | Images to video'), findsOneWidget);
    expect(find.text('PART II | Add Watermark To Video'), findsOneWidget);
  });
}
