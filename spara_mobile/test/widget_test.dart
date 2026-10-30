import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spara_mobile/pages/dasbor.dart';
import 'package:spara_mobile/pages/login.dart';
import 'package:spara_mobile/pages/register.dart';

import 'support/mock_api.dart';

void main() {
  setUp(() async {
    await setUpTestApi();
  });

  tearDown(tearDownTestApi);

  testWidgets('login requires both fields before opening the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk ke Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Isi data terlebih dahulu!'), findsNWidgets(2));
    expect(find.text('Mau pinjam apa hari ini?'), findsNothing);
  });

  testWidgets('registration requires all first-page fields before continuing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Halaman 1 dari 2'), findsOneWidget);
    expect(find.text('Isi data terlebih dahulu!'), findsNWidgets(5));
  });

  testWidgets(
    'registration requires all second-page fields before submitting',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Nama Tes');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'tes@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), '08123456789');

      final departmentDropdown = find
          .byType(DropdownButtonFormField<String>)
          .first;
      await tester.ensureVisible(departmentDropdown);
      await tester.tap(departmentDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teknik Informatika').last);
      await tester.pumpAndSettle();

      final programDropdown = find.byType(DropdownButtonFormField<String>).last;
      await tester.ensureVisible(programDropdown);
      await tester.tap(programDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('D3 Teknik Informatika').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2 dari 2'), findsOneWidget);
      expect(
        find.text('Are you sure the information has been entered correctly?'),
        findsNothing,
      );

      await tester.tap(find.text('Daftar akun'));
      await tester.pumpAndSettle();

      expect(find.text('Isi data terlebih dahulu!'), findsNWidgets(3));
      expect(find.text('Halaman 2 dari 2'), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsNothing);
    },
  );

  testWidgets('registration asks for confirmation before opening login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Nama Tes');
    await tester.enterText(find.byType(TextFormField).at(1), 'tes@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '08123456789');

    final departmentDropdown = find
        .byType(DropdownButtonFormField<String>)
        .first;
    await tester.ensureVisible(departmentDropdown);
    await tester.tap(departmentDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teknik Informatika').last);
    await tester.pumpAndSettle();

    final programDropdown = find.byType(DropdownButtonFormField<String>).last;
    await tester.ensureVisible(programDropdown);
    await tester.tap(programDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('D3 Teknik Informatika').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '123456789');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret123');

    await tester.tap(find.text('Daftar akun'));
    await tester.pumpAndSettle();
    expect(
      find.text('Apakah anda yakin data yang dimasukkan sudah benar?'),
      findsOneWidget,
    );
    expect(find.text('Masuk ke Akun'), findsNothing);

    await tester.tap(find.text('Periksa Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Halaman 2 dari 2'), findsOneWidget);
    expect(
      find.text('Apakah anda yakin data yang dimasukkan sudah benar?'),
      findsNothing,
    );

    await tester.tap(find.text('Daftar akun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, benar'));
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang kembali!'), findsOneWidget);
  });

  testWidgets('bottom navigation opens the matching page for each tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DasborPage()));

    final bottomNav = find.byType(BottomNavigationBar);
    expect(tester.widget<BottomNavigationBar>(bottomNav).currentIndex, 0);
    expect(find.text('Mau pinjam apa hari ini?'), findsOneWidget);

    await tester.tap(find.text('Pencarian'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(bottomNav).currentIndex, 1);
    expect(
      find.text('Temukan ruangan dan peralatan yang kamu butuhkan'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Proyektor');
    await tester.pumpAndSettle();
    expect(find.textContaining('Proyektor Epson 4K'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(bottomNav).currentIndex, 2);
    expect(find.text('Riwayat Peminjaman'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(bottomNav).currentIndex, 3);
    expect(find.text('Rajiv Tajusa David'), findsOneWidget);

    await tester.tap(find.text('Dasbor'));
    await tester.pumpAndSettle();
    expect(tester.widget<BottomNavigationBar>(bottomNav).currentIndex, 0);
    expect(find.text('Mau pinjam apa hari ini?'), findsOneWidget);
  });

  testWidgets('search result opens the facility detail page and loan form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DasborPage()));
    await tester.tap(find.text('Pencarian'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-facility-AL01')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Fasilitas'), findsOneWidget);
    expect(find.text('Kode AL01'), findsOneWidget);
    expect(
      find.text(
        'Pengajuan peminjaman akan dikirim ke admin/PIC untuk ditinjau '
        'sebelum disetujui.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('facility-detail-borrow')));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pengajuan'), findsOneWidget);
    expect(find.text('Nama Kegiatan'), findsOneWidget);
    expect(find.text('Penanggung Jawab'), findsOneWidget);
    expect(find.text('Keterangan'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Detail Fasilitas'), findsOneWidget);
  });

  testWidgets('loan request is confirmed, submitted and returns to dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> tapKey(Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(const MaterialApp(home: DasborPage()));
    await tester.tap(find.text('Pencarian'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-facility-RG-101')));
    await tester.pumpAndSettle();
    await tapKey(const ValueKey('facility-detail-borrow'));

    await tester.enterText(
      find.byKey(const ValueKey('booking-name')),
      'Rapat Himpunan',
    );

    await tapKey(const ValueKey('booking-date'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tapKey(const ValueKey('booking-start-time'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tapKey(const ValueKey('booking-end-time'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tapKey(const ValueKey('booking-submit'));

    expect(find.text('Konfirmasi Pengajuan'), findsOneWidget);
    expect(find.text('Rapat Himpunan'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('booking-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Pengajuan berhasil diajukan!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('booking-success-back')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
    expect(
      find.text('Pengajuan Workspace Virtual Reality berhasil dikirim.'),
      findsOneWidget,
    );
  });

  testWidgets('back from a secondary tab returns to the dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DasborPage()));

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
    expect(find.text('Mau pinjam apa hari ini?'), findsOneWidget);
  });

  testWidgets(
    'recommendation pagination has working previous and next buttons',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DasborPage()));
      await tester.pumpAndSettle();

      const selectedPageColor = Color(0xFFFFC107);

      Color pageColor(int page) {
        final pageButton = tester.widget<AnimatedContainer>(
          find.byKey(ValueKey('recommendation-page-$page')),
        );
        return (pageButton.decoration! as BoxDecoration).color!;
      }

      Future<void> tapControl(Key key) async {
        await tester.ensureVisible(find.byKey(key));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
      }

      expect(pageColor(1), selectedPageColor);
      await tapControl(const ValueKey('recommendation-page-2'));
      expect(pageColor(2), selectedPageColor);

      await tapControl(const ValueKey('recommendation-previous'));
      expect(pageColor(1), selectedPageColor);

      await tapControl(const ValueKey('recommendation-next'));
      expect(pageColor(2), selectedPageColor);
    },
  );

  testWidgets('dashboard layout fits a narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(240, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DasborPage()));
    await tester.pumpAndSettle();

    expect(find.text('Informasi Peminjaman Saya'), findsOneWidget);
    expect(find.text('Rekomendasi Kilat'), findsOneWidget);
    expect(find.text('Workspace Virtual Reality'), findsWidgets);
    expect(tester.takeException(), isNull);

    final recommendationRect = tester.getRect(
      find.byKey(const ValueKey('recommendation-panel')),
    );
    expect(recommendationRect.left, 0);
    expect(recommendationRect.right, 240);
    expect(find.byType(CustomScrollView), findsOneWidget);

    final loanCardHeading = find.text('Informasi Peminjaman Saya');
    final loanCardTopBeforeScroll = tester.getTopLeft(loanCardHeading).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(loanCardHeading).dy,
      lessThan(loanCardTopBeforeScroll),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('recommendation-next')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recommendation-next')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('recommendation-previous')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('recommendation-previous')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('facility detail and loan form fit a compact phone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DasborPage()));
    await tester.tap(find.text('Pencarian'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-facility-RG-101')));
    await tester.pumpAndSettle();
    expect(find.text('Detail Fasilitas'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('facility-detail-borrow')));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pengajuan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
