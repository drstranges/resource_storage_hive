## Hive Resource Storage
[![pub package](https://img.shields.io/pub/v/resource_storage_hive.svg)](https://pub.dev/packages/resource_storage_hive)

Simple implementation of persistent resource storage for [cached_resource](https://pub.dev/packages/cached_resource) package,
based on [hive][https://pub.dev/packages/hive] that stores a value as a JSON string.

## Components

1. `HiveResourceStorage`: persistent resource storage based on Hive database.
2. `HiveResourceStorageProvider`: factory to use for configuration of `cached_resource`.
3. `HiveProvider`: helper class to create separate instance of Hive database. Can be used to customize Hive instance.
