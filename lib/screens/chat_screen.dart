// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с системными сервисами (буфер обмена)
import 'package:flutter/services.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт для работы со шрифтами Google
import 'package:google_fonts/google_fonts.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт модели сообщения
import '../models/message.dart';
// Импорт маршрутов
import '../routes.dart';
// Импорт кастомных виджетов
import '../widgets/custom_button.dart';
import '../widgets/custom_input.dart';
import '../widgets/message_bubble.dart';

// Виджет для обработки ошибок в UI
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          debugPrint('Error in ErrorBoundary: $error');
          debugPrint('Stack trace: $stackTrace');
          return Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red,
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }
      },
    );
  }
}

// Виджет для отображения отдельного сообщения в чате
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final List<ChatMessage> messages;
  final int index;

  const _MessageBubble({
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
          // Заголовок сообщения с моделью или именем пользователя
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 4.0, right: 4.0),
            child: Text(
              isUser ? 'Вы' : message.modelName ?? 'AI',
              style: TextStyle(
                color: isUser
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.secondary,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Контейнер сообщения
          Container(
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
                  onLongPress: () {
                    final textToCopy = isUser
                        ? message.cleanContent
                        : '${messages[index - 1].cleanContent}\n\n${message.cleanContent}';
                    Clipboard.setData(ClipboardData(text: textToCopy));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Текст скопирован'),
                        backgroundColor: theme.colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SelectableText(
                      message.cleanContent,
                      style: GoogleFonts.roboto(
                        color: isUser
                            ? Colors.white
                            : theme.textTheme.bodyLarge?.color,
                        fontSize: 14.0,
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Информация о сообщении
          if (message.tokens != null || message.cost != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.tokens != null)
                    Text(
                      'Токенов: ${message.tokens}',
                      style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  if (message.tokens != null && message.cost != null)
                    const SizedBox(width: 8),
                  if (message.cost != null)
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, child) {
                        final isVsetgpt =
                            chatProvider.baseUrl?.contains('vsetgpt.ru') ==
                                true;
                        return Text(
                          message.cost! < 0.001
                              ? isVsetgpt
                                  ? 'Стоимость: <0.001₽'
                                  : 'Стоимость: <\$0.001'
                              : isVsetgpt
                                  ? 'Стоимость: ${message.cost!.toStringAsFixed(3)}₽'
                                  : 'Стоимость: \$${message.cost!.toStringAsFixed(3)}',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16.0),
                    child: InkWell(
                      onTap: () {
                        final textToCopy = isUser
                            ? message.cleanContent
                            : '${messages[index - 1].cleanContent}\n\n${message.cleanContent}';
                        Clipboard.setData(ClipboardData(text: textToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Текст скопирован'),
                            backgroundColor: theme.colorScheme.secondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.copy,
                          size: 14.0,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}

// Виджет для ввода сообщений
class _MessageInput extends StatefulWidget {
  final void Function(String) onSubmitted;

  const _MessageInput({required this.onSubmitted});

  @override
  _MessageInputState createState() => _MessageInputState();
}

// Состояние виджета ввода сообщений
class _MessageInputState extends State<_MessageInput> {
  // Контроллер для управления текстовым полем
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Флаг, указывающий, вводится ли сейчас сообщение
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  void _handleSubmitted(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    _controller.clear();
    setState(() {
      _isComposing = false;
    });
    widget.onSubmitted(trimmedText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });
              },
              onSubmitted: _isComposing ? _handleSubmitted : null,
              maxLines: 6,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 15.0,
              ),
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontSize: 15.0,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
            child: Material(
              color: _isComposing
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                onTap: _isComposing
                    ? () => _handleSubmitted(_controller.text)
                    : null,
                borderRadius: BorderRadius.circular(24.0),
                child: Container(
                  width: 40.0,
                  height: 40.0,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: _isComposing
                        ? Colors.white
                        : theme.iconTheme.color?.withOpacity(0.4),
                    size: 20.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Основной экран чата
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildMessagesList(),
              ),
              _buildInputArea(context),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Построение верхней панели приложения
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.background,
      toolbarHeight: 56,
      elevation: 0,
      title: Row(
        children: [
          _buildModelSelector(context),
          const Spacer(),
          _buildBalanceDisplay(context),
          _buildMenuButton(context),
        ],
      ),
    );
  }

  // Построение выпадающего списка для выбора модели
  Widget _buildModelSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
            child: DropdownButton<String>(
              dropdownColor: theme.colorScheme.surface,
              value: chatProvider.currentModel,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              underline: const SizedBox.shrink(),
              hint: Text(
                'Выберите модель',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.iconTheme.color,
                size: 20,
              ),
              onChanged: (String? value) {
                if (value != null) {
                  chatProvider.setCurrentModel(value);
                }
              },
              items: chatProvider.availableModels.map((model) {
                return DropdownMenuItem<String>(
                  value: model['id'],
                  child: Text(
                    model['name'],
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Отображение текущего баланса пользователя
  Widget _buildBalanceDisplay(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 14,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                chatProvider.balance,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Построение кнопки меню с дополнительными опциями
  Widget _buildMenuButton(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded,
            color: theme.iconTheme.color, size: 24),
        offset: const Offset(0, 40),
        onSelected: (String choice) async {
          final chatProvider = context.read<ChatProvider>();
          switch (choice) {
            case 'export':
              final path = await chatProvider.exportMessagesAsJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('История сохранена в: $path'),
                    backgroundColor: theme.colorScheme.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                );
              }
              break;
            case 'clear':
              _showClearHistoryDialog(context);
              break;
            case 'token_stats':
              Navigator.pushNamed(context, AppRoutes.tokenStats);
              break;
            case 'expense_chart':
              Navigator.pushNamed(context, AppRoutes.expenseChart);
              break;
            case 'settings':
              Navigator.pushNamed(context, AppRoutes.settings);
              break;
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'export',
            height: 44,
            child: Row(
              children: [
                Icon(Icons.save_alt_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Экспорт истории',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'clear',
            height: 44,
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded,
                    size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text('Очистить историю',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'token_stats',
            height: 44,
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Статистика токенов',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'expense_chart',
            height: 44,
            child: Row(
              children: [
                Icon(Icons.money_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('График расходов',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'settings',
            height: 44,
            child: Row(
              children: [
                Icon(Icons.settings,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Настройки',
                    style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Построение списка сообщений чата
  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          reverse: false,
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return MessageBubble(
              message: message,
              messages: chatProvider.messages,
              index: index,
            );
          },
        );
      },
    );
  }

  // Построение области ввода сообщений
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final controller = TextEditingController();

          return CustomInput(
            controller: controller,
            hint: 'Введите сообщение...',
            actionIcon: Icons.send_rounded,
            onActionPressed: () {
              final text = controller.text;
              if (text.trim().isNotEmpty) {
                chatProvider.sendMessage(text);
                controller.clear();
              }
            },
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                chatProvider.sendMessage(text);
                controller.clear();
              }
            },
          );
        },
      ),
    );
  }

  // Построение панели с кнопками действий
  Widget _buildActionButtons(BuildContext context) {
    // Получаем ширину экрана
    final screenWidth = MediaQuery.of(context).size.width;
    // Определяем пороговое значение для мобильных устройств
    const double mobileWidthThreshold = 600.0;

    // Если ширина экрана меньше порогового значения (мобильное устройство),
    // возвращаем пустой контейнер
    if (screenWidth < mobileWidthThreshold) {
      return const SizedBox.shrink();
    }

    // В случае десктопной версии, возвращаем оригинальные кнопки
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: theme.colorScheme.surface.withOpacity(0.8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              icon: Icons.save,
              label: 'Сохранить',
              color: const Color(0xFF3B82F6),
              size: ButtonSize.small,
              onPressed: () async {
                final path =
                    await context.read<ChatProvider>().exportMessagesAsJson();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('История сохранена в: $path',
                          style: const TextStyle(fontSize: 12)),
                      backgroundColor: theme.colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            CustomButton(
              icon: Icons.bar_chart,
              label: 'Статистика',
              color: const Color(0xFF9966CC),
              size: ButtonSize.small,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.tokenStats),
            ),
            const SizedBox(width: 8),
            CustomButton(
              icon: Icons.monetization_on,
              label: 'Расходы',
              color: const Color(0xFFF59E0B),
              size: ButtonSize.small,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.expenseChart),
            ),
            const SizedBox(width: 8),
            CustomButton(
              icon: Icons.settings,
              label: 'Настройки',
              color: const Color(0xFF6B7280),
              size: ButtonSize.small,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }

  // Отображение диалога подтверждения очистки истории
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF333333),
          title: const Text(
            'Очистить историю',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          content: const Text(
            'Вы уверены? Это действие нельзя отменить.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена', style: TextStyle(fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                context.read<ChatProvider>().clearHistory();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Очистить',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
