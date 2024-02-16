// Copyright 2024 The Cached Resource Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:hive/hive.dart';

/// Cache entry used by [HiveResourceStorage]
class HiveCacheEntry {
  HiveCacheEntry(this.data, {required this.storeTime});

  String data;
  int storeTime;
}

/// Hive adapter for [HiveCacheEntry]
class HiveCacheEntryAdapter extends TypeAdapter<HiveCacheEntry> {
  @override
  final typeId = 0;

  @override
  HiveCacheEntry read(BinaryReader reader) {
    return HiveCacheEntry(reader.read(), storeTime: reader.read());
  }

  @override
  void write(BinaryWriter writer, HiveCacheEntry obj) {
    writer.write(obj.data);
    writer.write(obj.storeTime);
  }
}
