import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme/app_theme.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/statistics/statistics_screen.dart';
import 'screens/mine/mine_screen.dart';
import 'screens/add_transaction/add_transaction_screen.dart';

class CoinConquerApp extends StatelessWidget {
  const CoinConquerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '硬币征服者',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalendarScreen(key: _calendarKey),
          const StatisticsScreen(),
          const MineScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar),
            activeIcon: Icon(CupertinoIcons.calendar, color: Color(0xFF007AFF)),
            label: '日历',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            activeIcon: Icon(CupertinoIcons.chart_bar, color: Color(0xFF007AFF)),
            label: '统计',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person, color: Color(0xFF007AFF)),
            label: '我的',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const AddTransactionScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
                if (result == true && mounted) {
                  _calendarKey.currentState?.loadData();
                }
              },
              child: const Icon(CupertinoIcons.add),
            )
          : null,
    );
  }
}
