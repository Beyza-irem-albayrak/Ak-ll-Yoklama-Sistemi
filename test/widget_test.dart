import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_qryoklamasistemi/pages/student_login.dart';
import 'package:flutter_qryoklamasistemi/pages/lecturer_login.dart';

void main() {
  testWidgets('Öğrenci giriş ekranı yükleniyor mu?', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StudentLoginPage(),
    ));

    // En az 2 textfield ve bir giriş butonu var mı
    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('Öğretmen giriş ekranı yükleniyor mu?', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LecturerLoginPage(),
    ));

    // En az 2 textfield ve bir giriş butonu var mı
    expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
