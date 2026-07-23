# Dio Network Inspector

Plugin Flutter yang dapat dipasang sementara untuk memantau trafik API `Dio`. Integrasi inspector disimpan sebagai Git patch lokal sehingga tidak ikut ke commit aplikasi.

## Cara kerja

`inspector.patch` merekam tiga perubahan integrasi: dependency package, pemasangan `DioNetworkInterceptor`, dan `DioInspectorOverlay`. Perintah lokal `inspect-save`, `inspect-plug`, dan `inspect-unplug` menjalankan Git langsung; package ini tidak menyediakan CLI Dart.

## Implementasi pertama kali

Lakukan langkah berikut dari root proyek Flutter target.

1. Tambahkan package sementara ke `pubspec.yaml`:

   ```yaml
   dependencies:
     dio_network_inspector:
       git:
         url: https://github.com/affandilham/dio_network_inspector.git
         ref: v1.0.0
   ```

2. Jalankan `flutter pub get`, lalu pasang integrasi secara manual:

   - Tambahkan `DioNetworkInterceptor()` ke instance `Dio`.
   - Bungkus aplikasi dengan `DioInspectorOverlay`.

3. Konfigurasikan perintah lokal sesuai sistem operasi di bagian berikut.

4. Rekam patch. Sebaiknya sebutkan file integrasi agar perubahan pekerjaan lain tidak ikut:

   ```bash
   inspect-save pubspec.yaml lib/src/app/app.dart lib/src/app/resource/base_api.dart
   ```

5. Tambahkan `inspector.patch` ke `.gitignore` proyek target:

   ```gitignore
   # Local Dio Network Inspector integration
   inspector.patch
   ```

6. Cabut integrasi sebelum melakukan commit:

   ```bash
   inspect-unplug
   ```

> Penting: jangan melakukan `git add`, `git commit`, atau `git push` saat inspector masih terpasang. Setelah `inspect-unplug`, pastikan `git status` tidak memuat `pubspec.yaml`, file aplikasi, atau file API yang hanya berubah karena inspector.

## Konfigurasi perintah lokal

Tambahkan fungsi berikut satu kali pada konfigurasi shell pengguna. Ketiga perintah harus selalu dijalankan dari root proyek target, tempat `inspector.patch` berada.

### macOS (`zsh`) dan Linux (`bash`/`zsh`)

Tambahkan blok ini ke `~/.zshrc` (macOS atau Linux dengan zsh) atau `~/.bashrc` (Linux dengan bash), lalu buka terminal baru atau jalankan `source ~/.zshrc` / `source ~/.bashrc`.

```bash
inspect-save() {
  local tmp_patch

  tmp_patch=$(mktemp inspector.patch.XXXXXX) || return 1
  git diff -- "$@" > "$tmp_patch"

  if [[ ! -s "$tmp_patch" ]]; then
    rm "$tmp_patch"
    echo "Tidak ada perubahan untuk disimpan; inspector.patch lama tetap aman."
    return 1
  fi

  mv "$tmp_patch" inspector.patch
  echo "Patch tersimpan: inspector.patch"
}

inspect-plug() {
  git apply inspector.patch && flutter pub get
}

inspect-unplug() {
  git apply -R inspector.patch && flutter pub get
}
```

### Windows (PowerShell)

Jalankan `$PROFILE` untuk melihat lokasi file profil PowerShell. Buat file tersebut bila belum ada, lalu tambahkan blok berikut. Buka PowerShell baru atau jalankan `. $PROFILE` setelah menyimpannya.

```powershell
function inspect-save {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]] $Files)

  $patch = (& git diff -- $Files) -join [Environment]::NewLine
  if ([string]::IsNullOrWhiteSpace($patch)) {
    Write-Host 'Tidak ada perubahan untuk disimpan; inspector.patch lama tetap aman.'
    return
  }

  $path = Join-Path (Get-Location) 'inspector.patch'
  [System.IO.File]::WriteAllText(
    $path,
    $patch + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
  )
  Write-Host 'Patch tersimpan: inspector.patch'
}

function inspect-plug {
  git apply inspector.patch
  if ($LASTEXITCODE -eq 0) { flutter pub get }
}

function inspect-unplug {
  git apply -R inspector.patch
  if ($LASTEXITCODE -eq 0) { flutter pub get }
}
```

Jika PowerShell menolak menjalankan profil, jalankan PowerShell dengan hak pengguna biasa dan atur execution policy untuk pengguna saat ini:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Penggunaan sehari-hari

```bash
# Pasang integrasi untuk debugging lokal.
inspect-plug

# Cabut integrasi sebelum staging atau commit.
inspect-unplug
```

`inspect-save` tanpa argumen merekam seluruh perubahan yang belum di-stage, sama seperti `git diff`. Untuk menghindari perubahan lain ikut tersimpan, berikan path file yang ingin direkam:

```bash
inspect-save pubspec.yaml lib/src/app/app.dart lib/src/app/resource/base_api.dart
```

## Troubleshooting

Jika `inspect-plug` gagal dengan `patch does not apply`, konteks kode di sekitar titik integrasi telah berubah.

1. Tambahkan ulang integrasi secara manual.
2. Jalankan `inspect-save` dengan path file integrasi untuk memperbarui `inspector.patch`.
3. Jalankan `inspect-unplug` untuk membersihkan integrasi kembali.
