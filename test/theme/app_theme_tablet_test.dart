import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminary_sidekick/theme/app_theme.dart';

void main() {
  Future<bool> evaluate(WidgetTester tester, Size size) async {
    late bool result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            result = AppTheme.isTabletLandscape(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('landscape + shortestSide >= 840 → true', (tester) async {
    // iPad 13″ landscape-ish: width > height, shortest side ≥ 840
    expect(await evaluate(tester, const Size(1366, 1024)), isTrue);
  });

  testWidgets('portrait + large shortest side → false', (tester) async {
    // Same device upright — phone layouts until portrait tablet is designed
    expect(await evaluate(tester, const Size(1024, 1366)), isFalse);
  });

  testWidgets('landscape + phone shortest side → false', (tester) async {
    expect(await evaluate(tester, const Size(900, 400)), isFalse);
  });
}
