import 'package:flutter_test/flutter_test.dart';
import 'package:cnpj/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CnpjApp());
    expect(find.text('Consulta CNPJ'), findsOneWidget);
  });
}
