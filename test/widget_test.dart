import 'package:flutter_test/flutter_test.dart';
import 'package:product_store/main.dart';

void main() {
  testWidgets('Product Store app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProductStoreApp());

    expect(find.text('Product Store'), findsOneWidget);
  });
}
