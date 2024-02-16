// Copyright 2024 The Cached Resource Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

import 'hive_cache_entry.dart';

/// Helper class to initialize separate instance of Hive database,
/// so this instance will not intersect with any other instance
/// in a target application
final class HiveProvider {
  const HiveProvider._();

  static final instance = HiveProvider._();
  static late final HiveImpl _hive = HiveImpl();
  static final _lock = Lock();
  static bool _needInitialize = true;

  /// Returns separate Hive instance and ensures that it is initialized.
  Future<HiveImpl> ensureInitialized() => _lock.synchronized(() async {
    if (_needInitialize) {
      _hive.registerAdapter(HiveCacheEntryAdapter());
      var appDir = await getApplicationDocumentsDirectory();
      _hive.init(path_utils.join(appDir.path, 'hive_res_storage'));
      _needInitialize = false;
    }
    return _hive;
  });

  /// Registers [adapters] in Hive instance that used by [HiveResourceStorage]
  Future<void> registerAdapters(List<TypeAdapter> adapters) async {
    final hive =
        await HiveProvider.instance.ensureInitialized();
    for (final adapter in adapters) {
      hive.registerAdapter(adapter);
    }
  }
}
