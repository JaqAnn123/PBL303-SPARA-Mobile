# PBL303-SPARA-Mobile

Aplikasi mobile Flutter untuk sistem peminjaman ruangan & peralatan SPARA.
Backend Laravel berada di folder `2A-Pagi-2026-Web-SPARA/backend`.

## Menjalankan

1. Nyalakan MySQL, lalu jalankan backend:

   ```powershell
   cd 2A-Pagi-2026-Web-SPARA/backend
   php artisan serve --host=127.0.0.1 --port=8000
   ```

2. Jalankan aplikasi:

   ```powershell
   cd spara_mobile
   flutter run
   ```

   Alamat API otomatis menyesuaikan platform:

   - Android emulator: `http://10.0.2.2:8000/api/`
   - Web/desktop: `http://127.0.0.1:8000/api/`

   Untuk HP fisik, pakai IP komputer di jaringan yang sama:

   ```powershell
   flutter run --dart-define=SPARA_API_BASE_URL=http://192.168.1.10:8000/api/
   ```

Akun demo:

| Peran | ID Number | Password |
| --- | --- | --- |
| Admin | `10000001` | `password` |
| Mahasiswa | `2021101001` | `password` |

## Notifikasi HP

Notifikasi status peminjaman diambil dari endpoint `/notifications` setiap
15 detik (sama seperti halaman web) lalu ditampilkan sebagai notifikasi Android
lewat `flutter_local_notifications`. Tidak perlu Firebase/FCM.

Cara mengecek:

1. Login sebagai mahasiswa (`2021101001`), lalu izinkan notifikasi saat diminta
   (Android 13+).
2. Buat pengajuan peminjaman dari aplikasi.
3. Setujui/tolak pengajuan tersebut dari web sebagai admin/PIC, **atau** suntik
   notifikasi percobaan lewat tinker:

   ```powershell
   cd 2A-Pagi-2026-Web-SPARA/backend
   php artisan tinker
   ```

   ```php
   App\Models\Notification::create([
       'id_number' => '2021101001',
       'type' => 'disetujui',
       'judul' => 'Peminjaman Disetujui',
       'pesan' => 'Peminjaman Ruang Seminar R.302 telah disetujui.',
       'peminjaman_id' => null,
       'read_at' => null,
   ]);
   ```

4. Tunggu maksimal 15 detik. Notifikasi muncul di status bar dan badge lonceng
   di dasbor bertambah. Mengetuk notifikasi membuka daftar notifikasi.

Batasan: notifikasi hanya berjalan selama proses aplikasi masih hidup
(foreground maupun background). Jika aplikasi dimatikan total, notifikasi tidak
muncul. Untuk notifikasi saat aplikasi tertutup, perlu migrasi ke Firebase Cloud
Messaging (FCM) dengan `google-services.json` dan service account Firebase.

## Pengujian

```powershell
cd spara_mobile
flutter analyze
flutter test
```
