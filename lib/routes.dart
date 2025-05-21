import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/token_stats_screen.dart';
import 'screens/expense_chart_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String settings = '/settings';
  static const String tokenStats = '/token_stats';
  static const String expenseChart = '/expense_chart';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const ChatScreen(),
      settings: (context) => const SettingsScreen(),
      tokenStats: (context) => const TokenStatsScreen(),
      expenseChart: (context) => const ExpenseChartScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final String? routeName = settings.name;

    if (routeName == home) {
      return MaterialPageRoute(builder: (_) => const ChatScreen());
    } else if (routeName == settings) {
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    } else if (routeName == tokenStats) {
      return MaterialPageRoute(builder: (_) => const TokenStatsScreen());
    } else if (routeName == expenseChart) {
      return MaterialPageRoute(builder: (_) => const ExpenseChartScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Страница не найдена: $routeName'),
          ),
        ),
      );
    }
  }
}
