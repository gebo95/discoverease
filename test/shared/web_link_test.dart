import 'package:discoverease/shared/utils/web_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('web links', () {
    test('accepts http and https addresses and adds https when missing', () {
      expect(isValidWebLink('https://example.com'), isTrue);
      expect(isValidWebLink('http://example.com/menu?lang=en'), isTrue);
      expect(isValidWebLink('example.com'), isTrue);
      expect(normalizeWebLink('  example.com/book  '), 'https://example.com/book');
      expect(normalizeWebLink('HTTPS://Example.COM/Path'), 'https://example.com/Path');
    });

    test('rejects unsafe, malformed, or non-web addresses', () {
      for (final bad in [
        'javascript:alert(1)',
        'javascript://example.com/%0aalert(1)',
        'ftp://example.com',
        'mailto:hello@example.com',
        'https://google.com@evil.example.com',
        'not a link',
        'https://',
        'https://localhost',
        'https://.example.com',
      ]) {
        expect(isValidWebLink(bad), isFalse, reason: bad);
      }
    });

    test('empty input stays empty and is not treated as a link', () {
      expect(normalizeWebLink('   '), '');
      expect(parseWebLink(''), isNull);
    });
  });
}
