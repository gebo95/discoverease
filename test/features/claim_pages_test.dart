import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:discoverease/features/business/pages/admin_claims_page.dart';
import 'package:discoverease/features/business/pages/claim_business_page.dart';
import 'package:discoverease/models/claimable_business.dart';
import 'package:discoverease/repositories/destination_repository.dart';
import 'package:discoverease/services/firebase_claim_service.dart';

class _FakeClaims implements FirebaseClaimService {
  _FakeClaims({
    this.claimable = const [],
    this.requests = const [],
    this.claimed = const [],
    this.confirmError,
  });

  final List<ClaimableBusiness> claimable;
  final List<ClaimRequest> requests;
  final List<ClaimedBusiness> claimed;
  final String? confirmError;
  final calls = <String>[];

  @override
  Stream<List<ClaimableBusiness>> watchClaimable() => Stream.value(claimable);

  @override
  Future<String> requestCode(String businessId) async {
    calls.add('send:$businessId');
    return 'ow***@cafe.com';
  }

  @override
  Future<void> confirmCode({required String businessId, required String code}) async {
    calls.add('confirm:$businessId:$code');
    if (confirmError != null) throw StateError(confirmError!);
  }

  @override
  Future<void> submitRequest({
    required String businessId,
    required String contact,
    String note = '',
  }) async {
    calls.add('help:$businessId:$contact:$note');
  }

  @override
  Future<void> createClaimable({
    required String name,
    required String email,
    String phone = '',
    String category = '',
    String destinationId = '',
  }) async {
    calls.add('create:$name:$email:$destinationId');
  }

  @override
  Stream<List<ClaimRequest>> watchPendingRequests() => Stream.value(requests);

  @override
  Stream<List<ClaimedBusiness>> watchClaimedBusinesses() => Stream.value(claimed);

  @override
  Future<void> revokeOwnership({
    required String businessId,
    String reason = '',
  }) async {
    calls.add('revoke:$businessId:$reason');
  }

  @override
  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
    String note = '',
  }) async {
    calls.add('review:$requestId:$approve');
  }
}

const _cafe = ClaimableBusiness(
  id: 'b1',
  name: 'Island Cafe',
  category: 'Food',
  emailHint: 'ow***@cafe.com',
);

Future<void> _pump(WidgetTester tester, _FakeClaims fake, Widget page) async {
  tester.view.physicalSize = const Size(420, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final destinations = DestinationRepository();
  addTearDown(destinations.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FirebaseClaimService>.value(value: fake),
        ChangeNotifierProvider<DestinationRepository>.value(value: destinations),
      ],
      // The page sits on top of a base page, like in the app, so closing it
      // has somewhere to go back to.
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                child: const Text('base'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => page),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('base'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the list shows only masked hints and can be searched', (tester) async {
    await _pump(
      tester,
      _FakeClaims(claimable: [
        _cafe,
        const ClaimableBusiness(id: 'b2', name: 'Blue Boats', category: 'Tours'),
      ]),
      const ClaimBusinessPage(),
    );
    expect(find.text('Island Cafe'), findsOneWidget);
    expect(find.textContaining('ow***@cafe.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'boat');
    await tester.pump();
    expect(find.text('Island Cafe'), findsNothing);
    expect(find.text('Blue Boats'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No business matches that name.'), findsOneWidget);
  });

  testWidgets('an empty list says so', (tester) async {
    await _pump(tester, _FakeClaims(), const ClaimBusinessPage());
    expect(find.textContaining('No businesses are waiting'), findsOneWidget);
  });

  testWidgets('send a code, type it, and the page closes as claimed', (tester) async {
    final fake = _FakeClaims();
    await _pump(tester, fake, const ClaimCodePage(business: _cafe));
    expect(find.textContaining('ow***@cafe.com'), findsOneWidget);
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(fake.calls, ['send:b1']);
    expect(find.textContaining('6-digit code'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(fake.calls.last, 'confirm:b1:123456');
    // The page closed and the base page is showing again.
    expect(find.text('Send code'), findsNothing);
    expect(find.text('base'), findsOneWidget);
    expect(find.text('You now manage Island Cafe.'), findsOneWidget);
  });

  testWidgets('a wrong code shows the server message and stays on the page', (tester) async {
    final fake = _FakeClaims(confirmError: 'That code is not right. 4 tries left.');
    await _pump(tester, fake, const ClaimCodePage(business: _cafe));
    await tester.tap(find.text('Send code'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(find.text('That code is not right. 4 tries left.'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('"I can\'t get the code" needs a contact and sends a request', (tester) async {
    final fake = _FakeClaims();
    await _pump(tester, fake, const ClaimCodePage(business: _cafe));
    await tester.tap(find.text('I can\'t get the code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send request'));
    await tester.pump();
    expect(find.textContaining('Enter an email or phone'), findsOneWidget);
    expect(fake.calls, isEmpty);
    await tester.enterText(find.widgetWithText(TextField, 'Your email or phone'), 'me@example.com');
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(fake.calls.single, 'help:b1:me@example.com:');
  });

  testWidgets('an admin can add a business to be claimed', (tester) async {
    final fake = _FakeClaims();
    await _pump(tester, fake, const AdminClaimsPage());
    await tester.enterText(find.widgetWithText(TextField, 'Business name'), 'New Cafe');
    await tester.enterText(find.widgetWithText(TextField, 'Contact email'), 'owner@newcafe.com');
    await tester.tap(find.text('Add business'));
    await tester.pump();
    expect(fake.calls.single, startsWith('create:New Cafe:owner@newcafe.com:'));
    expect(find.text('New Cafe can now be claimed.'), findsOneWidget);
  });

  testWidgets('an admin sees waiting requests and can approve or reject', (tester) async {
    final fake = _FakeClaims(requests: [
      const ClaimRequest(
        id: 'r1',
        businessId: 'b1',
        businessName: 'Island Cafe',
        accountEmail: 'me@gmail.com',
        contact: '242-555-0167',
        note: 'I am the owner',
      ),
    ]);
    await _pump(tester, fake, const AdminClaimsPage());
    await tester.scrollUntilVisible(find.text('Island Cafe'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('242-555-0167'), findsOneWidget);
    expect(find.textContaining('I am the owner'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pump();
    expect(fake.calls.last, 'review:r1:true');
    await tester.tap(find.text('Reject'));
    await tester.pump();
    expect(fake.calls.last, 'review:r1:false');
  });

  testWidgets('an admin can take a claimed business back, after confirming', (tester) async {
    final fake = _FakeClaims(claimed: [
      const ClaimedBusiness(
        id: 'b1',
        name: 'Island Cafe',
        email: 'owner@cafe.com',
        ownerUid: 'u1',
      ),
    ]);
    await _pump(tester, fake, const AdminClaimsPage());
    await tester.scrollUntilVisible(find.text('Take back'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Take back'));
    await tester.pumpAndSettle();
    // Cancelling does nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fake.calls, isEmpty);
    await tester.tap(find.text('Take back'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Reason (kept in the log)'), 'Left the company');
    await tester.tap(find.text('Take it back'));
    await tester.pumpAndSettle();
    expect(fake.calls.single, 'revoke:b1:Left the company');
    expect(find.text('Island Cafe can be claimed again.'), findsOneWidget);
  });
}
