import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ali/main.dart';

void main() {
  testWidgets('adding a product shows it in the cart total', (tester) async {
    await tester.pumpWidget(const AliApp());

    // Botão "adicionar" do primeiro card de produto.
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(find.text('1'), findsWidgets); // badge da cesta
  });
}
