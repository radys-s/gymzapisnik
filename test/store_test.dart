import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';

void main() {
  late AppDatabase db;
  late LocalStore store;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = LocalStore(db);
    await store.open();
  });

  tearDown(() => db.close());

  test('put, get and overwrite a document', () async {
    await store.put('workout', {'id': 'w1', 'name': 'A'});
    await store.put('workout', {'id': 'w1', 'name': 'B'});
    expect((await store.get('w1'))!['name'], 'B');
    expect(await store.all('workout'), hasLength(1));
  });

  test('remove is soft and put revives the row', () async {
    await store.put('workout', {'id': 'w1'});
    await store.remove('w1');
    expect(await store.get('w1'), isNull);
    expect((await store.raw('w1'))!['deleted'], 1);
    await store.put('workout', {'id': 'w1'});
    expect(await store.get('w1'), isNotNull);
  });

  test('all filters by kind', () async {
    await store.put('workout', {'id': 'w1'});
    await store.put('exercise', {'id': 'e1'});
    expect(await store.all('exercise'), [
      {'id': 'e1'},
    ]);
  });

  test('meta and wipe', () async {
    await store.setMeta('k', 'v1');
    await store.setMeta('k', 'v2');
    expect(await store.meta('k'), 'v2');
    await store.put('workout', {'id': 'w1'});
    await store.wipeLocal();
    expect(await store.meta('k'), isNull);
    expect(await store.raw('w1'), isNull);
  });
}
