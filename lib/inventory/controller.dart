import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/import_report.dart';
import '../core/report.dart';

abstract interface class InventoryStorage {
  Future<String?> read();
  Future<void> write(String? value);
}

class LocalInventoryStorage implements InventoryStorage {
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();
  @override
  Future<String?> read() => _store.getString('netscan.inventory.v1');
  @override
  Future<void> write(String? value) => value == null
      ? _store.remove('netscan.inventory.v1')
      : _store.setString('netscan.inventory.v1', value);
}

class DeviceRecord {
  DeviceRecord(this.host, {String? name, this.group = 'unknown'})
    : name = name ?? host;
  final String host;
  String name, group;
  final Set<String> advertisedServices = {};
  final List<ScanReport> history = [];
}

class InventoryController extends ChangeNotifier {
  InventoryController({InventoryStorage? storage})
    : _storage = storage ?? LocalInventoryStorage();
  final InventoryStorage _storage;
  final devices = <String, DeviceRecord>{};
  Future<void> _pendingWrite = Future.value();
  bool persistent = false, storageFailed = false, _closed = false;
  @override
  void notifyListeners() {
    if (!_closed) super.notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  Future<void> restore() async {
    try {
      final raw = await _storage.read();
      if (raw == null || _closed) return;
      final reports = importReports(raw);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final metadata = data['devices'] as List<dynamic>? ?? [];
      if (metadata.length > 256) {
        throw const FormatException('Inventory too large');
      }
      for (final report in reports) {
        addReport(report, notify: false);
      }
      for (final info in metadata) {
        final host = info['host'] as String, name = info['name'] as String;
        if (host.length > 64 || name.length > 200) {
          throw const FormatException('Invalid metadata');
        }
        if (devices.length >= 256 && !devices.containsKey(host)) continue;
        final record = devices.putIfAbsent(host, () => DeviceRecord(host));
        record.name = name;
        record.group =
            ['trusted', 'iot', 'guest', 'unknown'].contains(info['group'])
            ? info['group'] as String
            : 'unknown';
      }
      persistent = true;
    } catch (_) {
      storageFailed = true;
    }
    notifyListeners();
  }

  void addDiscovery(String host, String name, String service) {
    if (_closed || (devices.length >= 256 && !devices.containsKey(host))) {
      return;
    }
    final record = devices.putIfAbsent(
      host,
      () => DeviceRecord(host, name: name),
    );
    record.advertisedServices.add(service);
    notifyListeners();
  }

  void addReport(ScanReport report, {bool notify = true}) {
    if (_closed ||
        (devices.length >= 256 && !devices.containsKey(report.host))) {
      return;
    }
    final record = devices.putIfAbsent(
      report.host,
      () => DeviceRecord(report.host),
    );
    if (record.name == report.host && report.identity != null) {
      record.name = '${report.identity!.manufacturer} ${report.identity!.model}'
          .trim();
    }
    record.history.insert(0, report);
    if (record.history.length > 2) record.history.removeLast();
    if (notify) flush();
  }

  void setGroup(String host, String group) {
    devices[host]?.group = group;
    flush();
  }

  void flush() {
    notifyListeners();
    if (persistent) _write(export());
  }

  String export() => const JsonEncoder.withIndent('  ').convert({
    'format': 'netscan-inventory-v1',
    'reports': [
      for (final d in devices.values)
        for (final r in d.history.reversed) r.toJson(),
    ],
    'devices': [
      for (final d in devices.values)
        {'host': d.host, 'name': d.name, 'group': d.group},
    ],
  });
  Future<void> setPersistent(bool value) async {
    persistent = value;
    await _write(value ? export() : null);
    notifyListeners();
  }

  Future<void> clear() async {
    devices.clear();
    persistent = false;
    await _write(null);
    notifyListeners();
  }

  Future<void> _write(String? snapshot) {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _storage.write(snapshot);
        storageFailed = false;
      } catch (_) {
        storageFailed = true;
        notifyListeners();
      }
    });
    return _pendingWrite;
  }
}
