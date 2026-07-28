# MySQL Database Inspector

## Status

**Implementasi awal tersedia.** Koneksi MySQL tetap opt-in dan tidak dibuat
sampai user menekan **Connect**. Fitur editor lanjutan dan backlog tetap
ditandai TODO sampai ada kode serta verifikasi yang sesuai.

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
- [ ] **TODO — Mode read-only lanjutan:** parameter binding untuk query
  template dan parser penuh untuk statement kompleks.
- [x] **Database panel:** status koneksi, daftar tabel, data tabel,
  paging, refresh manual, dan disconnect.
- [x] **Metadata ENUM:** nilai valid dibaca dari schema dan dapat digunakan
  sebagai dropdown filter parameterized, termasuk opsi `NULL` bila diizinkan.
- [ ] **TODO — Metadata kolom lanjutan:** tampilan tipe data dan JSON preview.
- [x] **Autocomplete dasar:** keyword MySQL, tabel sesi aktif, serta kolom
  metadata yang sudah dibuka, termasuk prefix alias `FROM`/`JOIN` sederhana.
- [ ] **TODO — SQL editor lanjutan:** syntax highlighting, katalog kolom penuh,
  parsing alias/CTE kompleks, dan Highlight Active Statement.
- [x] **Query tabs dasar:** buat, pindah, dan tutup tab tanpa batas lisensi;
  draft serta satu halaman hasil per tab memakai satu koneksi bersama.
- [ ] **TODO — Query tabs lanjutan:** ganti nama, restore lintas sesi,
  konfirmasi draft sebelum menutup, dan eviction hasil tab tidak aktif.
- [ ] **TODO — Hardening:** error aman, lifecycle koneksi, batas RAM, unit test,
  dan integration test memakai MySQL lokal/ephemeral.
- [ ] **TODO — Request-to-table mapping:** aksi Inspect related data dari request
  Dio ke row/tabel terkait.

### Backlog setelah versi 1

- [ ] **TODO — Advanced filter presets** tanpa batas kondisi.
- [ ] **TODO — Saved query dan keyword snippets.**
- [ ] **TODO — Foreign-key navigation.**
- [ ] **TODO — Cancel query dan execution timeout.**
- [ ] **TODO — Query history lokal/privat.**
- [ ] **TODO — Query parameters.**
- [ ] **TODO — Export hasil aktif ke CSV/JSON.**
- [ ] **TODO — `EXPLAIN` dan ringkasan query plan.**

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
5. Filter sederhana berdasarkan kolom yang dipilih.
6. Kolom MySQL `ENUM` dikenali dan nilai yang diizinkan ditampilkan sebagai
   dropdown filter, seperti pilihan enum pada TablePlus.
7. Penampil nilai panjang dan JSON.
8. SQL read-only untuk query `SELECT`/`SHOW`/`DESCRIBE`, dengan batas row.
9. Editor SQL dengan autocomplete keyword MySQL dan nama schema yang tersedia.
10. **Highlight Active Statement**: query tempat cursor berada diberi blok
    highlight, dengan statement dipisahkan oleh tanda `;`.
11. Banyak query tab tanpa batas lisensi: buat, pindah, ganti nama, dan tutup
    tab query secara independen.
12. Tombol refresh manual dan tombol disconnect.

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

DioNetworkInspector
  └─ NetworkRequest terpilih
       └─ optional RequestDatabaseLink → filter tabel yang terkait
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

Saat tabel dibuka, client mengambil metadata kolom dari `INFORMATION_SCHEMA`.
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

UI memakai `enumValues` untuk membuat dropdown filter. Pilihan terdiri dari
semua nilai enum yang valid, ditambah **NULL** bila kolom nullable. **DEFAULT**
tidak muncul dalam mode read-only karena ia hanya bermakna saat menulis row.
Nilai enum tidak boleh dibangun menjadi SQL secara langsung; filter selalu
memakai parameter binding. Penguraian metadata harus diuji untuk nilai enum
yang mengandung koma atau apostrof.

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

Autocomplete memakai katalog keyword MySQL statis terlebih dahulu, kemudian
menambahkan nama tabel dan kolom dari metadata database yang sedang terhubung.
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
karakter yang diketik. Metadata tabel diambil sekali ketika koneksi dibuka,
disimpan hanya untuk sesi aktif, lalu digunakan untuk autocomplete. Keyword
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
- Putuskan koneksi ketika panel Database ditutup atau setelah idle timeout.
- Ambil metadata tabel sekali per sesi; jangan mengambil ukuran tabel atau isi
  semua tabel otomatis.
- Pagination menggunakan `LIMIT` dan offset/cursor yang sesuai kemampuan MySQL.
- Batas hasil query 100 row; ukuran page default 50.
- Jangan memasukkan hasil database ke `DioNetworkInspector.exportSession()`.
- Jangan menduplikasi string/blob besar untuk preview; tampilkan preview terbatas
  dan buka nilai penuh hanya atas aksi user.

## Integrasi dengan request Dio (tahap lanjutan)

Hubungan request dan tabel tidak dapat ditebak secara aman. Aplikasi host
mendaftarkan mapping secara eksplisit, misalnya response endpoint user memiliki
`id` yang harus dipakai untuk memfilter tabel `users`.

```dart
RequestDatabaseLink(
  method: 'GET',
  pathPattern: r'/users/:id',
  table: 'users',
  column: 'id',
  valueFrom: RequestValueSource.pathParameter('id'),
)
```

UI kemudian menampilkan aksi **Inspect related data** pada request yang cocok.
Tidak ada SQL yang dibangun dari input request tanpa parameter binding dan
validasi nama tabel/kolom.

## Tahapan implementasi

1. Tambahkan kontrak konfigurasi, interface client, dan model tabel/query.
2. Tambahkan driver MySQL serta implementasi koneksi dengan SSL sesuai config.
3. Buat query validator read-only, parameter binding, dan pembatas `LIMIT`.
4. Tambahkan metadata kolom, termasuk `ENUM`, dan dropdown filter yang memakai
   parameter binding.
5. Tambahkan editor SQL dengan parsing statement aktif, highlight berdasarkan
   posisi cursor, autocomplete keyword/schema, tabel, kolom, dan alias
   `FROM`/`JOIN`, serta alasan status tombol Run yang dapat diakses user.
6. Tambahkan lifecycle query tab (new, rename, close, restore draft) dengan
   satu koneksi bersama dan eviction hasil query yang tidak aktif.
7. Buat controller dan Database panel: connect, disconnect, tabel, dan paging.
8. Tambahkan filter, SQL read-only, serta state error yang tidak membocorkan
   password/connection string.
9. Tambahkan request-to-table mapping sebagai fitur terpisah setelah panel dasar
   stabil.
10. Buat example app lokal dengan konfigurasi placeholder; jangan pernah memakai
   database production sebagai fixture test otomatis.

## Backlog fitur lanjutan

Fitur berikut terinspirasi dari alur kerja database client desktop, tetapi
dirancang untuk inspector yang ringan dan read-only. Semua item di bawah adalah
backlog; tidak termasuk implementasi versi 1.

### Prioritas tinggi

1. **Advanced filter tanpa batas dan filter presets**
   - User dapat menambah lebih dari dua kondisi filter, menggabungkan `AND`/`OR`,
     lalu menyimpan filter sebagai preset lokal per tabel.
   - Filter dibangun memakai parameter binding dan tetap menghasilkan `SELECT`
     yang dibatasi `LIMIT`.

2. **Saved query dan keyword snippets**
   - User dapat menyimpan query read-only dengan nama, folder, dan keyword.
   - Mengetik keyword lalu memilih snippet memasukkan SQL ke tab aktif; tidak
     menjalankan query secara otomatis.
   - Simpan lokal dan jangan menaruh credential, hasil query, atau nilai sensitif
     ke file favorite.

3. **Foreign-key navigation / Inspect related data**
   - Metadata foreign key menampilkan aksi pada kolom relasi, misalnya `user_id`
     membuka row yang sesuai pada tabel `users`.
   - Aksi ini membuka filter/query read-only di tab baru dan memakai parameter
     binding.

4. **Cancel query dan execution timeout**
   - Setiap query memiliki timeout yang dapat dikonfigurasi secara lokal.
   - User dapat membatalkan query read-only yang berjalan; cancellation tidak
     boleh menutup seluruh inspector atau mengganggu tab lain.

### Prioritas sedang

5. **Query history lokal yang dapat dihapus**
   - Menyimpan daftar query yang benar-benar dijalankan, waktu, dan statusnya
     secara lokal agar dapat dibuka kembali di tab baru.
   - Sediakan clear per item dan clear all. History dinonaktifkan secara default
     untuk koneksi berlabel `production` atau bila user memilih mode privat.

6. **Query parameters**
   - Template dapat mendefinisikan parameter, misalnya `WHERE id = :id`.
   - Sebelum Run, UI meminta nilai parameter dan mengirimnya melalui parameter
     binding, bukan interpolasi string.

7. **Export hasil aktif**
   - Export hanya hasil query/page yang sedang terlihat ke CSV atau JSON.
   - Tidak ada import, SQL dump, atau export seluruh database pada tahap ini.
   - User memilih lokasi file secara eksplisit; tidak ada export otomatis.

8. **`EXPLAIN` dan ringkasan query plan**
   - Menjalankan `EXPLAIN` pada query read-only dan menampilkan tabel, index,
     estimasi row, serta peringatan full table scan.
   - Visual graph/diagram plan ditunda sampai implementasi dasar stabil.

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
- Kolom `ENUM` menampilkan dropdown filter yang hanya berisi nilai yang valid
  dan `NULL` bila diizinkan.
- Filter dan SQL hanya menjalankan operasi read-only dengan batas hasil.
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
4. Tabel/endpoint pertama yang akan mendapat mapping **Inspect related data**.
