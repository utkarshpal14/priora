import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/dashboard/presentation/screens/placeholder_screen.dart';

void main() {
  testWidgets('PlaceholderScreen renders setup completion information', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceholderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that the brand name and milestone status appear
    expect(find.text('Priora'), findsOneWidget);
    expect(find.text('Milestone 0 Setup Complete'), findsOneWidget);
    expect(find.text('Plan. Prioritize. Progress.'), findsOneWidget);
  });
}
