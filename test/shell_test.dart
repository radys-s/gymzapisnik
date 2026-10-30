import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/welcome/whats_new.dart';

void main() {
  testWidgets('system back walks tab stack, then first tab, then exits', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final exits = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    // Uvítání a souhlas testuje consent_flow_test; tady rovnou do aplikace.
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.finishWelcome(whatsNewRelease);
    });
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();

    // Podstránka v záložce Pokrok: zpět ji zavře, lišta zůstává.
    await tester.runAsync(() async {
      await tester.tap(find.text('Pokrok'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(state.profile.lastTab, 1);
    await tester.tap(find.text('Cviky a rekordy'));
    await tester.pumpAndSettle();
    expect(find.text('Cviky'), findsWidgets);
    expect(find.text('Strava'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Cviky a rekordy'), findsOneWidget);

    // Ze Stravy vede zpět na Trénink a záložka se pamatuje.
    await tester.runAsync(() async {
      await tester.tap(find.text('Strava'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(state.profile.lastTab, 2);
    // Návrat na první záložku ukládá profil, proto v reálném čase.
    await tester.runAsync(() async {
      await tester.binding.handlePopRoute();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Vybrat podle sebe'), findsOneWidget);
    expect(exits, isEmpty);

    // Kořen první záložky: aplikace se zavře (žádná smyčka).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(state.profile.lastTab, 0);
    expect(exits, ['SystemNavigator.pop']);
  });
}
