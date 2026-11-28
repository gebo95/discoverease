import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/models/claimable_business.dart';

void main() {
  test('a claimable business needs an id and a name', () {
    expect(ClaimableBusiness.fromJson('a', {'name': ' Cafe '})?.name, 'Cafe');
    expect(ClaimableBusiness.fromJson('', {'name': 'Cafe'}), isNull);
    expect(ClaimableBusiness.fromJson('a', {'name': '  '}), isNull);
    expect(ClaimableBusiness.fromJson('a', {}), isNull);
  });

  test('only hints are kept, and missing ones are empty', () {
    final business = ClaimableBusiness.fromJson('a', {
      'name': 'Cafe',
      'emailHint': 'ow***@cafe.com',
      'phoneHint': '***67',
      'category': 'Food',
    })!;
    expect(business.emailHint, 'ow***@cafe.com');
    expect(business.phoneHint, '***67');
    expect(ClaimableBusiness.fromJson('b', {'name': 'X'})!.emailHint, '');
  });

  test('search matches name or category, ignoring case', () {
    final business = ClaimableBusiness.fromJson('a', {
      'name': 'Island Cafe',
      'category': 'Food',
    })!;
    expect(business.matches('island'), isTrue);
    expect(business.matches('FOOD'), isTrue);
    expect(business.matches('  '), isTrue);
    expect(business.matches('boat'), isFalse);
  });

  test('a claim request needs an id and a business', () {
    final request = ClaimRequest.fromJson('r1', {
      'businessId': 'b1',
      'businessName': 'Cafe',
      'contact': 'me@example.com',
      'note': 'I own it',
    })!;
    expect(request.contact, 'me@example.com');
    expect(request.createdAt, isNull);
    expect(ClaimRequest.fromJson('', {'businessId': 'b1'}), isNull);
    expect(ClaimRequest.fromJson('r1', {}), isNull);
  });

  test('only claimed businesses are listed for taking back', () {
    final claimed = ClaimedBusiness.fromJson('b1', {
      'name': 'Cafe',
      'claimStatus': 'claimed',
      'email': 'o@c.com',
      'ownerUid': 'u1',
    })!;
    expect(claimed.ownerUid, 'u1');
    expect(ClaimedBusiness.fromJson('b1', {'name': 'Cafe', 'claimStatus': 'unclaimed'}), isNull);
    expect(ClaimedBusiness.fromJson('b1', {'name': 'Cafe'}), isNull);
    expect(ClaimedBusiness.fromJson('b1', {'claimStatus': 'claimed'})!.name, 'Unnamed business');
  });
}
