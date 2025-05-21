import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/analytics_service.dart';
import '../services/database_service.dart';

class TokenStatsScreen extends StatefulWidget {
  const TokenStatsScreen({super.key});

  @override
  State<TokenStatsScreen> createState() => _TokenStatsScreenState();
}

class _TokenStatsScreenState extends State<TokenStatsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _dbStatistics = {};
  Map<String, dynamic> _chartData = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Инициализируем пустую статистику
      setState(() {
        _isLoading = true;
      });

      // Получаем только данные из базы данных вместо комбинации с текущей сессией
      final chatProvider = context.read<ChatProvider>();
      final exportData = await chatProvider.exportHistory();

      // Используем только данные из базы данных для статистики
      setState(() {
        _dbStatistics = exportData['database_stats'] ?? {};
        _statistics =
            {}; // Не используем данные текущей сессии, чтобы избежать дублирования
        _chartData =
            {}; // Инициализируем пустую карту вместо вызова _generateChartData
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика токенов', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadStatistics,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildModelUsageList(),
                    const SizedBox(height: 16),
                    _buildSessionStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    // Используем только данные из БД для статистики, исключая дублирование
    final dbTokens = _dbStatistics['total_tokens'] ?? 0;
    final totalTokens = dbTokens;

    final dbMessages = _dbStatistics['total_messages'] ?? 0;
    final totalMessages = dbMessages;

    final tokensPerMessage =
        totalMessages > 0 ? totalTokens / totalMessages : 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Всего токенов:', '$totalTokens'),
            _buildStatRow('Всего сообщений:', '$totalMessages'),
            _buildStatRow('Среднее токенов на сообщение:',
                '${tokensPerMessage.toStringAsFixed(1)}'),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Получаем информацию о стоимости из доступных моделей
                final availableModels = chatProvider.availableModels;
                double estimatedCost = 0;

                if (availableModels.isNotEmpty) {
                  // Для упрощения берем среднюю стоимость токена из доступных моделей
                  double avgTokenCost = 0;
                  for (final model in availableModels) {
                    if (model['pricing'] != null) {
                      final promptPrice =
                          double.tryParse(model['pricing']['prompt'] ?? '0') ??
                              0;
                      final completionPrice = double.tryParse(
                              model['pricing']['completion'] ?? '0') ??
                          0;
                      avgTokenCost += (promptPrice + completionPrice) / 2;
                    }
                  }
                  avgTokenCost = avgTokenCost / availableModels.length;
                  estimatedCost = totalTokens * avgTokenCost;
                }

                final isVsegpt =
                    chatProvider.baseUrl?.contains('vsegpt.ru') == true;
                final costDisplay = isVsegpt
                    ? '${estimatedCost.toStringAsFixed(3)}₽ (прибл.)'
                    : '\$${estimatedCost.toStringAsFixed(3)} (прибл.)';

                return _buildStatRow('Примерная стоимость:', costDisplay);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModelUsageList() {
    // Используем только данные из БД, чтобы избежать дублирования
    final Map<String, Map<String, dynamic>> combinedModelUsage = {};

    // Добавляем данные из БД
    final dbModelUsage =
        _dbStatistics['model_usage'] as Map<dynamic, dynamic>? ?? {};
    for (final entry in dbModelUsage.entries) {
      final modelId = entry.key as String;
      combinedModelUsage[modelId] = {
        'count': entry.value['count'] ?? 0,
        'tokens': entry.value['tokens'] ?? 0,
        'source': 'DB',
      };
    }

    // Удаляем добавление данных из текущей сессии, чтобы избежать дублирования

    if (combinedModelUsage.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Нет данных об использовании моделей'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Использование по моделям',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...combinedModelUsage.entries.map((entry) {
              final modelId = entry.key;
              final usage = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelId,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatRow('Сообщений:', '${usage['count']}'),
                  _buildStatRow('Токенов:', '${usage['tokens']}'),
                  _buildStatRow(
                    'Среднее:',
                    usage['count'] > 0
                        ? '${(usage['tokens'] / usage['count']).toStringAsFixed(1)} токенов/сообщение'
                        : 'Н/Д',
                  ),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      // Поиск соответствующей модели для получения стоимости
                      Map<String, dynamic>? model;
                      try {
                        model = chatProvider.availableModels
                            .firstWhere((m) => m['id'] == modelId);
                      } catch (_) {
                        model = {'id': modelId, 'pricing': null};
                      }

                      if (model['pricing'] != null) {
                        final promptPrice = double.tryParse(
                                model['pricing']['prompt'] ?? '0') ??
                            0;
                        final completionPrice = double.tryParse(
                                model['pricing']['completion'] ?? '0') ??
                            0;
                        // Используем среднюю стоимость для примерной оценки
                        final avgPrice = (promptPrice + completionPrice) / 2;
                        final estimatedCost = usage['tokens'] * avgPrice;

                        final isVsegpt =
                            chatProvider.baseUrl?.contains('vsegpt.ru') == true;
                        final costDisplay = isVsegpt
                            ? '${estimatedCost.toStringAsFixed(3)}₽ (прибл.)'
                            : '\$${estimatedCost.toStringAsFixed(3)} (прибл.)';

                        return _buildStatRow(
                            'Примерная стоимость:', costDisplay);
                      } else {
                        return _buildStatRow(
                            'Примерная стоимость:', 'Нет данных');
                      }
                    },
                  ),
                  const Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    if (_statistics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика текущей сессии',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              'Длительность сессии:',
              '${_statistics['session_duration'] ?? 0} сек',
            ),
            _buildStatRow(
              'Сообщений в минуту:',
              '${(_statistics['messages_per_minute'] ?? 0).toStringAsFixed(1)}',
            ),
            _buildStatRow(
              'Начало сессии:',
              _statistics['start_time'] != null
                  ? _formatDateTime(DateTime.parse(_statistics['start_time']))
                  : 'Н/Д',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Сегодня, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Вчера, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  // Метод для генерации данных графика
  Map<String, dynamic> _generateChartData(Map<String, dynamic> exportData) {
    // Заглушка для метода, возвращает пустую карту
    return {};
  }
}
