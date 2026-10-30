import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spara_mobile/pages/dasbor.dart';

import 'support/mock_api.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MaterialApp(home: DasborPage()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await setUpTestApi();
  });

  tearDown(tearDownTestApi);

  testWidgets('profile displays account details and updates phone via API', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    expect(find.text('Profil Akun'), findsOneWidget);
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);
    expect(find.text('+62 812-3456-7890'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('profile-edit-phone')));
    await tester.enterText(
      find.byType(TextFormField).first,
      '+62 811-2222-3333',
    );
    await tester.tap(find.text('SMS'));
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi Kode'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('+62 811-2222-3333'), findsOneWidget);
    expect(find.text('Nomor telepon berhasil diperbarui.'), findsOneWidget);
  });

  testWidgets('email update validates address and saves the new address', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await _tapVisible(tester, find.byKey(const Key('profile-edit-email')));
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    expect(find.text('Verifikasi Kode'), findsNothing);

    await tester.enterText(
      find.byType(TextFormField).first,
      'rajiv.new@example.com',
    );
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '987654');
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();

    expect(
      find.text('Email berhasil diperbarui.'),
      findsOneWidget,
    );
    expect(find.text('rajiv.new@example.com'), findsOneWidget);
    expect(find.text('rajivcream@gmail.com'), findsNothing);
  });

  testWidgets('password change checks required and matching new passwords', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await _tapVisible(tester, find.byKey(const Key('profile-edit-password')));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'current-secret');
    await tester.enterText(fields.at(1), 'new-secret-123');
    await tester.enterText(fields.at(2), 'different-secret');
    await tester.tap(find.text('Ganti'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);

    await tester.enterText(fields.at(2), 'new-secret-123');
    await tester.tap(find.text('Ganti'));
    await tester.pumpAndSettle();
    expect(find.text('Kata sandi berhasil diperbarui.'), findsOneWidget);
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);
  });

  testWidgets('logout requires confirmation and returns to login', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await _tapVisible(tester, find.byKey(const Key('profile-logout')));
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);

    await _tapVisible(tester, find.byKey(const Key('profile-logout')));
    await tester.tap(find.text('Ya, keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali!'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
