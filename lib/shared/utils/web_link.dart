/// Helpers for web addresses that business owners type in.
///
/// Only http and https links are accepted, so values like `javascript:` can
/// never be stored or opened. A bare `example.com` is accepted and saved as
/// `https://example.com`.
final RegExp _hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');

/// Returns the parsed link, or null when [raw] is not a usable web address.
Uri? parseWebLink(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value.contains(RegExp(r'\s'))) return null;
  final withScheme = _hasScheme.hasMatch(value) ? value : 'https://$value';
  final uri = Uri.tryParse(withScheme);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  // Links with a username part (https://google.com@evil.com) can disguise
  // the real destination, so they are not accepted.
  if (uri.userInfo.isNotEmpty) return null;
  final host = uri.host;
  if (!host.contains('.') || host.startsWith('.') || host.endsWith('.')) {
    return null;
  }
  return uri;
}

bool isValidWebLink(String raw) => parseWebLink(raw) != null;

/// The form to store: empty stays empty, valid links get a scheme and a
/// lower-case host, and anything else is returned trimmed so a validator can
/// reject it before it is saved.
String normalizeWebLink(String raw) =>
    parseWebLink(raw)?.toString() ?? raw.trim();
