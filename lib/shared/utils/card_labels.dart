import '../../models/experience_options.dart';

/// Letters only, lower case, so "🏖 Beaches" and "beaches" compare equal.
String _plain(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

/// The small labels a card can show for a listing: its category, then each of
/// its types ("Bar & Lounge", "Beach"). When the card sits in a row that is
/// already named after a category, that category is left out, because the row
/// says it already. Labels that would only repeat each other are dropped.
List<String> cardLabels({
  required String category,
  required String subcategory,
  String? sectionCategory,
}) {
  final skip = sectionCategory == null ? '' : _plain(sectionCategory);
  final seen = <String>{};
  return [
    category.trim(),
    ...splitSubcategories(subcategory),
  ].where((label) {
    final key = _plain(label);
    if (key.isEmpty || !seen.add(key)) return false;
    return skip.isEmpty || key != skip;
  }).toList();
}
