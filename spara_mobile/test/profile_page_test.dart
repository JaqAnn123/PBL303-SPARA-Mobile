import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spara_mobile/pages/dasbor.dart';

Future<void> _openProfile(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: DasborPage()));
  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('profile displays account details and updates phone locally', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    expect(find.text('Profil Akun'), findsOneWidget);
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);
    expect(find.text('+62 812-3456-7890'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-edit-phone')));
    await tester.pumpAndSettle();
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
    expect(
      find.textContaining('Perubahan tersimpan di pratinjau lokal'),
      findsOneWidget,
    );
  });

  testWidgets('email update validates address and completes local code flow', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-edit-email')));
    await tester.pumpAndSettle();
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

    expect(find.text('rajiv.new@example.com'), findsOneWidget);
  });

  testWidgets('password change checks required and matching new passwords', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-edit-password')));
    await tester.pumpAndSettle();
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
    expect(
      find.text('Alur ubah kata sandi selesai di pratinjau frontend.'),
      findsOneWidget,
    );
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);
  });

  testWidgets('logout requires confirmation and returns to login', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pumpAndSettle();
    expect(
      find.text('Apakah anda yakin ingin keluar dari akun?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali!'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
