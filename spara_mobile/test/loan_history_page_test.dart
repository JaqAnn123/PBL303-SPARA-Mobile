import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spara_mobile/pages/riwayat.dart';

import 'support/mock_api.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() async {
    await setUpTestApi();
  });

  tearDown(tearDownTestApi);

  testWidgets('history layout fits a compact phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoanHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kamera Sony A6400'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history filters and searches local loan records', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoanHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kamera Sony A6400'), findsOneWidget);
    expect(find.text('Ruang Seminar R.302'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Proyektor Epson EB-X06'));
    expect(find.text('Proyektor Epson EB-X06'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Disetujui'));
    await tester.pumpAndSettle();
    expect(find.text('Ruang Seminar R.302'), findsOneWidget);
    expect(find.text('Kamera Sony A6400'), findsNothing);

    await tester.enterText(find.byType(TextField), 'REQ-2026-007');
    await tester.pumpAndSettle();
    expect(find.text('Tripod Kamera'), findsOneWidget);
    expect(find.text('Ruang Seminar R.302'), findsNothing);
  });

  testWidgets('history cancellation asks for confirmation', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoanHistoryPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cancel-REQ-2026-011')));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan pengajuan?'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Kamera Sony A6400'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cancel-REQ-2026-011')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, batalkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan REQ-2026-011 dibatalkan.'), findsOneWidget);
    await tester.tap(find.text('Menunggu').first);
    await tester.pumpAndSettle();
    expect(find.text('Kamera Sony A6400'), findsNothing);
  });

  testWidgets('approved loan opens a letter preview', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoanHistoryPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Disetujui'));
    await tester.pumpAndSettle();
    final letterButton = find.byKey(const ValueKey('letter-REQ-2026-010'));
    await tester.tap(letterButton);
    await tester.pumpAndSettle();
    expect(find.text('Preview Surat Izin'), findsOneWidget);
    expect(find.text('SURAT IZIN PEMINJAMAN'), findsOneWidget);
    expect(find.text('Download PDF'), findsOneWidget);
  });

  testWidgets('history pagination changes the visible records', (
    WidgetTester tester,
  ) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(const MaterialApp(home: LoanHistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('Kamera Sony A6400'), findsOneWidget);
    expect(find.text('Tripod Kamera'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('history-page-2')));
    await tester.pumpAndSettle();
    expect(find.text('Tripod Kamera'), findsOneWidget);
    expect(find.text('Kamera Sony A6400'), findsNothing);
  });
}
