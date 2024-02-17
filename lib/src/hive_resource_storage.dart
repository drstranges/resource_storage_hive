// Copyright 2024 The Cached Resource Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:resource_storage/resource_storage.dart';
import 'package:synchronized/synchronized.dart';

import 'hive_cache_entry.dart';
import 'hive_provider.dart';

/// Factory to provide instance of [HiveResourceStorage].
class HiveResourceStorageProvider implements ResourceStorageProvider {
  /// Creates factory of [HiveResourceStorage].
  const HiveResourceStorageProvider();

  @override
  ResourceStorage<K, V> createStorage<K, V>({
    required String storageName,
    StorageDecoder<V>? decode,
    StorageExecutor? executor,
    TimestampProvider? timestampProvider,
    ResourceLogger? logger,
  }) {
    return HiveResourceStorage(
      storageName: storageName,
      decode: ArgumentError.checkNotNull(decode, 'decode'),
      executor: executor ?? syncStorageExecutor,
      timestampProvider: timestampProvider ?? const TimestampProvider(),
      logger: logger,
    );
  }
}

/// Persistent resource storage implementation based on Hive database.
/// Stores a value as JSON string.
class HiveResourceStorage<K, V> implements ResourceStorage<K, V> {
  /// Creates persistent resource storage implementation based on Hive database.
  ///
  /// Stores a value as JSON string, so [decode] should be provided to be able
  /// to decode a value back.
  ///
  /// [storageName] is used by Hive to resolve storage box to store key-value
  /// data, therefore, it should be unique for the storage.
  ///
  /// For large json data consider providing a custom [executor] that runs task
  /// in separate isolate.
  ///
  /// Custom [timestampProvider] could be used in test to mock storeTime.
  ///
  /// Provide [Logger] if you want to see logs like errors during JSON parsing.
  ///
  HiveResourceStorage({
    required this.storageName,
    required StorageDecoder<V> decode,
    StorageExecutor executor = syncStorageExecutor,
    TimestampProvider timestampProvider = const TimestampProvider(),
    ResourceLogger? logger,
  })  : _logger = logger,
        _timestampProvider = timestampProvider,
        _storageAdapter = JsonStorageAdapter<V>(
          decode: decode,
          executor: executor,
          logger: logger,
        );

  static final _lock = Lock();
  final ResourceLogger? _logger;
  final String storageName;
  final JsonStorageAdapter<V> _storageAdapter;

  /// Set custom timestamp provider if you need it in tests
  final TimestampProvider _timestampProvider;

  /// Deletes all data from the Hive database instance that used by the storage.
  static Future<void> clearAllStorage() async {
    final hive = await HiveProvider.instance.ensureInitialized();
    await hive.deleteFromDisk();
  }

  /// Clears the storage box with name [storageName].
  @override
  Future<void> clear() async {
    final box = await _ensureBox();
    await box.clear();
  }

  @override
  Future<CacheEntry<V>?> getOrNull(K key) async {
    final storageKey = _resolveStorageKey(key);
    final cache = (await _ensureBox()).get(storageKey);
    if (cache != null) {
      try {
        final value = await _storageAdapter.decodeFromJson(cache.data);
        return CacheEntry(value, storeTime: cache.storeTime);
      } catch (e, trace) {
        _logger?.trace(
            LoggerLevel.error,
            'Error on load resource from [$storageName] by key [$storageKey]',
            e,
            trace);
      }
    }
    return null;
  }

  @override
  Future<void> put(K key, V data, {int? storeTime}) async {
    final storageKey = _resolveStorageKey(key);
    final json = await _storageAdapter.encodeToJson(data);
    final entry = HiveCacheEntry(
      json,
      storeTime: storeTime ?? _timestampProvider.getTimestamp(),
    );
    final box = await _ensureBox();
    await box.put(storageKey, entry);
  }

  @override
  Future<void> remove(K key) async {
    final storageKey = _resolveStorageKey(key);
    await (await _ensureBox()).delete(storageKey);
  }

  String _resolveStorageKey(K key) {
    if (key is String) return key;
    // Try to resolve resource key
    final dynamic dynamicKey = key;
    try {
      return dynamicKey.resourceKey;
    } catch (ignore) {
      //ignore
    }
    _logger?.trace(
      LoggerLevel.warning,
      'Complex storage key used: [$key]. Fallback to [key.toString()].'
      ' Try to use String as key or implement [String resourceKey] field.'
      ' Or ensure that toString method returns a value'
      ' that can be used as identifier of resource',
    );
    return key.toString();
  }

  Future<Box<HiveCacheEntry>> _ensureBox() => _lock.synchronized(() async {
        final hive = await HiveProvider.instance.ensureInitialized();
        Box<HiveCacheEntry> box;
        try {
          box = await hive.openBox(storageName);
        } catch (e, trace) {
          _logger?.trace(
              LoggerLevel.error,
              'Error on open box [$storageName]'
              ' => trying to recreate box. Cached data will be lost!',
              e,
              trace);
          await hive.deleteBoxFromDisk(storageName);
          box = await hive.openBox(storageName);
        }
        return box;
      });

  @override
  String toString() => 'HiveResourceStorage($storageName)';
}
