import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/welcome/whats_new.dart';
import 'package:gymzapisnik/ui/settings/file_io.dart';
import 'package:gymzapisnik/ui/settings/settings_page.dart';

class FakeFiles implements FileIo {
  final saved = <String, String>{};
  String? toOpen;

  @override
  Future<bool> saveText(String name, String content, String mimeType) async {
    saved[name] = content;
    return true;
  }

  @override
  Future<String?> pickText(List<String> extensions) async => toOpen;
}

void main() {
  testWidgets('settings change rest, theme, export and wipe data', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.markVersionSeen(whatsNewRelease);
    });
    await tester.binding.setSurfaceSize(const Size(400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final files = FakeFiles();
    await tester.pumpWidget(GymApp(state));
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute(builder: (_) => SettingsPage(state, files: files)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('2 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1:30 min').last);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(state.profile.restSeconds, 90);

    // Jeden vzhled, vždy tmavý: volba světla ani motivu už není.
    expect(find.text('Světlý'), findsNothing);
    expect(find.text('Vzhled a barva'), findsNothing);

    await tester.tap(find.text('Uložit zálohu'));
    await tester.pumpAndSettle();
    expect(files.saved.keys.single, startsWith('gymzapisnik-zaloha-'));
    expect(find.textContaining('Uloženo:'), findsOneWidget);

    files.toOpen = 'not a backup';
    await tester.tap(find.text('Obnovit ze zálohy'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('není platná záloha'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Smazat všechna data'), 300);
    await tester.tap(find.text('Smazat všechna data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pokračovat'));
    await tester.pumpAndSettle();
    // Bez zaškrtnutí podržení nic nesmaže.
    final hold = find.text('Podrž 3 s pro smazání');
    var gesture = await tester.startGesture(tester.getCenter(hold));
    await tester.pump(const Duration(seconds: 4));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(hold, findsOneWidget);
    await tester.tap(find.text('Rozumím, že se data nedají vrátit'));
    await tester.pump();
    // Krátké podržení se vrátí zpět.
    gesture = await tester.startGesture(tester.getCenter(hold));
    await tester.pump(const Duration(seconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(hold, findsOneWidget);
    gesture = await tester.startGesture(tester.getCenter(hold));
    // První snímek animaci teprve spustí, pak běží 3 s.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('Drž dál…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await gesture.up();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    // Po smazání začíná aplikace znovu uvítáním.
    expect(find.text('Sestavit můj plán'), findsOneWidget);
    expect(state.profile.hasValidConsent, isFalse);
  });
}
