import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatefulWidget {
  final void Function(String) onSend;
  final VoidCallback? onStop;
  final bool enabled;
  final bool streaming;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onStop,
    this.enabled = true,
    this.streaming = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _canSend) setState(() => _canSend = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.enabled && !widget.streaming;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.enter):
                      _SendIntent(),
                  SingleActivator(LogicalKeyboardKey.enter, shift: true):
                      _NewlineIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _SendIntent: CallbackAction<_SendIntent>(
                      onInvoke: (_) {
                        _submit();
                        return null;
                      },
                    ),
                    _NewlineIntent: CallbackAction<_NewlineIntent>(
                      onInvoke: (_) {
                        final sel = _ctrl.selection;
                        final txt = _ctrl.text;
                        final start = sel.start < 0 ? txt.length : sel.start;
                        final end = sel.end < 0 ? txt.length : sel.end;
                        _ctrl.value = TextEditingValue(
                          text: txt.replaceRange(start, end, '\n'),
                          selection:
                              TextSelection.collapsed(offset: start + 1),
                        );
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    enabled: enabled,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: widget.streaming
                          ? 'Asystent odpowiada…'
                          : 'Zapytaj o materiał (Enter aby wysłać, Shift+Enter - nowa linia)',
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: scheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: widget.streaming
                  ? scheme.primary
                  : (_canSend && enabled
                      ? scheme.primary
                      : scheme.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.streaming
                    ? widget.onStop
                    : ((_canSend && enabled) ? _submit : null),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    // W trakcie generacji przycisk pełni rolę zatrzymania.
                    widget.streaming ? Icons.stop_rounded : Icons.send_rounded,
                    color: widget.streaming
                        ? scheme.onPrimary
                        : (_canSend && enabled
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}

class _NewlineIntent extends Intent {
  const _NewlineIntent();
}
