import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/chat_history_service.dart';
import '../../../services/gemini/gemini_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../utils/date_formatter.dart';
import '../widgets/voice_record_button.dart';

class _Msg {
  final String id;
  final String text;
  final bool isUser;
  final bool isVoice;
  final bool isError;
  final DateTime at;
  const _Msg({
    required this.id,
    required this.text,
    required this.isUser,
    required this.at,
    this.isVoice = false,
    this.isError = false,
  });
}

/// GreenBot.
///
/// - Messages écrits ou vocaux : le bouton micro (maintien, ou glissé vers le
///   haut pour verrouiller) enregistre ; à l'arrêt, le vocal est transcrit
///   par Gemini, affiché comme message de l'utilisateur, puis GreenBot répond.
/// - Barre de saisie toujours visible au-dessus du clavier et de la barre
///   de navigation (elle était masquée par la barre flottante en v1).
class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final String? cacheKey;
  final bool autoSend;

  const ChatScreen({super.key, this.initialMessage, this.cacheKey, this.autoSend = true});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _voice = VoiceRecordController();
  final List<_Msg> _messages = [];
  bool _thinking = false;
  bool _transcribing = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreCurrent());
  }

  @override
  void didUpdateWidget(ChatScreen old) {
    super.didUpdateWidget(old);
    // Nouvelle question envoyée depuis une fiche terrain alors que l'onglet
    // GreenBot était déjà ouvert.
    if (widget.initialMessage != null && widget.initialMessage != old.initialMessage) {
      _startFromPrompt();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _restoreCurrent() async {
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      await _startFromPrompt();
      return;
    }
    final current = chatHistoryService.getCurrentSession();
    if (current != null) _showSession(current);
  }

  Future<void> _startFromPrompt() async {
    await chatHistoryService.createNewSession();
    if (!mounted) return;
    setState(_messages.clear);
    if (widget.autoSend) {
      await _send(widget.initialMessage!, cacheKey: widget.cacheKey);
    } else {
      _input.text = widget.initialMessage!;
    }
  }

  void _showSession(ChatSession s) {
    setState(() {
      _messages
        ..clear()
        ..addAll(s.messages.map((m) => _Msg(
              id: m.id,
              text: m.content,
              isUser: m.role == 'user',
              isVoice: m.kind == 'voice',
              at: m.timestamp,
            )));
    });
    _toBottom(jump: true);
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump || MediaQuery.of(context).disableAnimations) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Easing.standard);
      }
    });
  }

  String _errorText(Object e, String Function(String) t) {
    final code = e is GreenBotException ? e.code : 'unknown';
    return switch (code) {
      'no-key' => t('serviceUnavailableMessage'),
      'network' => t('networkErrorMessage'),
      'quota' => t('botQuotaMessage'),
      'busy' => t('botBusyMessage'),
      'blocked' => t('botBlockedMessage'),
      _ => t('genericErrorMessage'),
    };
  }

  Future<void> _send(String raw, {String? cacheKey, bool isVoice = false}) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;
    final l = context.read<LocaleProvider>();
    final history = _messages.where((m) => !m.isError).map((m) => (isUser: m.isUser, text: m.text)).toList();
    final userMsg = _Msg(id: UniqueKey().toString(), text: text, isUser: true, isVoice: isVoice, at: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _thinking = true;
    });
    _input.clear();
    _toBottom();
    await chatHistoryService.addMessageToCurrentSession(
      ChatMessage(role: 'user', content: text, timestamp: userMsg.at, kind: isVoice ? 'voice' : 'text'),
    );

    try {
      final answer = cacheKey != null
          ? await geminiService.adviceWithCache(text, cacheKey, language: l.locale)
          : await geminiService.reply(text, history: history, language: l.locale);
      final botMsg = _Msg(id: UniqueKey().toString(), text: answer, isUser: false, at: DateTime.now());
      await chatHistoryService.addMessageToCurrentSession(
        ChatMessage(role: 'assistant', content: answer, timestamp: botMsg.at),
      );
      final current = chatHistoryService.getCurrentSession();
      if (current != null && current.messages.length <= 2) {
        await chatHistoryService.updateCurrentSessionTitle(text.length > 40 ? '${text.substring(0, 40)}…' : text);
      }
      if (!mounted) return;
      setState(() {
        _messages.add(botMsg);
        _thinking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(id: UniqueKey().toString(), text: _errorText(e, l.t), isUser: false, isError: true, at: DateTime.now()));
        _thinking = false;
      });
    }
    _toBottom();
  }

  Future<void> _onVoice(Uint8List wav) async {
    final l = context.read<LocaleProvider>();
    setState(() => _transcribing = true);
    _toBottom();
    try {
      final transcript = await geminiService.transcribe(wav, language: l.locale);
      if (!mounted) return;
      setState(() => _transcribing = false);
      if (transcript.inaudible) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('voiceInaudible'))));
        return;
      }
      await _send(transcript.text, isVoice: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transcribing = false;
        _messages.add(_Msg(id: UniqueKey().toString(), text: _errorText(e, l.t), isUser: false, isError: true, at: DateTime.now()));
      });
      _toBottom();
    }
  }

  void _snack(String key) {
    final t = context.read<LocaleProvider>().t;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(t(key)), duration: const Duration(seconds: 2)));
  }

  Future<void> _newChat() async {
    await chatHistoryService.createNewSession();
    if (mounted) setState(_messages.clear);
  }

  Future<void> _openSessions() async {
    final t = context.read<LocaleProvider>().t;
    final locale = context.read<LocaleProvider>().locale;
    final sessions = await chatHistoryService.getAllSessions();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => StatefulBuilder(
          builder: (ctx, setSheet) => sessions.isEmpty
              ? EmptyState(icon: Icons.forum_outlined, title: t('noDiscussionYet'))
              : ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: sessions.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Text(t('conversations'), style: Theme.of(ctx).textTheme.titleLarge),
                      );
                    }
                    final s = sessions[i - 1];
                    final active = chatHistoryService.getCurrentSession()?.id == s.id;
                    return ListTile(
                      selected: active,
                      leading: const Icon(Icons.chat_bubble_outline_rounded),
                      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatDateTime(s.updatedAt, locale)),
                      onTap: () async {
                        await chatHistoryService.switchToSession(s.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSession(s);
                      },
                      trailing: IconButton(
                        tooltip: t('delete'),
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          final wasActive = active;
                          await chatHistoryService.deleteSession(s.id);
                          setSheet(() => sessions.removeWhere((x) => x.id == s.id));
                          if (wasActive && mounted) setState(_messages.clear);
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final user = context.watch<AuthProvider>().currentUser;
    final busy = _thinking || _transcribing;

    return Scaffold(
      appBar: CustomAppBar(
        title: t('greenBot'),
        showProfileIcon: true,
        actions: [
          IconButton(tooltip: t('chatHistory'), onPressed: _openSessions, icon: const Icon(Icons.forum_outlined)),
          IconButton(tooltip: t('newDiscussion'), onPressed: busy ? null : _newChat, icon: const Icon(Icons.add_comment_outlined)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !busy
                ? _Welcome(onPick: (q) => _send(q), userName: (user?.name ?? '').split(' ').first)
                : ListView.builder(
                    controller: _scroll,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length + (busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return _TypingBubble(label: t(_transcribing ? 'transcribing' : 'greenBotTyping'));
                      }
                      final m = _messages[i];
                      return _Bubble(msg: m, voiceLabel: t('voiceMessage'));
                    },
                  ),
          ),
          _Composer(
            input: _input,
            voice: _voice,
            busy: busy,
            t: t,
            onSend: () => _send(_input.text),
            onVoice: _onVoice,
            onPermissionDenied: () => _snack('micPermissionDenied'),
            onPermissionGranted: () => _snack('micPermissionGranted'),
            onTooShort: () => _snack('holdToRecord'),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController input;
  final VoiceRecordController voice;
  final bool busy;
  final String Function(String) t;
  final VoidCallback onSend;
  final ValueChanged<Uint8List> onVoice;
  final VoidCallback onPermissionDenied;
  final VoidCallback onPermissionGranted;
  final VoidCallback onTooShort;

  const _Composer({
    required this.input,
    required this.voice,
    required this.busy,
    required this.t,
    required this.onSend,
    required this.onVoice,
    required this.onPermissionDenied,
    required this.onPermissionGranted,
    required this.onTooShort,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = input.text.trim().isNotEmpty;
    return Material(
      color: scheme.surface,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: ListenableBuilder(
            listenable: voice,
            builder: (context, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: voice.isRecording
                      ? RecordingBar(controller: voice, slideToCancel: t('slideToCancel'), cancelTooltip: t('cancel'))
                      : TextField(
                          controller: input,
                          enabled: !busy,
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          inputFormatters: [LengthLimitingTextInputFormatter(1500)],
                          decoration: InputDecoration(
                            hintText: t('askYourQuestion'),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(26)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26),
                              borderSide: BorderSide(color: scheme.outlineVariant),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26),
                              borderSide: BorderSide(color: scheme.primary, width: 2),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: hasText && !voice.isRecording
                          ? IconButton.filled(
                              key: const ValueKey('send'),
                              tooltip: t('send'),
                              iconSize: 24,
                              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                              onPressed: busy ? null : onSend,
                              icon: const Icon(Icons.send_rounded),
                            )
                          : VoiceRecordButton(
                              key: const ValueKey('mic'),
                              controller: voice,
                              enabled: !busy,
                              tooltip: t('voiceButtonHint'),
                              onRecorded: onVoice,
                              onPermissionDenied: onPermissionDenied,
                              onPermissionGranted: onPermissionGranted,
                              onTooShort: onTooShort,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  final String voiceLabel;
  const _Bubble({required this.msg, required this.voiceLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = msg.isUser;
    final bg = msg.isError
        ? scheme.errorContainer
        : user
            ? scheme.primary
            : scheme.surfaceContainerHigh;
    final fg = msg.isError
        ? scheme.onErrorContainer
        : user
            ? scheme.onPrimary
            : scheme.onSurface;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(user ? 18 : 4),
              bottomRight: Radius.circular(user ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (msg.isVoice)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, size: 14, color: fg.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(voiceLabel, style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              SelectableText(msg.text, style: theme.textTheme.bodyLarge?.copyWith(color: fg)),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(formatTime(msg.at), style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur « GreenBot écrit… » : trois points qui pulsent doucement
/// (désactivé si les animations sont coupées dans l'accessibilité).
class _TypingBubble extends StatefulWidget {
  final String label;
  const _TypingBubble({required this.label});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: widget.label,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(
                            alpha: 0.3 + 0.7 * (((_c.value * 3 - i) % 3) < 1 ? 1 - ((_c.value * 3 - i) % 3) : 0),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final ValueChanged<String> onPick;
  final String userName;
  const _Welcome({required this.onPick, required this.userName});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = Theme.of(context);
    final suggestions = [t('chatSuggestion1'), t('chatSuggestion2'), t('chatSuggestion3'), t('chatSuggestion4')];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.eco_rounded, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          userName.isEmpty ? t('botWelcomeTitle') : l.tf('botWelcomeTitleName', {'name': userName}),
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(t('botWelcomeText'), style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.all(14)),
              onPressed: () => onPick(s),
              child: Text(s),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_none_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(child: Text(t('voiceTip'), style: theme.textTheme.bodySmall)),
          ],
        ),
      ],
    );
  }
}
