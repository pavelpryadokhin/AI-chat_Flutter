import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';

/// Виджет для отображения пузырька сообщения в чате
class MessageBubble extends StatelessWidget {
  /// Сообщение для отображения
  final ChatMessage message;

  /// Все сообщения в чате (нужно для копирования вопроса и ответа вместе)
  final List<ChatMessage> messages;

  /// Индекс сообщения в списке
  final int index;

  const MessageBubble({
    super.key,
    required this.message,
    required this.messages,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Заголовок сообщения
          _buildMessageHeader(context, isUser, theme),

          // Содержимое сообщения
          _buildMessageContent(context, isUser, theme),

          // Футер с информацией о сообщении
          if (message.tokens != null || message.cost != null)
            _buildMessageFooter(context, isUser, theme),

          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  /// Построение заголовка сообщения
  Widget _buildMessageHeader(
      BuildContext context, bool isUser, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 4.0, right: 4.0),
      child: Text(
        isUser ? 'Вы' : message.modelName ?? 'AI',
        style: TextStyle(
          color:
              isUser ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Построение содержимого сообщения
  Widget _buildMessageContent(
      BuildContext context, bool isUser, ThemeData theme) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primary.withOpacity(0.9)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16.0 : 4.0),
          topRight: Radius.circular(isUser ? 4.0 : 16.0),
          bottomLeft: const Radius.circular(16.0),
          bottomRight: const Radius.circular(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isUser ? 16.0 : 4.0),
          topRight: Radius.circular(isUser ? 4.0 : 16.0),
          bottomLeft: const Radius.circular(16.0),
          bottomRight: const Radius.circular(16.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => _copyMessage(context, isUser),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SelectableText(
                message.cleanContent,
                style: GoogleFonts.roboto(
                  color:
                      isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                  fontSize: 14.0,
                  letterSpacing: 0.2,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Построение футера сообщения
  Widget _buildMessageFooter(
      BuildContext context, bool isUser, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.tokens != null)
            Text(
              'Токенов: ${message.tokens}',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          if (message.tokens != null && message.cost != null)
            const SizedBox(width: 8),
          if (message.cost != null) _buildCostDisplay(context, theme),
          const SizedBox(width: 4),
          _buildCopyButton(context, isUser, theme),
        ],
      ),
    );
  }

  /// Отображение стоимости запроса
  Widget _buildCostDisplay(BuildContext context, ThemeData theme) {
    final isVsetgpt = false; // Для определения валюты (доллары или рубли)

    return Text(
      message.cost! < 0.001
          ? isVsetgpt
              ? 'Стоимость: <0.001₽'
              : 'Стоимость: <\$0.001'
          : isVsetgpt
              ? 'Стоимость: ${message.cost!.toStringAsFixed(3)}₽'
              : 'Стоимость: \$${message.cost!.toStringAsFixed(3)}',
      style: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
        fontSize: 11,
      ),
    );
  }

  /// Кнопка копирования
  Widget _buildCopyButton(BuildContext context, bool isUser, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: () => _copyMessage(context, isUser),
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.copy,
            size: 14.0,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// Копирование сообщения в буфер обмена
  void _copyMessage(BuildContext context, bool isUser) {
    final textToCopy = isUser
        ? message.cleanContent
        : '${messages[index - 1].cleanContent}\n\n${message.cleanContent}';

    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Текст скопирован'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
