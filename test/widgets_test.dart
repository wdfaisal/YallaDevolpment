import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/widgets/app_scaffold.dart';
import 'package:yalla_talabat_customer/core/widgets/states.dart';
import 'package:yalla_talabat_customer/presentation/shared/headers.dart';

import 'support/test_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders title, message and runs the action', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        testApp(
          EmptyState(
            title: 'Nothing here',
            message: 'Add something first',
            actionLabel: 'Add',
            onAction: () => tapped++,
          ),
        ),
      );

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.text('Add something first'), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(tapped, 1);
    });
  });

  group('ErrorState', () {
    testWidgets('shows the message and retries', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        testApp(
          ErrorState(message: 'Network down', onRetry: () => retried++),
        ),
      );

      expect(find.text('Network down'), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      expect(retried, 1);
    });
  });

  group('AsyncView', () {
    testWidgets('renders data', (tester) async {
      await tester.pumpWidget(
        testApp(
          AsyncView<int>(
            value: const AsyncValue.data(7),
            builder: (value) => Text('value=$value'),
          ),
        ),
      );
      expect(find.text('value=7'), findsOneWidget);
    });

    testWidgets('renders a spinner while loading', (tester) async {
      await tester.pumpWidget(
        testApp(
          AsyncView<int>(
            value: const AsyncValue.loading(),
            builder: (value) => Text('value=$value'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders an error with retry', (tester) async {
      await tester.pumpWidget(
        testApp(
          AsyncView<int>(
            value: AsyncValue.error(Exception('boom'), StackTrace.empty),
            builder: (value) => Text('value=$value'),
          ),
        ),
      );
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });

  group('AppScaffold', () {
    testWidgets('honours top and bottom safe areas', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          const AppScaffold(
            header: SimpleHeader(title: 'Header', showBack: false),
            body: Text('Body'),
            bottomBar: SizedBox(height: 60, child: Text('Bar')),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Bar'), findsOneWidget);

      final headerTop = tester.getTopLeft(find.text('Header')).dy;
      expect(headerTop, greaterThanOrEqualTo(44));

      final barBottom = tester.getBottomLeft(find.text('Bar')).dy;
      expect(barBottom, lessThanOrEqualTo(844 - 34));
    });
  });
}
