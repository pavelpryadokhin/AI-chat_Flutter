import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/database_service.dart';

class ExpenseChartScreen extends StatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<DateTime, double> _dailyExpenses = {};
  String _selectedPeriod = 'week'; // 'week', 'month', 'all'
  double _totalExpenses = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Используем новый метод из DatabaseService
      final DateTime? startDate = _selectedPeriod == 'week'
          ? DateTime.now().subtract(const Duration(days: 7))
          : _selectedPeriod == 'month'
              ? DateTime(DateTime.now().year, DateTime.now().month - 1,
                  DateTime.now().day)
              : null;

      final expenses =
          await _databaseService.getExpensesByDay(startDate: startDate);

      // Вычисляем общую сумму расходов
      final total = expenses.values.fold(0.0, (sum, value) => sum + value);

      setState(() {
        _dailyExpenses = expenses;
        _totalExpenses = total;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading expenses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<DateTime, double> _filterExpensesByPeriod(
      Map<DateTime, double> expenses, String period) {
    final now = DateTime.now();
    final filtered = <DateTime, double>{};

    switch (period) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        for (final entry in expenses.entries) {
          if (entry.key.isAfter(weekAgo)) {
            filtered[entry.key] = entry.value;
          }
        }
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        for (final entry in expenses.entries) {
          if (entry.key.isAfter(monthAgo)) {
            filtered[entry.key] = entry.value;
          }
        }
        break;
      case 'all':
      default:
        return expenses;
    }

    return filtered;
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('График расходов', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadExpenses,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildPeriodSelector(),
                _buildTotalExpensesCard(),
                Expanded(
                  child: _dailyExpenses.isEmpty
                      ? const Center(child: Text('Нет данных о расходах'))
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildExpenseChart(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment<String>(
            value: 'week',
            label: Text('Неделя', style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment<String>(
            value: 'month',
            label: Text('Месяц', style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment<String>(
            value: 'all',
            label: Text('Все', style: TextStyle(fontSize: 12)),
          ),
        ],
        selected: {_selectedPeriod},
        onSelectionChanged: (selected) {
          _changePeriod(selected.first);
        },
      ),
    );
  }

  Widget _buildTotalExpensesCard() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isVsegpt = chatProvider.baseUrl?.contains('vsegpt.ru') == true;
        final formattedExpense = isVsegpt
            ? '${_totalExpenses.toStringAsFixed(3)}₽'
            : '\$${_totalExpenses.toStringAsFixed(3)}';

        return Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Общие расходы',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedExpense,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'за ${_getPeriodText(_selectedPeriod)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'week':
        return 'последнюю неделю';
      case 'month':
        return 'последний месяц';
      case 'all':
      default:
        return 'все время';
    }
  }

  Widget _buildExpenseChart() {
    // Сортируем даты
    final sortedDates = _dailyExpenses.keys.toList()..sort();

    // Подготавливаем данные для графика
    final spots = <FlSpot>[];
    final bottomTitles = <String>[];

    for (var i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final expense = _dailyExpenses[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), expense));
      bottomTitles.add(DateFormat('dd.MM').format(date));
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isVsegpt = chatProvider.baseUrl?.contains('vsegpt.ru') == true;
        final currencySymbol = isVsegpt ? '₽' : '\$';

        return Column(
          children: [
            const Text(
              'Ежедневные расходы',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: Text(
                              '${currencySymbol}${value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < bottomTitles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                bottomTitles[index],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
