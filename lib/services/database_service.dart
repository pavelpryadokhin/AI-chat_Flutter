// Импорт платформо-зависимых функций
import 'dart:io' show Platform;
// Импорт утилит для работы с путями
import 'package:path/path.dart';
// Импорт основного пакета для работы с SQLite
import 'package:sqflite/sqflite.dart';
// Импорт основных классов Flutter
import 'package:flutter/foundation.dart';
// Импорт FFI реализации для desktop платформ
import 'package:sqflite_common_ffi/sqflite_ffi.dart' if (dart.library.html) '';
// Импорт модели сообщения
import '../models/message.dart';

// Класс сервиса для работы с базой данных
class DatabaseService {
  // Единственный экземпляр класса (Singleton)
  static final DatabaseService _instance = DatabaseService._internal();
  // Экземпляр базы данных
  static Database? _database;

  // Фабричный метод для получения экземпляра
  factory DatabaseService() {
    return _instance;
  }

  // Приватный конструктор для реализации Singleton
  DatabaseService._internal();

  // Геттер для получения экземпляра базы данных
  Future<Database> get database async {
    if (_database != null) return _database!; // Возврат существующей БД
    _database = await _initDatabase(); // Инициализация новой БД
    return _database!;
  }

  // Метод инициализации базы данных
  Future<Database> _initDatabase() async {
    // Инициализация FFI для desktop платформ
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Получение пути к базе данных
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chat_cache.db'); // Имя файла базы данных

    // Открытие/создание базы данных
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Создание таблицы messages при первом запуске
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            model_id TEXT,
            tokens INTEGER,
            cost REAL
          )
        ''');
      },
    );
  }

  // Метод сохранения сообщения в базу данных
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final db = await database;
      // Вставка данных в таблицу messages
      await db.insert(
        'messages',
        {
          'content': message.content, // Текст сообщения
          'is_user': message.isUser ? 1 : 0, // Преобразование bool в int
          'timestamp': message.timestamp.toIso8601String(), // Временная метка
          'model_id': message.modelId, // Идентификатор модели
          'tokens': message.tokens, // Количество токенов
          'cost': message.cost, // Стоимость запроса
        },
        conflictAlgorithm:
            ConflictAlgorithm.replace, // Стратегия при конфликтах
      );
    } catch (e) {
      debugPrint('Error saving message: $e'); // Логирование ошибок
    }
  }

  // Метод получения сообщений из базы данных
  Future<List<ChatMessage>> getMessages({int limit = 50}) async {
    try {
      final db = await database;
      // Запрос данных из таблицы messages
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        orderBy: 'timestamp ASC', // Сортировка по времени
        limit: limit, // Ограничение количества записей
      );

      // Преобразование данных в объекты ChatMessage
      return List.generate(maps.length, (i) {
        return ChatMessage(
          content: maps[i]['content'] as String, // Текст сообщения
          isUser: maps[i]['is_user'] == 1, // Преобразование int в bool
          timestamp:
              DateTime.parse(maps[i]['timestamp'] as String), // Временная метка
          modelId: maps[i]['model_id'] as String?, // Идентификатор модели
          tokens: maps[i]['tokens'] as int?, // Количество токенов
          cost: maps[i]['cost'] as double?, // Стоимость запроса
        );
      });
    } catch (e) {
      debugPrint('Error getting messages: $e'); // Логирование ошибок
      return []; // Возврат пустого списка в случае ошибки
    }
  }

  // Метод очистки истории сообщений
  Future<void> clearHistory() async {
    try {
      final db = await database;
      await db.delete('messages'); // Удаление всех записей из таблицы
    } catch (e) {
      debugPrint('Error clearing history: $e'); // Логирование ошибок
    }
  }

  // Метод получения статистики по сообщениям
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = await database;

      // Получение общего количества сообщений
      final totalMessagesResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM messages');
      final totalMessages = Sqflite.firstIntValue(totalMessagesResult) ?? 0;

      // Получение общего количества токенов
      final totalTokensResult = await db.rawQuery(
          'SELECT SUM(tokens) as total FROM messages WHERE tokens IS NOT NULL');
      final totalTokens = Sqflite.firstIntValue(totalTokensResult) ?? 0;

      // Получение статистики использования моделей
      final modelStats = await db.rawQuery('''
        SELECT 
          model_id,
          COUNT(*) as message_count,
          SUM(tokens) as total_tokens
        FROM messages 
        WHERE model_id IS NOT NULL 
        GROUP BY model_id
      ''');

      // Формирование данных по использованию моделей
      final modelUsage = <String, Map<String, int>>{};
      for (final stat in modelStats) {
        final modelId = stat['model_id'] as String;
        modelUsage[modelId] = {
          'count': stat['message_count'] as int, // Количество сообщений
          'tokens':
              stat['total_tokens'] as int? ?? 0, // Общее количество токенов
        };
      }

      return {
        'total_messages': totalMessages, // Общее количество сообщений
        'total_tokens': totalTokens, // Общее количество токенов
        'model_usage': modelUsage, // Статистика по моделям
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e'); // Логирование ошибок
      return {
        'total_messages': 0,
        'total_tokens': 0,
        'model_usage': {},
      };
    }
  }

  // Метод получения расходов по дням
  Future<Map<DateTime, double>> getExpensesByDay(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await database;

      // Настройка условий запроса в зависимости от переданных дат
      String whereClause = 'is_user = 0 AND cost IS NOT NULL';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Запрос сообщений от AI с ненулевой стоимостью
      final List<Map<String, dynamic>> messages = await db.query(
        'messages',
        columns: ['cost', 'timestamp'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      // Группировка расходов по дням
      final Map<DateTime, double> dailyExpenses = {};

      for (final message in messages) {
        final timestamp = DateTime.parse(message['timestamp'] as String);
        final cost = message['cost'] as double;

        // Создаем дату без времени (только год, месяц, день)
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

        // Добавляем стоимость к текущему значению или инициализируем с текущей стоимостью
        dailyExpenses[date] = (dailyExpenses[date] ?? 0) + cost;
      }

      return dailyExpenses;
    } catch (e) {
      debugPrint('Error getting expenses by day: $e');
      return {};
    }
  }

  // Метод получения статистики использования токенов по дням
  Future<Map<DateTime, Map<String, dynamic>>> getTokenUsageByDay(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final db = await database;

      // Настройка условий запроса в зависимости от переданных дат
      String whereClause = 'tokens IS NOT NULL';
      List<dynamic> whereArgs = [];

      if (startDate != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endDate.toIso8601String());
      }

      // Запрос сообщений с ненулевым количеством токенов
      final List<Map<String, dynamic>> messages = await db.query(
        'messages',
        columns: ['tokens', 'timestamp', 'model_id', 'is_user', 'cost'],
        where: whereClause,
        whereArgs: whereArgs,
      );

      // Группировка использования токенов по дням
      final Map<DateTime, Map<String, dynamic>> dailyUsage = {};

      for (final message in messages) {
        final timestamp = DateTime.parse(message['timestamp'] as String);
        final tokens = message['tokens'] as int;
        final isUser = message['is_user'] == 1;
        final modelId = message['model_id'] as String?;
        final cost = message['cost'] as double?;

        // Создаем дату без времени (только год, месяц, день)
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

        // Инициализируем запись для текущей даты, если она не существует
        if (!dailyUsage.containsKey(date)) {
          dailyUsage[date] = {
            'total_tokens': 0,
            'total_cost': 0.0,
            'message_count': 0,
            'models': <String, Map<String, dynamic>>{},
          };
        }

        // Обновляем общую статистику
        dailyUsage[date]!['total_tokens'] =
            (dailyUsage[date]!['total_tokens'] as int) + tokens;
        dailyUsage[date]!['message_count'] =
            (dailyUsage[date]!['message_count'] as int) + 1;

        if (cost != null) {
          dailyUsage[date]!['total_cost'] =
              (dailyUsage[date]!['total_cost'] as double) + cost;
        }

        // Обновляем статистику по моделям, если сообщение от AI
        if (!isUser && modelId != null) {
          final models =
              dailyUsage[date]!['models'] as Map<String, Map<String, dynamic>>;

          if (!models.containsKey(modelId)) {
            models[modelId] = {
              'tokens': 0,
              'cost': 0.0,
              'count': 0,
            };
          }

          models[modelId]!['tokens'] =
              (models[modelId]!['tokens'] as int) + tokens;
          models[modelId]!['count'] = (models[modelId]!['count'] as int) + 1;

          if (cost != null) {
            models[modelId]!['cost'] =
                (models[modelId]!['cost'] as double) + cost;
          }
        }
      }

      return dailyUsage;
    } catch (e) {
      debugPrint('Error getting token usage by day: $e');
      return {};
    }
  }
}
