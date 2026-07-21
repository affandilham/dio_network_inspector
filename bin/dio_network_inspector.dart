import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args.first;
  final additionalArgs = args.skip(1).toList();

  switch (command) {
    case 'save':
      _savePatch(additionalArgs);
      break;
    case 'plug':
      _plug();
      break;
    case 'unplug':
      _unplug();
      break;
    default:
      print('❌ Perintah tidak dikenal: $command');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('''
Dio Network Inspector CLI
-------------------------
Cara pakai: dart run dio_network_inspector <command> [file1 file2 ...]

Commands:
  save [file1 file2] : Merekam perubahan kode saat ini ke inspector.patch.
                       (Opsional: Anda bisa menspesifikasikan path file tertentu 
                       jika tidak ingin merekam semua perubahan git).
  plug               : Menerapkan inspector.patch ke dalam kode (git apply).
  unplug             : Mencabut inspector.patch dari kode (git apply -R).
''');
}

void _savePatch(List<String> files) {
  print('Merekam patch ke inspector.patch...');

  final gitArgs = ['diff'];
  if (files.isNotEmpty) {
    gitArgs.addAll(files);
    print('ℹ️  Memfilter perubahan HANYA untuk file:');
    for (var f in files) {
      print('    - $f');
    }
  }

  final result = Process.runSync('git', gitArgs);

  if (result.stdout.toString().trim().isEmpty) {
    if (files.isNotEmpty) {
      print('⚠️ Tidak ada perubahan kode pada file-file yang disebutkan.');
    } else {
      print(
        '⚠️ Tidak ada perubahan kode (git diff kosong). Pastikan Anda belum melakukan git add/commit pada kode sisipan.',
      );
    }
    return;
  }

  final file = File('inspector.patch');
  file.writeAsStringSync(result.stdout.toString());
  print('✅ Berhasil menyimpan patch ke inspector.patch');
  print(
    'ℹ️  Jangan lupa tambahkan inspector.patch ke .gitignore agar tidak ter-commit ke repositori utama Anda.',
  );
}

void _plug() {
  final file = File('inspector.patch');
  if (!file.existsSync()) {
    print(
      '❌ File inspector.patch tidak ditemukan. Jalankan perintah `save` terlebih dahulu saat plugin terpasang manual.',
    );
    exit(1);
  }

  print('Menerapkan inspector.patch...');
  final result = Process.runSync('git', ['apply', 'inspector.patch']);

  if (result.exitCode == 0) {
    print('✅ Dio Network Inspector berhasil dipasang (PLUGGED)!');
    print(
      'ℹ️  Jangan lupa jalankan `flutter pub get` jika ada perubahan dependensi.',
    );
    _checkForUpdates();
  } else {
    print('❌ Gagal menerapkan patch:');
    print(result.stderr);
    print(result.stdout);
    print('\n💡 SOLUSI JIKA PATCH GAGAL:');
    print(
      'Struktur baris kode proyek Anda telah berubah sehingga git kebingungan mencari titik sisipan.',
    );
    print('Lakukan 3 langkah mudah ini:');
    print(
      '  1. Pasang/tambahkan ulang kode plugin secara manual ke proyek Anda.',
    );
    print(
      '  2. Jalankan `dart run dio_network_inspector save` untuk merekam ulang patch terbaru.',
    );
    print(
      '  3. Jalankan `dart run dio_network_inspector unplug` untuk mencabutnya kembali.',
    );
  }
}

void _unplug() {
  final file = File('inspector.patch');
  if (!file.existsSync()) {
    print('❌ File inspector.patch tidak ditemukan.');
    exit(1);
  }

  print('Mencabut inspector.patch...');
  final result = Process.runSync('git', ['apply', '-R', 'inspector.patch']);

  if (result.exitCode == 0) {
    print('✅ Dio Network Inspector berhasil dicabut (UNPLUGGED)!');
  } else {
    print(
      '❌ Gagal mencabut patch (mungkin sudah dicabut atau ada perubahan konflik kode):',
    );
    print(result.stderr);
    print(result.stdout);
  }
}

void _checkForUpdates() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) return;

  final lines = pubspecFile.readAsLinesSync();
  String? gitUrl;
  String? currentRef;

  bool inInspector = false;
  int inspectorIndent = -1;

  for (var line in lines) {
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;

    final indent = line.length - line.trimLeft().length;

    if (line.trim().startsWith('dio_network_inspector:')) {
      inInspector = true;
      inspectorIndent = indent;
      continue;
    }

    if (inInspector) {
      if (indent <= inspectorIndent) {
        inInspector = false;
        continue;
      }

      if (line.trim().startsWith('url:')) {
        gitUrl = line.split('url:').last.trim();
      } else if (line.trim().startsWith('ref:')) {
        currentRef = line.split('ref:').last.trim();
      }
    }
  }

  if (gitUrl != null) {
    try {
      final result = Process.runSync('git', ['ls-remote', '--tags', gitUrl]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();

        final tags = <String>[];
        for (var line in output.split('\n')) {
          if (line.contains('refs/tags/')) {
            var tag = line.split('refs/tags/').last.trim();
            if (tag.endsWith('^{}')) tag = tag.substring(0, tag.length - 3);
            tags.add(tag);
          }
        }

        if (tags.isNotEmpty) {
          tags.sort();
          final latestTag = tags.last;
          if (currentRef != null && currentRef != latestTag) {
            print('\n🌟 [INFO UPDATE TERSEDIA]');
            print(
              'Versi terbaru dio_network_inspector ($latestTag) telah tersedia di GitHub!',
            );
            print('Saat ini Anda menggunakan ref: $currentRef');
            print(
              'Silakan update `pubspec.yaml` Anda menjadi `ref: $latestTag` dan jalankan `flutter pub get`.\n',
            );
          }
        }
      }
    } catch (e) {}
  }
}
