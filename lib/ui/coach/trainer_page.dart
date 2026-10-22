import 'package:flutter/material.dart';

import '../../ai/fridge_coach.dart';
import '../../ai/trainer.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
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
  const TrainerPage(this.state, {super.key, this.now = DateTime.now});

  @override
  State<TrainerPage> createState() => _TrainerPageState();
}

class _TrainerPageState extends State<TrainerPage> {
  late List<ChatMessage> messages = widget.state.coachChat;
  final input = TextEditingController();
  final scroll = ScrollController();
  bool waiting = false;
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
    if (question.isEmpty || waiting) return;
    if (!await confirmAiNotice(context, state) || !mounted) return;
    if (text == null) input.clear();
    setState(() {
      messages = [
        ...messages,
        ChatMessage(
          ChatRole.user,
          question.length > maxChatMessage
              ? question.substring(0, maxChatMessage)
              : question,
          widget.now(),
        ),
      ];
      error = null;
    });
    await _save();
    await _ask();
  }

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
      messages,
      state.trainerContext(widget.now()),
      adult: state.profile.adult,
    );
    if (!mounted || request != requestId) return;
    switch (result) {
      case AiOk(:final value):
        setState(() {
          waiting = false;
          messages = [
            ...messages,
            ChatMessage(ChatRole.assistant, value, widget.now()),
          ];
        });
        await _save();
      case AiError(:final message, :final kind):
        setState(() {
          waiting = false;
          error = message;
          retryable = kind != AiErrorKind.quota && kind != AiErrorKind.disabled;
        });
    }
    _toEnd();
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
                      'Trenér zatím není dostupný. V této verzi aplikace '
                      'AI není zapnutá. Co dnes cvičit ukazuje hlavní karta '
                      'v Cvičení.',
                      style: text.bodyMedium,
                    ),
                  ),
                if (messages.isEmpty) ...[
                  const SizedBox(height: Space.l),
                  Text('Na co se chceš zeptat?', style: text.titleLarge),
                  const SizedBox(height: Space.s),
                  Text(
                    'Trenér vidí tvůj program, poslední tréninky, rekordy '
                    'a regeneraci. Neví tvoje jméno ani poznámky.',
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                  const SizedBox(height: Space.l),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.s,
                    children: [
                      for (final q in trainerSuggestions)
                        ActionChip(
                          label: Text(q),
                          onPressed: enabled && !waiting
                              ? () => _send(q)
                              : null,
                        ),
                    ],
                  ),
                ],
                for (final m in messages) _Bubble(m),
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
