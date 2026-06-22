import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../domain/entities/conversation.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onCopy,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == MessageRole.user;

    final bg = isUser ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = isUser ? scheme.onPrimary : scheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _avatar(scheme, false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: _content(context, fg),
                  ),
                  if (message.sources.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Źródła:',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...{for (final s in message.sources) s.filename}
                              .map((file) => InkWell(
                                    onTap: () =>
                                        _showSourceSheet(context, file),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: scheme.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        file,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  if (!isStreaming &&
                      message.content.isNotEmpty &&
                      (onCopy != null || onRegenerate != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onCopy != null)
                            _ActionButton(
                              icon: Icons.copy_outlined,
                              tooltip: 'Kopiuj',
                              onTap: onCopy!,
                            ),
                          if (onRegenerate != null)
                            _ActionButton(
                              icon: Icons.refresh,
                              tooltip: 'Regeneruj',
                              onTap: onRegenerate!,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _avatar(scheme, true),
        ],
      ),
    );
  }

  void _showSourceSheet(BuildContext context, String filename) {
    final fragments = message.sources
        .where((s) => s.filename == filename && s.snippet.trim().isNotEmpty)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filename,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Fragmenty użyte w odpowiedzi',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: fragments.isEmpty
                      ? Text(
                          'Podgląd niedostępny dla tej wiadomości.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: fragments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SelectableText(
                              fragments[i].snippet,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, Color fg) {
    if (message.content.isEmpty && isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: fg, delay: 0),
          const SizedBox(width: 4),
          _Dot(color: fg, delay: 200),
          const SizedBox(width: 4),
          _Dot(color: fg, delay: 400),
        ],
      );
    }

    if (message.role == MessageRole.user) {
      return Text(
        message.content,
        style: TextStyle(color: fg, fontSize: 14),
      );
    }
    // Asystent - pełen Markdown z formatowaniem.
    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: TextStyle(color: fg, fontSize: 14, height: 1.45),
        listBullet: TextStyle(color: fg, fontSize: 14),
        h1: TextStyle(color: fg, fontSize: 20, fontWeight: FontWeight.bold),
        h2: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
        h3: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold),
        code: TextStyle(
          color: fg,
          backgroundColor:
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _avatar(ColorScheme scheme, bool isUser) {
    return CircleAvatar(
      radius: 14,
      backgroundColor:
          isUser ? scheme.primary : scheme.tertiaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 14,
        color: isUser ? scheme.onPrimary : scheme.onTertiaryContainer,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final Color color;
  final int delay;
  const _Dot({required this.color, required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
