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

    // Závod (výchozí) je jen tmavý: světlý motiv jde jen v jiném vzhledu.
    expect(find.text('Světlý'), findsNothing);
    await tester.runAsync(() => state.setPreferences(look: 'aurora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Světlý'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(state.profile.theme, 'light');
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    await tester.tap(find.text('Uložit zálohu'));
    await tester.pumpAndSettle();
    expect(files.saved.keys.single, startsWith('gymzapisnik-zaloha-'));
    expect(find.textContaining('Uloženo:'), findsOneWidget);

    files.toOpen = 'not a backup';
    await tester.tap(find.text('Obnovit ze zálohy'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.textContaining('není platná záloha'), findsOneWidget);

    await tester.tap(find.text('Smazat všechna data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat vše'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    // Po smazání začíná aplikace znovu uvítáním.
    expect(find.text('Přeskočit'), findsOneWidget);
    expect(state.profile.hasValidConsent, isFalse);
  });
}
