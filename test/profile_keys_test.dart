import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/push.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/domain/profile_keys.dart';
import 'package:gymzapisnik/state/app_state.dart';

void main() {
  test('profile survives a JSON round trip with every key', () {
    final p = const Profile().withExtra({
      ProfileKey.weekGoal: 4,
      ProfileKey.trainingDays: [1, 3, 5],
      ProfileKey.reminder: 18 * 60,
      ProfileKey.restSeconds: 90,
      ProfileKey.restByExercise: {'bench_press': 180},
      ProfileKey.weightStep: 1.25,
      ProfileKey.proteinTarget: 140,
      ProfileKey.split: 'ppl',
      ProfileKey.tab: 2,
      ProfileKey.welcomeSeen: true,
      ProfileKey.seenVersion: '1.0.0',
      ProfileKey.aiNotice: true,
      ProfileKey.pro: true,
      'fromNewerVersion': {'kept': true},
    });
    final back = Profile.fromJson(p.toJson());

    expect(back.extra, p.extra);
    expect(back.weekGoal, 4);
    expect(back.trainingDays, [1, 3, 5]);
    expect(back.reminderMinutes, 18 * 60);
    expect(back.restSeconds, 90);
    expect(back.restFor('bench_press'), 180);
    expect(back.weightStep, 1.25);
    expect(back.proteinTarget, 140);
    expect(back.splitId, 'ppl');
    expect(back.lastTab, 2);
    expect(back.welcomeSeen, isTrue);
    expect(back.seenVersion, '1.0.0');
    expect(back.aiNoticeAccepted, isTrue);
    expect(back.isPro, isTrue);
    expect(back.extra['fromNewerVersion'], {'kept': true});
  });

  test('legacy tab keys still map to the right tab', () {
    Profile tab(Map<String, dynamic> extra) => Profile(extra: extra);
    expect(tab({ProfileKey.legacyTab: 1}).lastTab, 3);
    expect(tab({ProfileKey.legacyTab: 2}).lastTab, 2);
    expect(tab({ProfileKey.legacyLastTab: 1}).lastTab, 2);
    expect(tab({ProfileKey.tab: 1, ProfileKey.legacyTab: 2}).lastTab, 1);
    expect(tab({}).lastTab, 0);
  });

  test('every key the app writes is a known ProfileKey', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();

    await state.acceptConsent(
      adult: true,
      guardianConsent: false,
      welcomeVersion: '1.0.0',
      aiNotice: true,
    );
    await state.setPreferences(restSeconds: 90, weightStep: 5);
    await state.setExerciseRest('bench_press', 150);
    await state.setFrequency(days: [1, 4]);
    await state.setSplit('ppl');
    await state.setNutritionTargets(protein: 150, kcal: 2500);
    await state.setLastTab(2);
    await state.markBackedUp();
    await state.markVersionSeen('1.0.1');
    await state.setOnboardingStep(2);
    await state.setWeekFocus(FocusKind.values.first);

    final unknown = state.profile.extra.keys.toSet().difference(ProfileKey.all);
    expect(unknown, isEmpty);
    expect(state.profile.extra.keys, contains(ProfileKey.weekFocus));
  });
}
