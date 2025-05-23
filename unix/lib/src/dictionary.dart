import 'dart:io';

import 'package:device_vendor_info_interface/collections.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

final class _UnixVendorDictionaryEntriesStream
    extends VendorDictionaryEntriesStreamBase<String> {
  const _UnixVendorDictionaryEntriesStream();

  @override
  Future<void> generateContent(DictionaryEntryStreamAdder<String> add,
      DictionaryEntryStreamThrower addError) async {
    final Directory dmi = Directory(r"/sys/class/dmi/id/");
    assert(dmi.isAbsolute);

    if (!await dmi.exists()) {
      return;
    }

    bool isReadable(int mode) => [mode >> 6, mode >> 3, mode]
        .map((e) => e & 0x7)
        .every((permission) => permission >= 0x4);

    final Stream<File> dmiFiles = dmi
        .list(followLinks: false)
        .where((entity) =>
            entity is File && isReadable(entity.statSync().mode & 0x1FF))
        .cast<File>();

    await for (File f in dmiFiles) {
      add(p.basename(f.path), await f.readAsString());
    }
  }
}

/// UNIX implementation of [VendorDictionary].
@internal
final class UnixVendorDictionary extends VendorDictionaryBase<String> {
  /// Constructor of [UnixVendorDictionary].
  ///
  /// It only valid when running in UNIX. Otherwise, the assertion
  /// failed.
  UnixVendorDictionary() {
    if (!Platform.isMacOS && !Platform.isLinux) {
      throw UnsupportedError("This dictionary is only designed for UNIX only.");
    }
  }

  @override
  VendorDictionaryEntriesStream<String> get entries =>
      const _UnixVendorDictionaryEntriesStream();
}
