# MySQL Database Inspector

## Status

**Implementasi awal tersedia.** Koneksi MySQL tetap opt-in dan tidak dibuat
sampai user menekan **Connect**. Hanya backlog yang belum memiliki kode dan
verifikasi yang sesuai yang ditandai TODO.

## Checklist implementasi

Centang item hanya setelah kode, test yang relevan, dan verifikasi manualnya
selesai.

- [x] Dokumentasikan requirement, batas keamanan, dan target penggunaan RAM.
- [x] Implementasi awal: konfigurasi in-memory, koneksi lazy, daftar tabel,
  row ber-pagination, refresh/disconnect, dan query read-only tunggal.
- [x] Guard query: satu statement, pembatas hasil SELECT, serta blokir operasi
  tulis, transaction, lock, dan file output.
- [x] **Fondasi MySQL:** konfigurasi host, interface client, model data,
  dan implementasi koneksi lazy dengan SSL.
- [x] **Database panel:** status koneksi, daftar tabel, pencarian tabel lokal
  case-insensitive berbasis potongan nama (`dings` menemukan
  `report_recordings`), data tabel, paging, refresh manual, dan disconnect.
- [x] **Metadata ENUM:** nilai valid dibaca dari schema dan ditampilkan sebagai
  dropdown inspeksi langsung pada cell, termasuk opsi `NULL` bila diizinkan.
- [x] **Metadata kolom lanjutan:** tipe data tersedia saat hover header agar
  tabel tetap ringkas; kolom foreign key diberi ikon kunci gold dan nilai
  kolom MySQL `JSON` dapat dibuka sebagai preview terformat read-only.
- [x] **Autocomplete dasar:** keyword MySQL, tabel sesi aktif, dan seluruh
  metadata kolom schema yang dimuat sekali ketika koneksi dibuka. Kolom hanya
  disarankan setelah tabel valid dipilih melalui `FROM` atau `JOIN`, tanpa
  batas jumlah saran; daftar muncul sebagai popup yang dapat di-scroll dan
  tidak mengurangi tinggi hasil query. Gunakan `↑`/`↓` untuk memindahkan pilihan,
  `Enter` atau `Tab` untuk memasukkan suggestion, serta `Esc` untuk menutupnya.
  `Shift` + `Enter` menambah baris baru tanpa memilih suggestion. `Ctrl` +
  `Enter` menjalankan active statement yang valid dan tidak memilih suggestion.
  Kolom tanpa alias dibatasi ke tabel utama setelah `FROM`; gunakan alias
  eksplisit untuk tabel `JOIN`.
- [x] **SQL editor lanjutan:** syntax highlighting, katalog kolom penuh,
  serta autocomplete alias dan CTE pada statement aktif.
  - [x] **Syntax highlighting read-only:** keyword SQL, string, angka,
    komentar, dan quoted identifier diberi warna tanpa mengubah query atau
    memengaruhi validasi/execution. Highlight active statement serta error line
    tetap diprioritaskan sebagai background.
  - [x] **Highlight Active Statement:** cursor menentukan satu statement yang
    diberi highlight dan menjadi satu-satunya kandidat **Run**. Pemisah `;`
    penutup ikut diberi highlight, sedangkan `;` di dalam string, quoted
    identifier, atau komentar diabaikan. Caret tepat setelah `;` tetap
    menggunakan statement sebelumnya; blank line setelahnya tidak aktif.
  - [x] **Nomor baris dan lokasi error:** editor menampilkan gutter nomor
    baris yang ikut bergulir bersama teks. Pesan MySQL berbentuk `at line N`
    dihitung relatif terhadap statement aktif yang dikirim, lalu dipetakan ke
    nomor serta isi baris editor yang benar secara merah. Lokasi tidak berubah
    walaupun cursor dipindah setelah query dijalankan.
  - [x] **Alias dan CTE:** autocomplete membaca alias `FROM`/`JOIN`, nama CTE,
    kolom hasil `SELECT` CTE, dan daftar nama output CTE eksplisit. Saran hanya
    memakai statement di posisi cursor agar alias dari query lain tidak bocor.
- [x] **Query tabs dasar:** buat, pindah, dan tutup tab tanpa batas lisensi;
  draft serta satu halaman hasil per tab memakai satu koneksi bersama.
- [x] **Query tabs lanjutan:**
  - [x] Ganti nama tab melalui double-click pada tab.
  - [x] **Restore lintas sesi:** hingga 20 nama tab, draft SQL, dan tab aktif
    dipulihkan secara lokal per database/environment setelah Connect. Hasil
    query, kredensial, dan koneksi tidak pernah dipulihkan.
  - [x] Konfirmasi sebelum menutup tab yang memiliki draft SQL.
  - [x] Opsi global **Release inactive query results** tersedia di Inspector
    settings. Saat diaktifkan, hasil tab tidak aktif dilepas untuk menghemat
    RAM; draft tetap tersimpan dan tab menampilkan penanda untuk menjalankan
    ulang query. Secara default opsi ini nonaktif.
- [x] **Hardening integration test:** suite MySQL hanya berjalan bila user
  memasang `MYSQL_INSPECTOR_INTEGRATION=1` dan mengisi fixture lokal eksplisit.
  Test menolak host selain `localhost`/`127.0.0.1`/`::1` serta environment
  `production` sebelum membuka socket. Ia memverifikasi connect, baca metadata,
  dan query `SELECT` read-only; database Voltunes production tidak pernah
  dijadikan fixture otomatis.

### Backlog setelah versi 1

- [x] **Saved query lokal/privat:** hingga 50 query read-only bernama per
  database/environment disimpan pada perangkat. Memilihnya mengikuti posisi
  fokus dan tidak mengganti draft; SQL yang dimasukkan selalu memiliki penutup
  statement `;` tanpa menggandakan delimiter yang sudah ada.
  - [x] Folder opsional mengelompokkan query tersimpan secara lokal. Memilih
    query tetap hanya memasukkan SQL ke tab aktif tanpa menjalankannya otomatis.
- [x] **Foreign-key navigation:** kolom foreign key pada hasil browse tabel
  dan query result memiliki aksi Inspect related data yang menyiapkan query
  `SELECT` aman pada tab baru dan langsung menjalankannya. Pada result
  `JOIN`, aksi hanya muncul bila nama kolom FK tidak ambigu. Schema tanpa
  constraint FK juga didukung secara konservatif untuk kolom `*_id` jika hanya
  ada satu kandidat tabel (`kandang_id` → `kandangs`). Beberapa source column
  bernama sama tetap didukung bila semuanya menunjuk ke target yang sama.
  - [x] Navigasi balik dari tabel referensi tersedia untuk satu relasi yang
    tidak ambigu.
  - [x] **Relasi komposit:** navigasi memakai seluruh pasangan kolom dalam
    constraint foreign key yang sama, sehingga query target selalu memakai
    predicate `AND` lengkap dan tidak dapat membuka row yang salah.
- [x] **Structure read-only:** switch **Data / Structure** untuk tabel yang
  sedang dibuka. Columns, Indexes, Triggers, dan DDL tersedia sebagai metadata
  read-only; tidak ada aksi tambah/edit/hapus/simpan ke server. Trigger
  ditampilkan sebagai accordion per tabel: nama, timing, event, serta deskripsi
  singkat selalu terlihat; statement SQL hanya ditampilkan pada item yang
  dibuka, diberi syntax highlighting, dan dapat disalin.
- [x] **Cancel query dan execution timeout:** query dibatalkan atau melewati
  timeout konfigurasi (default 30 detik) dengan menutup sesi MySQL aktif agar
  operasi server berhenti. Inspector kembali disconnected dan user menekan
  **Connect** untuk memulai sesi bersih; tidak ada koneksi setengah-terpakai.
- [x] **Query history lokal/privat:** maksimal 50 query sukses per database
  dan environment disimpan lokal, tidak masuk export session, dapat dipilih
  ulang dari editor, serta dapat dihapus manual. Memilih history tidak pernah
  mengganti draft: pada statement yang sedang aktif query ditambahkan di akhir;
  pada whitespace antar-statement query disisipkan di posisi fokus. SQL yang
  dimasukkan selalu ditutup dengan `;`.
- [x] **Export hasil aktif ke CSV/JSON:** menu pada hasil database menyimpan
  halaman hasil yang sudah dimuat ke file lokal melalui dialog simpan native.
  CSV menyertakan BOM UTF-8 dan directive delimiter Excel agar setiap nilai
  masuk ke cell kolom yang tepat pada locale macOS. Nilai cell dipertahankan
  sebagai teks literal agar Excel tidak mengubah decimal atau ID dari database.
  Export tidak menjalankan query tambahan, tidak menyertakan kredensial, dan
  tidak ikut dalam export session Network Inspector.
- [x] **`EXPLAIN` dan ringkasan query plan:** tombol **Explain** menjalankan
  `EXPLAIN` hanya untuk active statement `SELECT`/`WITH`. Hasil menampilkan
  estimasi row dan memberi peringatan bila MySQL melaporkan full table scan.

## Tujuan

Menambahkan panel database MySQL yang ringan ke `dio_network_inspector`, supaya
developer dapat memeriksa data Voltunes saat debugging tanpa membuka TablePlus.
Panel berjalan di dalam aplikasi Flutter yang sudah dijalankan, bukan sebagai
proses desktop tambahan.

## Konteks

- Inspector saat ini sudah merekam request dan response `Dio`.
- Database Voltunes adalah MySQL dan dapat diakses dari Mac developer.
- Koneksi TablePlus menggunakan port non-standar serta SSL mode `PREFERRED`.
- Target utama adalah mengurangi tekanan RAM ketika Codex, Flutter desktop, dan
  alat database dipakai bersamaan.

## Ruang lingkup versi 1

1. Tab atau panel **Database** pada jendela inspector.
2. Koneksi MySQL dibuat hanya saat user membuka panel Database.
3. Daftar tabel dari satu database yang telah dikonfigurasi.
4. Tampilan data tabel dengan pagination (default 50 row) dan pemuatan halaman
   berikutnya berdasarkan permintaan user.
5. Kolom MySQL `ENUM` dikenali dan nilai yang diizinkan ditampilkan sebagai
   dropdown pada cell, seperti pilihan enum pada TablePlus.
7. Penampil nilai panjang dan JSON.
8. SQL read-only untuk query `SELECT`/`SHOW`/`DESCRIBE`, dengan batas row.
9. Editor SQL dengan autocomplete keyword MySQL dan nama schema yang tersedia.
10. **Highlight Active Statement**: query tempat cursor berada diberi blok
    highlight, dengan statement dipisahkan oleh tanda `;`.
11. Nomor baris editor dan penanda baris error yang merujuk ke `at line N`
    dari respons MySQL.
12. Banyak query tab tanpa batas lisensi: buat, pindah, ganti nama, dan tutup
    tab query secara independen.
13. Tombol refresh manual dan tombol disconnect.

## Di luar ruang lingkup versi 1

- `INSERT`, `UPDATE`, `DELETE`, DDL, import/export, dan transaksi tulis.
- Sinkronisasi skema atau cache seluruh isi database.
- Auto-refresh, polling, atau monitoring proses MySQL.
- Dukungan SSH tunnel. Jika koneksi memerlukannya, host app harus lebih dahulu
  menyediakan tunnel lokal yang sudah aktif.
- Menyimpan, mengekspor, atau menyalin kredensial database.
- Dukungan database selain MySQL.

Perubahan nilai enum langsung dari grid juga di luar ruang lingkup versi 1.
Fitur tersebut adalah mode tulis dan hanya dapat dipertimbangkan setelah mode
read-only stabil serta ada konfirmasi eksplisit per perubahan.

Autocomplete bukan izin eksekusi. Editor boleh menyarankan seluruh keyword
MySQL agar berguna untuk membaca schema, tetapi tombol **Run** harus nonaktif
untuk perintah yang tidak lolos kebijakan read-only.

## Keamanan

Gunakan akun MySQL khusus inspector dengan hak minimum. Akun tersebut hanya
boleh mendapat `SELECT` dan `SHOW VIEW` pada database development/staging yang
relevan. Jangan gunakan akun aplikasi utama atau akun dengan akses tulis.

Contoh pembuatan akun dilakukan oleh administrator database, bukan oleh package:

```sql
CREATE USER 'voltunes_inspector'@'allowed-host' IDENTIFIED BY 'strong-local-secret';
GRANT SELECT, SHOW VIEW ON `voltunes_db`.* TO 'voltunes_inspector'@'allowed-host';
FLUSH PRIVILEGES;
```

Konfigurasi nyata tidak boleh masuk ke Git, request log, session export, error
message, screenshot, atau file Markdown ini. Host aplikasi menyediakan
konfigurasi dari `.env` lokal atau secure storage. Password tidak ditampilkan
ulang oleh UI inspector.

Koneksi production perlu persetujuan eksplisit. Secara default, UI harus
menampilkan environment dan peringatan yang jelas jika konfigurasi ditandai
`production`.

## Kontrak konfigurasi yang diusulkan

Package menerima konfigurasi dari aplikasi host; package tidak membaca `.env`
secara langsung.

```dart
class MySqlInspectorConfig {
  const MySqlInspectorConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.sslMode = MySqlSslMode.preferred,
    this.environmentLabel = 'development',
    this.pageSize = 50,
    this.maxPageSize = 100,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final MySqlSslMode sslMode;
  final String environmentLabel;
  final int pageSize;
  final int maxPageSize;
}
```

Nilai aktual diisi hanya oleh aplikasi Voltunes, misalnya dari environment lokal
yang diabaikan Git. `sslMode` perlu mendukung sekurang-kurangnya `disabled`,
`preferred`, dan `required`; sertifikat CA/client hanya ditambahkan apabila
koneksi memang mewajibkannya.

## Arsitektur

```text
Voltunes host app
  └─ MySqlInspectorConfig (lokal, tidak dicatat inspector)
       └─ DatabaseInspectorController
            ├─ MySqlDatabaseClient
            ├─ query validator (read-only + LIMIT)
            └─ DatabaseInspectorWidget
                 ├─ daftar tabel
                 ├─ data tabel / filter / pagination
                 └─ SQL read-only

```

`MySqlDatabaseClient` dibungkus oleh interface agar UI dan test tidak bergantung
langsung pada driver MySQL:

```dart
abstract interface class DatabaseInspectorClient {
  Future<void> connect();
  Future<void> disconnect();
  Future<List<DatabaseTable>> listTables();
  Future<QueryPage> fetchRows(TableQuery query);
  Future<QueryPage> executeReadOnly(String sql);
}
```

Implementasi MySQL dan dependency drivernya dibuat lazy: koneksi tidak dibuat
saat overlay dibuka dan tidak ada query berjalan di background.

### Metadata enum

Saat koneksi dibuka, client mengambil metadata seluruh kolom schema dari
`INFORMATION_SCHEMA` dalam satu query.
Untuk kolom bertipe MySQL `ENUM`, client mengurai daftar nilai yang valid dari
metadata tipe dan mengembalikannya sebagai bagian dari `DatabaseColumn`.

```dart
class DatabaseColumn {
  const DatabaseColumn({
    required this.name,
    required this.type,
    this.enumValues = const [],
    this.isNullable = true,
  });

  final String name;
  final String type;
  final List<String> enumValues;
  final bool isNullable;
}
```

Saat koneksi dibuka, metadata seluruh kolom pada schema diambil dengan satu
query `INFORMATION_SCHEMA` dan disimpan untuk sesi aktif. UI memakai
`enumValues` untuk membuat dropdown langsung pada cell. Pilihan terdiri dari
semua nilai enum yang valid, ditambah **NULL** bila kolom nullable. Memilih
nilai hanya memberi pemberitahuan read-only; database tidak diubah. Penguraian
metadata harus diuji untuk nilai enum yang mengandung koma atau apostrof.

### Editor SQL dan kebijakan eksekusi

#### Query tabs

Database Inspector mendukung lebih dari dua query tab tanpa batas lisensi atau
paywall. Setiap tab menyimpan draft SQL, posisi cursor, active statement,
status validator, dan konfigurasi limitnya sendiri. User dapat membuat tab baru,
memberi nama tab, berpindah tab, dan menutupnya. Tab dengan draft yang belum
disimpan/di-clear meminta konfirmasi sebelum ditutup.

Semua tab berbagi satu `MySqlDatabaseClient` dan satu koneksi aktif; membuka tab
baru tidak boleh membuat koneksi MySQL baru. Untuk menjaga RAM, hasil query
besar hanya dipertahankan untuk tab aktif. Saat tab lama tidak aktif atau saat
melewati anggaran memori, hasilnya dapat dilepas sambil mempertahankan teks
query; UI memberi penanda bahwa query perlu dijalankan ulang untuk melihat
hasil. Draft SQL tidak dimasukkan ke export session network secara default.

#### Highlight Active Statement

Editor mengenali statement aktif dari posisi cursor. Bila beberapa query ditulis
dalam satu editor, tanda `;` di luar string literal dan komentar menjadi batas
statement. Statement yang memuat cursor mendapat highlight blok penuh, seperti
fitur **Highlight Current Query** di TablePlus.

```sql
SELECT * FROM users;

SELECT * FROM purchase_order_details  -- cursor berada di sini
WHERE supplier_price_accounting > 0;
```

Pada contoh tersebut, hanya statement kedua yang di-highlight dan yang menjadi
kandidat untuk **Run**. Memindahkan cursor ke statement pertama memindahkan
highlight tanpa menjalankan query. Parser harus mengabaikan `;` yang berada di
dalam string (`'text; value'`), quoted identifier, atau komentar SQL agar blok
aktif tidak salah. Jika cursor berada di whitespace di antara dua statement,
tidak ada statement aktif dan **Run** nonaktif.

Autocomplete mengambil keyword MySQL dari `INFORMATION_SCHEMA.KEYWORDS` sekali
saat koneksi dibuka, kemudian menambahkan nama tabel dan kolom dari metadata
database yang sedang terhubung. Bila view keyword tidak tersedia, katalog
keyword bawaan dipakai sebagai fallback.
Contohnya, ketika user mengetik `use`, pilihan `users`, `user_roles`, dan tabel
lain yang cocok muncul bersama keyword `USER`/`USE`, dengan label nama database
di sebelahnya. Nama tabel diprioritaskan setelah konteks `FROM`, `JOIN`,
`UPDATE`, `INTO`, atau `TABLE`; nama kolom diprioritaskan setelah `SELECT`,
`WHERE`, `ORDER BY`, dan `GROUP BY`.

Autocomplete kolom juga memahami alias tabel. Parser editor membangun symbol
table dari bagian `FROM` dan `JOIN`, baik alias menggunakan `AS` maupun alias
singkat tanpa `AS`:

```sql
SELECT A.price, B.
FROM purchase_order_details AS A
JOIN supplier_prices B ON B.id = A.supplier_price_id
WHERE B.pri
```

Pada `B.` atau `B.pri`, saran dibatasi pada kolom tabel `supplier_prices` yang
dipetakan ke alias `B`; contohnya `B.price`, `B.price_accounting`, beserta tipe
kolomnya. Hal yang sama berlaku untuk `A.pri`. Nama alias dicocokkan tanpa
membedakan huruf besar/kecil, sementara teks yang dimasukkan user dipertahankan
di editor. Untuk kolom tanpa prefix pada query multi-tabel, UI menampilkan
sumbernya (`A.price`, `B.price`) agar kolom yang ambigu tidak terlihat sama.

Alias yang belum bisa dipetakan dengan pasti—misalnya hasil subquery/CTE yang
kompleks—tidak boleh menghasilkan saran kolom yang keliru. UI dapat tetap
memberi keyword dan nama tabel umum, atau meminta metadata hasil query pada
tahap lanjutan.

Tidak perlu scraping dari internet atau menjalankan query tambahan untuk setiap
karakter yang diketik. Metadata tabel, kolom, dan keyword diambil sekali ketika
koneksi dibuka, disimpan hanya untuk sesi aktif, lalu digunakan untuk
autocomplete. Keyword
tulis seperti `INSERT` atau `UPDATE` tetap dapat muncul sebagai saran, namun
tidak pernah membuat query dapat dieksekusi.

Sebelum tombol **Run** diaktifkan, query harus dianalisis dengan parser/tokenizer
SQL yang konservatif. Aturannya:

- Hanya active statement yang dianalisis dan dapat dijalankan; statement lain
  dalam editor tidak ikut berjalan.
- Active statement harus tepat satu statement utuh yang dibatasi parser.
- Statement yang diizinkan: `SELECT`, `SHOW`, `DESCRIBE`, dan `EXPLAIN` untuk
  query read-only.
- `WITH` hanya diizinkan jika statement terakhirnya adalah `SELECT` dan semua
  CTE juga read-only.
- Query yang diizinkan selalu diberi atau dibatasi `LIMIT` oleh client, kecuali
  jenis statement yang memang tidak menerima `LIMIT`.
- UI menampilkan alasan tombol dinonaktifkan, misalnya: “`UPDATE` tidak
  diizinkan: Database Inspector adalah read-only.”

Tombol **Run** harus tetap nonaktif untuk keyword/perilaku berikut, termasuk
varian multi-statement dan query yang disamarkan dengan komentar:

```text
INSERT, UPDATE, DELETE, REPLACE, CREATE, ALTER, DROP, TRUNCATE,
RENAME, GRANT, REVOKE, SET, USE, CALL, DO, LOAD, HANDLER, INSTALL,
UNINSTALL, KILL, PURGE, LOCK, UNLOCK, START TRANSACTION, COMMIT,
ROLLBACK, SAVEPOINT
```

Selain itu, blokir `SELECT ... FOR UPDATE`, `LOCK IN SHARE MODE`, `SELECT ...
INTO OUTFILE`, dan `SELECT ... INTO DUMPFILE`. Jangan memakai pemeriksaan regex
satu kata sebagai pengaman karena komentar, CTE, quote, dan beberapa statement
dapat melewati pendekatan tersebut. Bila query tidak dapat dipastikan aman,
perlakukan sebagai tidak aman dan nonaktifkan **Run**.

## Batas performa dan RAM

- Satu koneksi aktif maksimum.
- Putuskan koneksi ketika panel Database ditutup atau setelah idle timeout
  opsional dari Inspector settings. Fitur ini nonaktif secara default; saat
  diaktifkan, interval dapat dipilih (1, 5, 15, atau 30 menit). Aktivitas
  editor, browse tabel, query, klik/tap, dan scroll di panel Database
  mengulang timer idle.
- Ambil daftar tabel dan metadata kolom schema sekali per sesi; jangan
  mengambil ukuran tabel atau isi semua tabel otomatis.
- Pagination menggunakan `LIMIT` dan offset/cursor yang sesuai kemampuan MySQL.
- Batas hasil query 100 row; ukuran page default 50.
- Jangan memasukkan hasil database ke `DioNetworkInspector.exportSession()`.
- Jangan menduplikasi string/blob besar untuk preview; tampilkan preview terbatas
  dan buka nilai penuh hanya atas aksi user.

## Tahapan implementasi

1. Tambahkan kontrak konfigurasi, interface client, dan model tabel/query.
2. Tambahkan driver MySQL serta implementasi koneksi dengan SSL sesuai config.
3. Buat query validator read-only dan pembatas `LIMIT`.
4. Tambahkan metadata kolom seluruh schema, termasuk `ENUM`, dan dropdown
   inspeksi langsung pada cell.
5. Tambahkan editor SQL dengan parsing statement aktif, highlight berdasarkan
   posisi cursor, autocomplete keyword/schema, tabel, kolom, dan alias
   `FROM`/`JOIN`, serta alasan status tombol Run yang dapat diakses user.
6. Tambahkan lifecycle query tab (new, rename, close, restore draft) dengan
   satu koneksi bersama dan eviction hasil query yang tidak aktif.
7. Buat controller dan Database panel: connect, disconnect, tabel, dan paging.
8. Tambahkan filter, SQL read-only, serta state error yang tidak membocorkan
   password/connection string.
9. Buat example app lokal dengan konfigurasi placeholder; jangan pernah memakai
   database production sebagai fixture test otomatis.

## Backlog fitur lanjutan

Fitur berikut terinspirasi dari alur kerja database client desktop dan tetap
dirancang untuk inspector yang ringan serta read-only. Item yang dicentang
sudah tersedia; sisanya adalah backlog.

### Prioritas tinggi

1. **Folder dan keyword snippets untuk saved query**
   - Query read-only bernama sudah tersedia secara lokal per
     database/environment, tanpa kredensial atau hasil query di file storage.
   - [x] Folder lokal serta penyisipan SQL ke tab aktif tanpa menjalankan query
     secara otomatis.

2. **Foreign-key navigation / Inspect related data**
   - [x] Metadata foreign key menampilkan aksi pada kolom relasi, termasuk
     query result bila relasi dapat ditentukan tanpa ambigu. Aksi membuat query
     `SELECT` read-only yang sudah escaped pada tab baru lalu menjalankannya
     otomatis.
   - [x] Navigasi balik dari tabel referensi untuk satu relasi yang tidak
     ambigu.
  - [x] Relasi komposit memakai seluruh pasangan kolom constraint yang sama.

3. **Cancel query dan execution timeout**
   - [x] Setiap query memiliki timeout yang dapat dikonfigurasi secara lokal
     (default 30 detik).
   - [x] User dapat membatalkan query read-only yang berjalan. Sesi MySQL aktif
     ditutup untuk memastikan operasi server berhenti, lalu inspector kembali
     disconnected agar user dapat membuat sesi bersih lewat **Connect**.

4. **Structure read-only (inspirasi TablePlus)**
   - [x] Saat user membuka tabel, switch **Data / Structure** menyediakan
     metadata columns tanpa memuat row tambahan.
   - [x] **Columns:** urutan, nama, data type, nullable, serta penanda PK/FK
     dan target relasi dari metadata sesi aktif.
   - [x] **Indexes:** nama, unique/non-unique, type, dan urutan kolom dibaca
     dari `INFORMATION_SCHEMA.STATISTICS` saat tabel dibuka.
   - [x] **Foreign keys:** aturan `ON UPDATE`/`ON DELETE` ditampilkan bila
     tersedia dari metadata `INFORMATION_SCHEMA`.
   - [x] **Triggers:** nama, timing, event, dan statement read-only tersedia
     dalam accordion dengan syntax highlighting serta tombol salin.
   - [x] **DDL:** `SHOW CREATE TABLE` dengan syntax highlighting dan ikon copy
     di dalam panel DDL. Tidak ada eksekusi DDL, import, perubahan schema,
     atau tombol Save.
   - Referensi UX: dokumentasi resmi TablePlus untuk
     [Table Structure](https://docs.tableplus.com/gui-tools/working-with-table/table),
     [Index](https://docs.tableplus.com/gui-tools/working-with-table/index),
     dan [Trigger](https://docs.tableplus.com/gui-tools/working-with-table/trigger).

### Prioritas sedang

5. **Query history lokal yang dapat dihapus**
   - [x] Menyimpan maksimal 50 query sukses per database/environment secara
     lokal dan dapat dibuka kembali tanpa mengganti draft aktif.
   - [x] Sediakan clear per item dan clear all.
   - [x] History nonaktif secara default untuk koneksi `production`; user dapat
     mengaktifkannya secara eksplisit dari Inspector settings.

6. **Export hasil aktif**
   - [x] Export hanya hasil query/page yang sedang terlihat ke CSV atau JSON.
   - [x] Tidak ada import, SQL dump, atau export seluruh database pada tahap
     ini. User memilih lokasi file secara eksplisit; tidak ada export otomatis.

7. **`EXPLAIN` dan ringkasan query plan**
   - [x] Menjalankan `EXPLAIN` pada query read-only dan menampilkan tabel,
     index, estimasi row, serta peringatan full table scan.
   - [ ] **TODO — Visual graph/diagram plan** ditunda sampai implementasi dasar
     stabil.

### Ditunda atau tidak diprioritaskan

- Multi-window desktop: menambah penggunaan RAM dan tidak diperlukan untuk
  tujuan utama inspector.
- ERD/schema diagram penuh dan dashboard chart otomatis: berguna, tetapi lebih
  berat daripada kebutuhan debugging harian.
- Import CSV/SQL dump, edit schema/data, user management, query process kill,
  dan backup/restore: bertentangan dengan mode read-only atau memiliki risiko
  besar pada koneksi production.

## Kriteria selesai versi 1

- Saat tab Database tidak dibuka, tidak ada koneksi MySQL maupun polling.
- User dapat connect dan disconnect secara manual dengan konfigurasi valid.
- User dapat melihat daftar tabel dan membuka data satu tabel per halaman.
- Kolom `ENUM` menampilkan dropdown pada cell yang hanya berisi nilai valid
  dan `NULL` bila diizinkan; pilihan tidak mengubah database.
- SQL hanya menjalankan operasi read-only dengan batas hasil.
- Autocomplete boleh menampilkan keyword MySQL lengkap, tetapi **Run** hanya
  aktif untuk satu query yang telah tervalidasi read-only.
- Cursor di dalam statement yang dibatasi `;` memberi highlight pada statement
  tersebut; hanya statement aktif itu yang boleh dievaluasi untuk **Run**.
- User dapat membuka lebih dari dua query tab; semua berbagi satu koneksi dan
  tab tersembunyi tidak menyimpan hasil query besar tanpa batas.
- Setelah alias tabel dikenali dari `FROM`/`JOIN`, `alias.prefix` hanya memberi
  saran kolom milik tabel alias tersebut dan menampilkan tipe kolomnya.
- Query ambigu, multi-statement, atau berpotensi menulis selalu membuat **Run**
  nonaktif dengan alasan yang jelas.
- Error koneksi menjelaskan masalah secara aman tanpa mencetak credential.
- Query dan hasil database tidak muncul di ekspor sesi network secara default.
- Unit test mencakup validator SQL, limit, pagination, dan controller state;
  integration test menggunakan MySQL lokal/ephemeral, bukan production.

## Keputusan yang masih diperlukan

1. Environment mana yang boleh diakses: development, staging, atau production.
2. Apakah koneksi mengharuskan SSL `PREFERRED` atau `REQUIRED`.
3. Nama akun MySQL read-only khusus inspector dan host yang diizinkan.
