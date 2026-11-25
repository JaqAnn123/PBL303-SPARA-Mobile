import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spara_mobile/pages/dasbor.dart';
import 'package:spara_mobile/services/api_client.dart';
import 'package:spara_mobile/services/spara_api.dart';

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

  testWidgets('profile shows contact info as read-only', (
    WidgetTester tester,
  ) async {
    await _openProfile(tester);

    expect(find.text('Profil Akun'), findsOneWidget);
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);
    expect(find.text('+62 812-3456-7890'), findsOneWidget);
    expect(find.text('rajivcream@gmail.com'), findsOneWidget);

    // Telepon & email tidak lagi bisa diubah dari aplikasi mobile.
    expect(find.byKey(const Key('profile-edit-phone')), findsNothing);
    expect(find.byKey(const Key('profile-edit-email')), findsNothing);
    // Kata sandi masih bisa diubah.
    expect(find.byKey(const Key('profile-edit-password')), findsOneWidget);
  });

  test('uploadProfilePhoto mengirim multipart dan mengembalikan foto baru', () async {
    final user = await SparaApi.instance.uploadProfilePhoto(
      bytes: const [1, 2, 3, 4],
      filename: 'foto.png',
    );

    expect(user.profilePicture, contains('/storage/profile_picture/'));
  });

  test('mediaUrl menyamakan host gambar dengan host API', () {
    final url = ApiClient.instance.mediaUrl(
      'http://127.0.0.1:8000/storage/profile_picture/test.png',
    );

    expect(url, isNotNull);
    expect(Uri.parse(url!).host, Uri.parse(ApiClient.baseUrl).host);
    expect(url, contains('/storage/profile_picture/test.png'));
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
