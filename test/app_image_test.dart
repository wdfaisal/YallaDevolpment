import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/config/env.dart';
import 'package:yalla_talabat_customer/core/widgets/app_image.dart';

void main() {
  group('AppImage', () {
    testWidgets('resolves backend-relative URLs against the API origin',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppImage(
            url: '/api/media/images/logo.png',
            width: 40,
            height: 40,
          ),
        ),
      );

      final image =
          tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
      expect(image.imageUrl, '${Env.apiBaseUrl}/api/media/images/logo.png');
    });

    testWidgets('shows the placeholder when the URL is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppImage(url: null, width: 40, height: 40),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    });
  });
}
