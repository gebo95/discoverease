import 'package:discoverease/shared/utils/card_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the category then each type', () {
    expect(
      cardLabels(category: 'Entertainment', subcategory: 'Nightlife, Beach'),
      ['Entertainment', 'Nightlife', 'Beach'],
    );
    expect(cardLabels(category: 'Tours', subcategory: ''), ['Tours']);
    expect(cardLabels(category: '', subcategory: 'Sushi'), ['Sushi']);
  });

  test('leaves out the category the row is already named after', () {
    expect(
      cardLabels(category: 'Tours', subcategory: 'Boat Tour', sectionCategory: 'Tours'),
      ['Boat Tour'],
    );
    expect(
      cardLabels(category: 'Tours', subcategory: '', sectionCategory: 'Tours'),
      isEmpty,
    );
  });

  test('matches categories regardless of emoji, case or plural spacing', () {
    expect(
      cardLabels(category: '🏖 Beaches', subcategory: '', sectionCategory: 'beaches'),
      isEmpty,
    );
    expect(
      cardLabels(category: 'Dining', subcategory: 'Seafood', sectionCategory: '🍽 dining'),
      ['Seafood'],
    );
  });

  test('does not repeat a label that says the same thing twice', () {
    expect(
      cardLabels(category: 'Tours', subcategory: 'tours, Boat Tour'),
      ['Tours', 'Boat Tour'],
    );
  });

  test('a row for another category keeps everything', () {
    expect(
      cardLabels(category: 'Dining', subcategory: 'Bar & Lounge', sectionCategory: 'Tours'),
      ['Dining', 'Bar & Lounge'],
    );
  });
}
