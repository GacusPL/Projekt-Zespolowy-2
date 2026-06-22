import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../domain/entities/conversation.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  const MessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
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
                          ...message.sources.map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      scheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: scheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )),
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
    // Asystent — pełen Markdown z formatowaniem.
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
