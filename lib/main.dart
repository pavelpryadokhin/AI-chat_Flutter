// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт пакета для работы с .env файлами
import 'package:flutter_dotenv/flutter_dotenv.dart';
// Импорт пакета для локализации приложения
import 'package:flutter_localizations/flutter_localizations.dart';
// Импорт пакета для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт кастомного провайдера для управления состоянием чата
import 'providers/chat_provider.dart';
// Импорт маршрутов
import 'routes.dart';

// Виджет для обработки и отлова ошибок в приложении
class ErrorBoundaryWidget extends StatelessWidget {
  // Дочерний виджет, который будет обернут в обработчик ошибок
  final Widget child;

  // Конструктор с обязательным параметром child
  const ErrorBoundaryWidget({super.key, required this.child});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем Builder для создания нового контекста
    return Builder(
      // Функция построения виджета с обработкой ошибок
      builder: (context) {
        // Пытаемся построить дочерний виджет
        try {
          // Возвращаем дочерний виджет, если ошибок нет
          return child;
          // Ловим и обрабатываем ошибки
        } catch (error, stackTrace) {
          // Логируем ошибку в консоль
          debugPrint('Error in ErrorBoundaryWidget: $error');
          // Логируем стек вызовов для отладки
          debugPrint('Stack trace: $stackTrace');
          // Возвращаем MaterialApp с экраном ошибки
          return MaterialApp(
            // Основной экран приложения
            home: Scaffold(
              // Красный фон для экрана ошибки
              backgroundColor: Colors.red,
              // Центрируем содержимое
              body: Center(
                // Добавляем отступы
                child: Padding(
                  // Отступы 16 пикселей со всех сторон
                  padding: const EdgeInsets.all(16.0),
                  // Текст с описанием ошибки
                  child: Text(
                    // Отображаем текст ошибки
                    'Error: $error',
                    // Белый цвет текста
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

// Основная точка входа в приложение
void main() async {
  try {
    // Инициализация Flutter биндингов
    WidgetsFlutterBinding.ensureInitialized();

    // Настройка обработки ошибок Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      // Отображение ошибки
      FlutterError.presentError(details);
      // Логирование ошибки
      debugPrint('Flutter error: ${details.exception}');
      // Логирование стека вызовов
      debugPrint('Stack trace: ${details.stack}');
    };

    // Загрузка переменных окружения из .env файла
    await dotenv.load(fileName: ".env");
    // Логирование успешной загрузки
    debugPrint('Environment loaded');
    // Проверка наличия API ключа
    debugPrint('API Key present: ${dotenv.env['OPENROUTER_API_KEY'] != null}');
    // Логирование базового URL
    debugPrint('Base URL: ${dotenv.env['BASE_URL']}');

    // Запуск приложения с обработчиком ошибок
    runApp(const ErrorBoundaryWidget(child: MyApp()));
  } catch (e, stackTrace) {
    // Логирование ошибки запуска приложения
    debugPrint('Error starting app: $e');
    // Логирование стека вызовов
    debugPrint('Stack trace: $stackTrace');
    // Запуск приложения с экраном ошибки
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error starting app: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Основной виджет приложения
class MyApp extends StatelessWidget {
  // Конструктор с ключом
  const MyApp({super.key});

  // Метод построения виджета
  @override
  Widget build(BuildContext context) {
    // Используем ChangeNotifierProvider для управления состоянием
    return ChangeNotifierProvider(
      // Функция создания провайдера
      create: (_) {
        try {
          // Создаем экземпляр ChatProvider
          return ChatProvider();
        } catch (e, stackTrace) {
          // Логирование ошибки создания провайдера
          debugPrint('Error creating ChatProvider: $e');
          // Логирование стека вызовов
          debugPrint('Stack trace: $stackTrace');
          // Повторный выброс исключения
          rethrow;
        }
      },
      // Основной виджет MaterialApp
      child: MaterialApp(
        // Настройка поведения прокрутки
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: ScrollBehavior(),
            child: child!,
          );
        },
        // Заголовок приложения
        title: 'AI Chat',
        // Скрытие баннера debug
        debugShowCheckedModeBanner: false,
        // Установка локали по умолчанию (русский)
        locale: const Locale('ru', 'RU'),
        // Поддерживаемые локали
        supportedLocales: const [
          Locale('ru', 'RU'), // Русский
          Locale('en', 'US'), // Английский (США)
        ],
        // Делегаты для локализации
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate, // Локализация Material виджетов
          GlobalWidgetsLocalizations.delegate, // Локализация базовых виджетов
          GlobalCupertinoLocalizations
              .delegate, // Локализация Cupertino виджетов
        ],
        // Настройка темы приложения
        theme: ThemeData(
          // Цветовая схема на основе синего цвета
          colorScheme: ColorScheme.fromSeed(
            seedColor:
                const Color(0xFF3B82F6), // Основной цвет (современный синий)
            brightness: Brightness.dark, // Темная тема
            primary: const Color(0xFF3B82F6), // Современный синий
            secondary: const Color(0xFF10B981), // Современный зеленый
            tertiary: const Color(0xFFF59E0B), // Современный золотой
            background: const Color(0xFF111827), // Темно-серый фон
            surface: const Color(0xFF1F2937), // Поверхность элементов
            error: const Color(0xFFEF4444), // Красный цвет для ошибок
          ),
          // Использование Material 3
          useMaterial3: true,
          // Цвет фона Scaffold
          scaffoldBackgroundColor: const Color(0xFF111827),
          // Настройка темы AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F2937), // Цвет фона
            foregroundColor: Colors.white, // Цвет текста
            elevation: 2, // Легкая тень для глубины
            centerTitle: true, // Центрирование заголовка
          ),
          // Настройка темы диалогов
          dialogTheme: const DialogTheme(
            backgroundColor: Color(0xFF1F2937), // Цвет фона
            elevation: 8, // Тень для создания эффекта глубины
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(16)), // Скругленные углы
            ),
            titleTextStyle: TextStyle(
              color: Colors.white, // Цвет заголовка
              fontSize: 20, // Размер шрифта
              fontWeight: FontWeight.bold, // Жирный шрифт
              fontFamily: 'Roboto', // Шрифт
            ),
            contentTextStyle: TextStyle(
              color: Colors.white70, // Цвет текста
              fontSize: 16, // Размер шрифта
              fontFamily: 'Roboto', // Шрифт
            ),
          ),
          // Настройка текстовой темы
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 16, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
            bodyMedium: TextStyle(
              fontFamily: 'Roboto', // Шрифт
              fontSize: 14, // Размер шрифта
              color: Colors.white, // Цвет текста
            ),
            labelLarge: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          // Настройка темы кнопок
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // Цвет текста
              backgroundColor: const Color(0xFF3B82F6), // Фон кнопки
              elevation: 2, // Легкая тень
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Скругленные углы
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
                fontWeight: FontWeight.w500, // Средне-жирный шрифт
              ),
            ),
          ),
          // Настройка темы текстовых кнопок
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6), // Цвет текста
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Скругленные углы
              ),
              textStyle: const TextStyle(
                fontFamily: 'Roboto', // Шрифт
                fontSize: 14, // Размер шрифта
                fontWeight: FontWeight.w500, // Средне-жирный шрифт
              ),
            ),
          ),
          // Настройка темы иконок
          iconTheme: const IconThemeData(
            color: Colors.white70, // Цвет иконок
            size: 20, // Размер иконок
          ),
          // Настройка карточек
          cardTheme: const CardTheme(
            color: Color(0xFF1F2937), // Цвет фона карточек
            elevation: 2, // Тень для карточек
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(12)), // Скругленные углы
            ),
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Отступы
          ),
        ),
        // Использование созданных маршрутов
        initialRoute: AppRoutes.home,
        routes: AppRoutes.getRoutes(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
