// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savework2/main.dart';
import 'package:savework2/services/work_day_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App loads home screen', (WidgetTester tester) async {
    await initializeDateFormatting('th');
    SharedPreferences.setMockInitialValues({});
    final storage = WorkDayStorage();
    await storage.init();
    await tester.pumpWidget(WorkDayApp(storage: storage));
    await tester.pump();

    expect(find.text('หน้าหลัก'), findsWidgets);
    expect(find.text('วันนี้'), findsOneWidget);
  });
}
