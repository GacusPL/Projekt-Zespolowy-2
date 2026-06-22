import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/conversation.dart';

class ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final Conversation? active;
  final void Function(Conversation) onOpen;
  final void Function(Conversation) onDelete;
  final VoidCallback onNew;
  final bool loading;

  const ConversationList({
    super.key,
    required this.conversations,
    required this.active,
    required this.onOpen,
    required this.onDelete,
    required this.onNew,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: FilledButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nowa rozmowa'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'HISTORIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Brak rozmów.\nKliknij "Nowa rozmowa" by zacząć.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (_, i) {
                          final c = conversations[i];
                          final isActive = c.id == active?.id;
                          return _ConvTile(
                            conv: c,
                            active: isActive,
                            onTap: () => onOpen(c),
                            onDelete: () => onDelete(c),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _ConvTile({
    required this.conv,
    required this.active,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d.MM HH:mm', 'pl_PL');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: active
            ? scheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFmt.format(conv.updatedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.close,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: onDelete,
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
