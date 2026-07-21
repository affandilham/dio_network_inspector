# Dio Network Inspector

Plugin lokal *pluggable* untuk memantau lalu lintas API pada aplikasi Flutter Anda. Plugin ini dirancang untuk dapat "dicolok-cabut" (*plug and play*) tanpa perlu menyampah di riwayat commit Git utama Anda, dan dapat digunakan di berbagai macam proyek.

## Fitur CLI (Command Line Interface)

Plugin ini dilengkapi dengan *executable* CLI bawaan berbasis Dart untuk mengatur pemasangan dan pencabutan plugin dengan mudah menggunakan fitur Git Patch.

## Cara Penggunaan (Implementasi Pertama Kali)

Jika Anda ingin menggunakan plugin ini di dalam proyek Flutter yang baru (misalnya bukan Voltunes):

1. **Tambahkan Dependensi**
   Tambahkan plugin ini ke `pubspec.yaml` proyek Anda. Jika Anda mengambil dari GitHub:
   ```yaml
   dev_dependencies:
     dio_network_inspector:
       git: https://github.com/affandilham/dio_network_inspector.git
   ```

2. **Pasang Plugin Secara Manual (Satu Kali Saja)**
   Ubah kode di proyek Anda secara manual.
   * Hubungkan `DioNetworkInterceptor` pada instance `Dio` Anda.
   * Bungkus widget `MaterialApp` Anda dengan `DioInspectorOverlay(navigatorKey: ..., child: ...)`

3. **Rekam Patch (SAVE)**
   Sebelum Anda melakukan `git add` atau `git commit`, rekam perubahan kode manual tersebut dengan menjalankan perintah CLI berikut di terminal proyek Anda:
   ```bash
   dart run dio_network_inspector save
   ```
   *(Efek: Sebuah file `inspector.patch` akan dibuat di root proyek Anda. File ini berisi rekaman lokasi di mana Anda menyisipkan kode plugin tadi).*
   
   **Tips**: Jika kebetulan Anda memiliki file lain yang sedang Anda ubah (uncommitted changes) yang tidak ingin ikut terekam ke dalam patch, Anda bisa menyebutkan nama-nama file plugin secara spesifik:
   ```bash
   dart run dio_network_inspector save pubspec.yaml lib/src/app/app.dart lib/src/app/resource/base_api.dart
   ```

4. **Kembalikan Kode Seperti Semula (UNPLUG)**
   Karena patch-nya sudah tersimpan, cabut sisipan manual tadi agar *repository* Anda bersih kembali:
   ```bash
   dart run dio_network_inspector unplug
   ```

## Cara Penggunaan Sehari-Hari

Setelah langkah instalasi di atas dilakukan dan `inspector.patch` sudah tercipta, teman-teman tim Anda (atau Anda sendiri) bisa menggunakan workflow ini dengan instan:

### 1. Memasang Plugin (PLUG)
Gunakan ini saat Anda ingin melakukan *debugging* memantau API secara lokal. Jalankan di root proyek aplikasi Flutter Anda:
```bash
dart run dio_network_inspector plug
```
*(Efek: Patch akan diaplikasikan. Sebuah tombol melayang Inspector akan muncul di layar aplikasi Anda).*

### 2. Mencabut Plugin (UNPLUG)
Gunakan ini saat *debugging* selesai, atau **SANGAT PENTING: Sebelum Anda melakukan `git add`, `git commit`, atau `git push`** di proyek utama. 
```bash
dart run dio_network_inspector unplug
```
*(Efek: Seluruh jejak kode sisipan plugin akan dihapus bersih).*

---

## Troubleshooting: Patch Gagal Diterapkan

Sewaktu-waktu, saat menjalankan `plug`, Git bisa saja menolak dengan pesan *`patch does not apply`*. 

### Kenapa Ini Bisa Terjadi?
Sistem *patch* Git bekerja dengan mencari "Konteks" baris kode (bukan hanya nomor baris). Jika Anda melakukan perubahan/refaktor kode **tepat di sekitar tempat kode plugin tersebut bersandar**, Git akan kebingungan karena lingkungan baris kodenya sudah berubah. 

### Cara Memperbaikinya (Regenerate Patch)
1. **Pasang Manual**: Tambahkan kembali kode sisipan plugin secara manual ke proyek Anda seperti tahap "Implementasi Pertama Kali".
2. **Perbarui Patch**: Jalankan `dart run dio_network_inspector save`. File `inspector.patch` akan diperbarui sesuai konteks kode terbaru Anda.
3. **Cabut Kembali**: Jalankan `dart run dio_network_inspector unplug` untuk membersihkan kode. Semua kembali berjalan normal!
