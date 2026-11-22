import 'package:discoverease/features/main_shell/main_shell_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opening Explore remembers what to show and tells the shell', () {
    final controller = MainShellController();
    var notified = 0;
    controller.addListener(() => notified++);
    controller.openExplore(category: 'Tour');
    expect(controller.category, 'Tour');
    expect(controller.areaId, isNull);
    expect(controller.requestId, 1);
    controller.openExplore(areaId: 'downtown-nassau');
    expect(controller.category, isNull);
    expect(controller.areaId, 'downtown-nassau');
    expect(controller.requestId, 2);
    expect(notified, 2);
  });

  test('clearing forgets the request without announcing anything', () {
    final controller = MainShellController();
    controller.openExplore(category: 'Tour', filter: '🏖 Beach');
    var notified = 0;
    controller.addListener(() => notified++);
    controller.clear();
    expect(controller.category, isNull);
    expect(controller.filter, isNull);
    expect(notified, 0);
  });
}
