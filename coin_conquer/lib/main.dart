import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/balance_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/recurring_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final categoryProvider = CategoryProvider();
  await categoryProvider.loadCategories();

  final balanceProvider = BalanceProvider();
  await balanceProvider.loadBalance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: balanceProvider),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => RecurringProvider()),
      ],
      child: const CoinConquerApp(),
    ),
  );
}
