import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/core/report.dart';
import 'package:netscan/inventory/controller.dart';

class MemoryStorage implements InventoryStorage {
  String? value;
  final writes = <String?>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? next) async {
    await Future<void>.delayed(Duration.zero);
    value = next;
    writes.add(next);
  }
}

void main() {
  test(
    'inventory does not persist until requested; deletion follows pending saves',
    () async {
      final storage = MemoryStorage();
      final inventory = InventoryController(storage: storage);
      inventory.addReport(
        const ScanReport(
          host: '192.168.1.1',
          method: 'tcp',
          message: 'scan.complete',
        ),
      );
      expect(storage.writes, isEmpty);
      await inventory.setPersistent(true);
      expect(storage.value, contains('192.168.1.1'));
      inventory.setGroup('192.168.1.1', 'iot');
      await inventory.clear();
      expect(storage.value, isNull);
      expect(storage.writes.last, isNull);
      expect(inventory.devices, isEmpty);
      inventory.dispose();
    },
  );
  test(
    'saved inventory restores two reports with provenance and group',
    () async {
      final storage = MemoryStorage();
      final first = InventoryController(storage: storage);
      for (final port in [80, 443, 22]) {
        first.addReport(
          ScanReport(
            host: '192.168.1.2',
            method: 'tcp',
            message: 'scan.complete',
            ports: [PortObservation(port, true)],
          ),
        );
      }
      first.setGroup('192.168.1.2', 'trusted');
      await first.setPersistent(true);
      final restored = InventoryController(storage: storage);
      await restored.restore();
      expect(restored.devices.values.single.history.length, 2);
      expect(restored.devices.values.single.group, 'trusted');
      expect(restored.devices.values.single.history.first.imported, isTrue);
      first.dispose();
      restored.dispose();
    },
  );
}
