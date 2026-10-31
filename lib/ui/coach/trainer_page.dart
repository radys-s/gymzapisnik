import 'package:flutter/material.dart';

import '../../ai/fridge_coach.dart';
import '../../ai/trainer.dart';
import '../../coach/local_coach.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../program/program_page.dart';
import '../widgets/ai_photo.dart';

/// Otázky do začátku. Jen o tréninku, nic o hubnutí.
const trainerSuggestions = [
  'Co mám dnes cvičit?',
  'Kde nejvíc stagnuju a co s tím?',
  'Čím nahradit dřepy, když bolí koleno?',
  'Kolik sérií týdně dávám na partii?',
  'Jak rozložit tréninky do konce týdne?',
];

/// Chat s AI trenérem. Trenér vidí jen krátký souhrn tréninků
/// ([AppState.trainerContext]), chat zůstává v zařízení.
class TrainerPage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;

  /// Začne dnešní trénink (trenér se před tím zavře).
  final VoidCallback? onStartToday;
  const TrainerPage(
    this.state, {
    super.key,
    this.now = DateTime.now,
    this.onStartToday,
  });

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> {
  late List<ChatMessage> messages = widget.state.coachChat;
  final input = TextEditingController();
  final scroll = ScrollController();
  bool waiting = false;
  bool sending = false;
  String? error;

  /// Opakovat má smysl jen u výpadku, ne u limitu nebo vypnuté AI.
  bool retryable = true;
  int requestId = 0;

  AppState get state => widget.state;

  @override
  void dispose() {
    _cancel();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _cancel() {
    requestId++;
    final trainer = state.trainer;
    if (trainer is CancellableFridgeCoach) {
      (trainer as CancellableFridgeCoach).cancelPending();
    }
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _save() async {
    try {
      await state.saveCoachChat(messages);
    } catch (_) {
      if (mounted) showToast(context, 'Chat se nepodařilo uložit.');
    }
  }

  Future<void> _send([String? text]) async {
    final question = (text ?? input.text).trim();
    if (question.isEmpty || waiting || sending) return;
    // Hned, ještě před prvním čekáním: dvojí klepnutí (Enter + tlačítko)
    // nesmí poslat otázku dvakrát a utratit dva dotazy z denního limitu.
    sending = true;
    try {
      await _sendChecked(question, text);
    } finally {
      sending = false;
    }
  }

  Future<void> _sendChecked(String question, String? text) async {
    final intent = classifyQuestion(question);
    // Na dnešní plán odpoví aplikace sama, hned a stejně jako hlavní karta.
    final instant = intent == CoachIntent.today || !state.trainer.enabled;
    if (!instant && (!await confirmAiNotice(context, state) || !mounted)) {
      return;
    }
    if (text == null) input.clear();
    setState(() {
      messages = _capped([
        ...messages,
        ChatMessage(
          ChatRole.user,
          question.length > maxChatMessage
              ? question.substring(0, maxChatMessage)
              : question,
          widget.now(),
        ),
      ]);
      error = null;
    });
    if (instant) {
      _reply(
        localAnswer(intent, state.coachFacts(widget.now())) ??
            'Na tohle potřebuju AI, která teď v aplikaci není zapnutá. '
                'Zkus jednu z otázek níž, na ty odpovím z tvých dat.',
        local: true,
      );
      await _save();
      _toEnd();
      return;
    }
    await _save();
    await _ask();
  }

  void _reply(String text, {bool local = false}) => setState(() {
    messages = _capped([
      ...messages,
      ChatMessage(ChatRole.assistant, text, widget.now(), local: local),
    ]);
  });

  /// V paměti stejně jako na disku jen posledních [maxCoachChat] zpráv.
  static List<ChatMessage> _capped(List<ChatMessage> list) =>
      list.length > maxCoachChat
      ? list.sublist(list.length - maxCoachChat)
      : list;

  /// Zeptá se na poslední zprávu uživatele (i po chybě znovu).
  Future<void> _ask() async {
    if (!mounted || messages.isEmpty) return;
    final request = ++requestId;
    setState(() {
      waiting = true;
      error = null;
    });
    _toEnd();
    final result = await state.trainer.ask(
      aiHistory(messages),
      state.trainerContext(widget.now()),
      adult: state.profile.adult,
    );
    if (!mounted || request != requestId) return;
    switch (result) {
      case AiOk(:final value):
        waiting = false;
        _reply(tidyReply(value));
        await _save();
      case AiError(:final message, :final kind):
        final question = messages.last.content;
        final local = localAnswer(
          classifyQuestion(question),
          state.coachFacts(widget.now()),
        );
        setState(() {
          waiting = false;
          error = local == null
              ? message
              : '$message Odpověď níž je jen z tvých dat.';
          retryable =
              local == null &&
              kind != AiErrorKind.quota &&
              kind != AiErrorKind.disabled;
        });
        if (local != null) {
          _reply(local, local: true);
          await _save();
        }
    }
    _toEnd();
  }

  ChatMessage _brief(CoachFacts f) =>
      ChatMessage(ChatRole.assistant, briefing(f, widget.now()), widget.now());

  List<_Action> _actionsFor(CoachIntent intent, CoachFacts f) {
    final start = widget.onStartToday;
    return [
      if (intent == CoachIntent.today && start != null && f.canStart)
        (
          label: 'Začít ${f.day}',
          icon: Icons.play_arrow_rounded,
          onTap: () {
            Navigator.of(context).pop();
            start();
          },
        ),
      if (intent == CoachIntent.today ||
          intent == CoachIntent.week ||
          intent == CoachIntent.stall)
        (
          label: 'Otevřít program',
          icon: Icons.view_week_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => ProgramPage(state))),
        ),
    ];
  }

  Future<void> _clear() async {
    final ok = await confirmAction(
      context,
      title: 'Smazat chat?',
      message: 'Zprávy s trenérem zmizí z tohoto zařízení.',
      confirm: 'Smazat',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _cancel();
    setState(() {
      messages = [];
      waiting = false;
      error = null;
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final enabled = state.trainer.enabled;
    final last = messages.lastOrNull;
    // Fakta jen tam, kde se ukazují: úvodní přehled a akce pod odpovědí.
    final facts = last == null || last.role == ChatRole.assistant
        ? state.coachFacts(widget.now())
        : null;
    // I bez chyby: otázka zůstala bez odpovědi (třeba po zavření aplikace).
    final canRetry =
        retryable && !waiting && last?.role == ChatRole.user && enabled;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trenér'),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'Smazat chat',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _clear,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                Space.s,
                Space.page,
                Space.l,
              ),
              children: [
                if (!enabled)
                  Panel(
                    child: Text(
                      'AI v této verzi není zapnutá. Na otázky níž odpovím '
                      'z tvých tréninků, bez internetu.',
                      style: text.bodyMedium,
                    ),
                  ),
                if (messages.isEmpty) ...[
                  Reveal(child: _Bubble(_brief(facts!))),
                  Reveal(
                    index: 1,
                    child: _Actions(_actionsFor(CoachIntent.today, facts)),
                  ),
                  const SizedBox(height: Space.l),
                  Reveal(
                    index: 2,
                    child: Text(
                      'Trenér vidí tvůj program, poslední tréninky, rekordy '
                      'a regeneraci. Neví tvoje jméno ani poznámky.',
                      style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  Reveal(
                    index: 3,
                    child: Wrap(
                      spacing: Space.s,
                      runSpacing: Space.s,
                      children: [
                        for (final q in trainerSuggestions)
                          _QuestionChip(
                            q,
                            onTap: !waiting ? () => _send(q) : null,
                          ),
                      ],
                    ),
                  ),
                ],
                for (final (i, m) in messages.indexed) ...[
                  _Bubble(m),
                  if (m.role == ChatRole.assistant &&
                      i > 0 &&
                      i == messages.length - 1)
                    _Actions(
                      _actionsFor(
                        classifyQuestion(messages[i - 1].content),
                        facts!,
                      ),
                    ),
                ],
                // Další otázky, na které se ještě nezeptal.
                if (last?.role == ChatRole.assistant && !waiting)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.l),
                    child: Wrap(
                      spacing: Space.s,
                      runSpacing: Space.s,
                      children: [
                        for (final q in trainerSuggestions)
                          if (!messages.any((m) => m.content == q))
                            _QuestionChip(q, onTap: () => _send(q)),
                      ],
                    ),
                  ),
                if (waiting)
                  Semantics(liveRegion: true, child: const _Bubble(null)),
                if (error != null || canRetry)
                  Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (error case final e?)
                            Text(
                              e,
                              style: text.bodySmall?.copyWith(
                                color: p.negative,
                              ),
                            ),
                          if (canRetry)
                            TextButton.icon(
                              onPressed: _ask,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Zkusit znovu'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                Space.xs,
                Space.s,
                Space.s,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          enabled: enabled,
                          minLines: 1,
                          maxLines: 5,
                          maxLength: maxChatMessage,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            hintText: 'Zeptej se trenéra',
                            counterText: '',
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: Space.xs),
                      ListenableBuilder(
                        listenable: input,
                        builder: (context, _) => IconButton.filled(
                          tooltip: 'Odeslat',
                          constraints: const BoxConstraints.tightFor(
                            width: minTap + 4,
                            height: minTap + 4,
                          ),
                          onPressed:
                              enabled &&
                                  !waiting &&
                                  input.text.trim().isNotEmpty
                              ? _send
                              : null,
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'AI se může splést. Nenahrazuje lékaře ani trenéra '
                    'naživo; při bolesti přestaň.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: p.tertiaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Akce pod odpovědí trenéra.
typedef _Action = ({String label, IconData icon, VoidCallback onTap});

class _Actions extends StatelessWidget {
  final List<_Action> actions;
  const _Actions(this.actions);

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Wrap(
        spacing: Space.s,
        runSpacing: Space.s,
        children: [
          for (final (i, a) in actions.indexed)
            i == 0
                ? FilledButton.icon(
                    onPressed: a.onTap,
                    icon: Icon(a.icon),
                    label: Text(a.label),
                  )
                : OutlinedButton.icon(
                    onPressed: a.onTap,
                    icon: Icon(a.icon),
                    label: Text(a.label),
                  ),
        ],
      ),
    );
  }
}

/// Bublina zprávy; `null` = trenér píše.
class _Bubble extends StatelessWidget {
  final ChatMessage? message;
  const _Bubble(this.message);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final m = message;
    final mine = m?.role == ChatRole.user;
    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.82,
      ),
      margin: const EdgeInsets.only(top: Space.s),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.m + 2,
        vertical: Space.m - 2,
      ),
      decoration: BoxDecoration(
        color: mine ? p.accent : p.elevated,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: m == null
          ? Text(
              'Trenér píše…',
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            )
          : SelectableText(
              m.content,
              style: text.bodyLarge?.copyWith(
                color: mine ? p.onAccent : p.label,
              ),
            ),
    );
    return Semantics(
      label: m == null ? null : (mine ? 'Ty' : 'Trenér'),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}

/// Navržená otázka. Čtečka ji ohlásí jako tlačítko (čip by na webu
/// hlásila jako zaškrtávací políčko).
class _QuestionChip extends StatelessWidget {
  final String question;
  final VoidCallback? onTap;
  const _QuestionChip(this.question, {this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: question,
    onTap: onTap,
    excludeSemantics: true,
    child: ActionChip(label: Text(question), onPressed: onTap),
  );
}
