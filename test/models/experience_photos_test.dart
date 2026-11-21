import 'package:discoverease/models/business_profile.dart';
import 'package:discoverease/shared/utils/photo_files.dart';
import 'package:flutter_test/flutter_test.dart';

const _old1 = 'https://firebasestorage.googleapis.com/v0/b/b/o/public%2Fbiz%2Fexp%2Fa.jpg?alt=media';
const _old2 = 'https://firebasestorage.googleapis.com/v0/b/b/o/public%2Fbiz%2Fexp%2Fb.jpg?alt=media';
const _new1 = 'pending/biz/exp/c.png';

BusinessExperience _live({List<String> photos = const []}) => BusinessExperience(
  id: 'exp',
  title: 'Sunset Cruise',
  description: 'Evening boat tour.',
  category: 'Tours',
  subcategory: 'Boat',
  destinationId: 'nassau',
  destination: 'Nassau',
  location: 'Paradise Island',
  price: r'$$',
  imageUrl: photos.isEmpty ? '' : photos.first,
  status: 'published',
  photos: photos,
);

ExperienceRevision _withPhotos(BusinessExperience live, List<String> photos) {
  final base = ExperienceRevision.fromExperience(live);
  return ExperienceRevision(
    title: base.title,
    description: base.description,
    category: base.category,
    subcategory: base.subcategory,
    destinationId: base.destinationId,
    destination: base.destination,
    location: base.location,
    price: base.price,
    imageUrl: base.imageUrl,
    photos: photos,
  );
}

void main() {
  group('photo lists on experiences', () {
    test('survive a round trip and default to none for older records', () {
      final live = _live(photos: [_old1, _old2]);
      expect(BusinessExperience.fromJson(live.toJson()).photos, [_old1, _old2]);
      final older = BusinessExperience.fromJson({
        'id': 'x',
        'title': 'T',
        'category': 'Tours',
        'destinationId': 'nassau',
        'destination': 'Nassau',
      });
      expect(older.photos, isEmpty);
    });

    test('ignore anything in the list that is not text', () {
      final parsed = BusinessExperience.fromJson({
        'id': 'x',
        'title': 'T',
        'category': 'Tours',
        'destinationId': 'nassau',
        'destination': 'Nassau',
        'photos': [_old1, 5, null],
      });
      expect(parsed.photos, [_old1]);
    });
  });

  group('photo changes in a revision', () {
    test('adding a photo is a change a reviewer sees', () {
      final live = _live(photos: [_old1]);
      final changes = _withPhotos(live, [_old1, _new1]).changesFrom(live);
      expect(changes.map((c) => c.label), ['Photos']);
      expect(changes.single.before, '1 photo');
      expect(changes.single.after, '2 photos (1 new)');
    });

    test('removing a photo is a change', () {
      final live = _live(photos: [_old1, _old2]);
      final changes = _withPhotos(live, [_old1]).changesFrom(live);
      expect(changes.single.after, '1 photo');
    });

    test('only changing the cover is not a change that needs review', () {
      final live = _live(photos: [_old1, _old2]);
      expect(_withPhotos(live, [_old2, _old1]).changesFrom(live), isEmpty);
    });

    test('a revision remembers its photos in order', () {
      final live = _live(photos: [_old1]);
      final stored = _withPhotos(live, [_new1, _old1]).toJson();
      expect(ExperienceRevision.fromJson(stored).photos, [_new1, _old1]);
    });
  });

  group('photo file helpers', () {
    test('accept only JPEG, PNG and WebP, in any letter case', () {
      expect(photoExtension('beach.JPG'), 'jpg');
      expect(photoExtension('beach.jpeg'), 'jpg');
      expect(photoExtension('a.b.png'), 'png');
      expect(photoExtension('x.webp'), 'webp');
      for (final bad in ['x.gif', 'x.heic', 'x', 'x.', '.', 'x.png.exe', '']) {
        expect(photoExtension(bad), isNull, reason: bad);
      }
    });

    test('map each type to its content type', () {
      expect(photoContentType('png'), 'image/png');
      expect(photoContentType('webp'), 'image/webp');
      expect(photoContentType('jpg'), 'image/jpeg');
    });

    test('new file names are safe, typed and never repeat', () {
      final names = {for (var i = 0; i < 50; i++) newPhotoFileName('png')};
      expect(names.length, 50);
      for (final name in names) {
        expect(RegExp(r'^[A-Za-z0-9_-]{1,80}\.png$').hasMatch(name), isTrue, reason: name);
      }
    });

    test('tell pending uploads from approved photos', () {
      expect(isPendingPhoto(_new1), isTrue);
      expect(isPendingPhoto(_old1), isFalse);
    });

    test('compare photo lists by set and by order', () {
      expect(samePhotoSet(['a', 'b'], ['b', 'a']), isTrue);
      expect(samePhotoSet(['a'], ['a', 'b']), isFalse);
      expect(samePhotoOrder(['a', 'b'], ['b', 'a']), isFalse);
      expect(samePhotoOrder(['a', 'b'], ['a', 'b']), isTrue);
    });
  });
}
