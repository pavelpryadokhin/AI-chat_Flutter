import 'package:flutter/material.dart';

/// Кастомная кнопка для использования в приложении
class CustomButton extends StatelessWidget {
  /// Текст кнопки
  final String label;

  /// Иконка кнопки (необязательно)
  final IconData? icon;

  /// Функция обработки нажатия
  final VoidCallback onPressed;

  /// Основной цвет кнопки
  final Color color;

  /// Стиль текста (необязательно)
  final TextStyle? textStyle;

  /// Размер кнопки (small, medium, large)
  final ButtonSize size;

  /// Конструктор кнопки
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = const Color(0xFF3B82F6),
    this.textStyle,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Определение размеров на основе выбранного размера кнопки
    double height;
    double borderRadius;
    double fontSize;
    double iconSize;
    EdgeInsets padding;

    switch (size) {
      case ButtonSize.small:
        height = 32.0;
        borderRadius = 8.0;
        fontSize = 12.0;
        iconSize = 16.0;
        padding = const EdgeInsets.symmetric(horizontal: 12.0);
        break;
      case ButtonSize.medium:
        height = 40.0;
        borderRadius = 10.0;
        fontSize = 14.0;
        iconSize = 18.0;
        padding = const EdgeInsets.symmetric(horizontal: 16.0);
        break;
      case ButtonSize.large:
        height = 48.0;
        borderRadius = 12.0;
        fontSize = 16.0;
        iconSize = 20.0;
        padding = const EdgeInsets.symmetric(horizontal: 20.0);
        break;
    }

    final defaultTextStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontFamily: 'Roboto',
    );

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize),
              const SizedBox(width: 8.0),
            ],
            Text(
              label,
              style: textStyle ?? defaultTextStyle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Enum для определения размера кнопки
enum ButtonSize {
  small,
  medium,
  large,
}
