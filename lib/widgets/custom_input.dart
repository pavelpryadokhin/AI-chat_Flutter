import 'package:flutter/material.dart';

/// Кастомное поле ввода для использования в приложении
class CustomInput extends StatefulWidget {
  /// Контроллер для управления текстом
  final TextEditingController controller;

  /// Подсказка для поля ввода
  final String hint;

  /// Функция, вызываемая при отправке текста
  final Function(String)? onSubmitted;

  /// Функция, вызываемая при изменении текста
  final Function(String)? onChanged;

  /// Максимальное количество строк
  final int maxLines;

  /// Минимальное количество строк
  final int minLines;

  /// Иконка действия
  final IconData? actionIcon;

  /// Функция, вызываемая при нажатии на иконку действия
  final VoidCallback? onActionPressed;

  /// Фокус-нода для управления фокусом
  final FocusNode? focusNode;

  /// Конструктор
  const CustomInput({
    super.key,
    required this.controller,
    this.hint = '',
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 6,
    this.minLines = 1,
    this.actionIcon,
    this.onActionPressed,
    this.focusNode,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isComposing = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);

    // Проверяем, есть ли уже текст в контроллере
    _isComposing = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(8.0),
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
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.trim().isNotEmpty;
                });

                if (widget.onChanged != null) {
                  widget.onChanged!(text);
                }
              },
              onSubmitted: _isComposing && widget.onSubmitted != null
                  ? widget.onSubmitted
                  : null,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 15.0,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
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
          if (widget.actionIcon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
              child: Material(
                color: _isComposing
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24.0),
                child: InkWell(
                  onTap: _isComposing && widget.onActionPressed != null
                      ? () {
                          widget.onActionPressed!();
                        }
                      : null,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    alignment: Alignment.center,
                    child: Icon(
                      widget.actionIcon,
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
