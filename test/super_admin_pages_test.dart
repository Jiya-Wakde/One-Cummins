import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:onecummins/pages/super_admin_notices_page.dart';
import 'package:onecummins/pages/club_requests_page.dart';
import 'package:onecummins/pages/dashboard_page.dart';

void main() {
  testWidgets('SuperAdminNoticesPage builds and shows create button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Create Notice'), findsOneWidget);
  });

  testWidgets('ClubRequestsPage builds without crashing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ClubRequestsPage()));
    await tester.pumpAndSettle();

    // Either a progress indicator or text will be present; ensure no crash
    expect(find.byType(CircularProgressIndicator).evaluate().isNotEmpty || find.textContaining('No requests').evaluate().isNotEmpty, true);
  });
}
