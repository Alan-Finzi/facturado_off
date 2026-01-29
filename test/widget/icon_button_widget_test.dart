import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:facturador_offline/widget/icon_button_widget.dart';
import 'package:facturador_offline/util/constants.dart';

void main() {
  group('IconButtonWidget', () {
    testWidgets('Renders correctly with default properties', (WidgetTester tester) async {
      // Setup
      bool tapped = false;

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButtonWidget(
                icon: Icons.add,
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify
      expect(find.byType(IconButtonWidget), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Test interaction
      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, isTrue);
    });

    testWidgets('Renders correctly when disabled', (WidgetTester tester) async {
      // Setup
      bool tapped = false;

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButtonWidget(
                icon: Icons.add,
                onPressed: () {
                  tapped = true;
                },
                disabled: true,
              ),
            ),
          ),
        ),
      );

      // Find the icon
      final iconFinder = find.byIcon(Icons.add);
      expect(iconFinder, findsOneWidget);

      // Try to tap and verify it doesn't respond
      await tester.tap(iconFinder);
      expect(tapped, isFalse);
    });

    testWidgets('Shows loading indicator when isLoading=true', (WidgetTester tester) async {
      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButtonWidget(
                icon: Icons.add,
                onPressed: () {},
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      // Verify loading indicator is visible and icon is not
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('passwordVisibility factory constructor changes icon based on visibility',
        (WidgetTester tester) async {
      // Test with password hidden
      bool passwordVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: IconButtonWidget.passwordVisibility(
                    isVisible: passwordVisible,
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state: password is hidden, so icon should be visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);

      // Tap to toggle
      await tester.tap(find.byType(IconButtonWidget));
      await tester.pump();

      // After tap: password is visible, icon should be visibility_outlined
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      // Tap again to toggle back
      await tester.tap(find.byType(IconButtonWidget));
      await tester.pump();

      // After second tap: password is hidden again, icon should be visibility_off_outlined
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('Uses orange color when visible and red color when hidden in passwordVisibility',
        (WidgetTester tester) async {
      // Setup a widget that allows us to check the icon color
      bool passwordVisible = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Center(
                  child: IconButtonWidget.passwordVisibility(
                    isVisible: passwordVisible,
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Find the icon
      final iconFinder = find.byIcon(Icons.visibility_off_outlined);
      expect(iconFinder, findsOneWidget);

      // Get the Icon widget to check its color
      final Icon icon = tester.widget<Icon>(iconFinder);
      // When hidden, should use primary color (red/magenta)
      expect(icon.color, Constants.miColor);

      // Tap to toggle
      await tester.tap(find.byType(IconButtonWidget));
      await tester.pump();

      // Find the new icon
      final visibleIconFinder = find.byIcon(Icons.visibility_outlined);
      expect(visibleIconFinder, findsOneWidget);

      // Get the Icon widget to check its color
      final Icon visibleIcon = tester.widget<Icon>(visibleIconFinder);
      // When visible, should use orange color
      expect(visibleIcon.color, Colors.orange);
    });
  });
}