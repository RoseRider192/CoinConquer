import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/work_session.dart';
import '../models/budget.dart';
import '../models/recurring_rule.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('coin_conquer.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        custom_name TEXT,
        note TEXT,
        date TEXT NOT NULL,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        recurring_interval TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE part_time_jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        default_hourly_rate REAL NOT NULL,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE work_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id INTEGER NOT NULL DEFAULT 0,
        hours_worked REAL NOT NULL,
        hourly_rate REAL NOT NULL,
        total_income REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT,
        `interval` TEXT NOT NULL,
        next_date TEXT NOT NULL,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final categories = [
      // Expense categories
      ('食物', 'expense', 'food', '0xFFF97316', 1),
      ('交通', 'expense', 'transport', '0xFF3B82F6', 1),
      ('衣物', 'expense', 'clothing', '0xFFEC4899', 1),
      ('娱乐', 'expense', 'entertainment', '0xFF8B5CF6', 1),
      ('教育', 'expense', 'education', '0xFF06B6D4', 1),
      ('工作', 'expense', 'work', '0xFF6366F1', 1),
      ('医疗', 'expense', 'medical', '0xFFEF4444', 1),
      ('人情', 'expense', 'social', '0xFFF59E0B', 1),
      // Income categories
      ('工资', 'income', 'salary', '0xFF22C55E', 1),
      ('兼职', 'income', 'parttime', '0xFF10B981', 1),
      ('投资', 'income', 'investment', '0xFF16A34A', 1),
      ('其他', 'income', 'other_income', '0xFF78716C', 1),
    ];

    for (final cat in categories) {
      await db.insert('categories', {
        'name': cat.$1,
        'type': cat.$2,
        'icon': cat.$3,
        'color': cat.$4,
        'is_default': cat.$5,
        'created_at': now,
      });
    }
  }

  // --- Category CRUD ---
  Future<List<Category>> getCategories({String? type}) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (type != null) {
      where = 'WHERE type = ?';
      args = [type];
    }
    final maps = await db.rawQuery(
      'SELECT * FROM categories $where ORDER BY is_default DESC, id ASC',
      args,
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Transaction CRUD ---
  Future<List<Transaction>> getTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      conditions.add('t.type = ?');
      args.add(type);
    }
    if (startDate != null) {
      conditions.add('t.date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('t.date <= ?');
      args.add(endDate);
    }

    String where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final sql = 'SELECT t.*, c.name as category_name, c.color as category_color, c.icon as category_icon '
        'FROM transactions t '
        'LEFT JOIN categories c ON t.category_id = c.id '
        '$where '
        'ORDER BY t.date DESC, t.id DESC '
        '${limit != null ? 'LIMIT $limit' : ''}';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) {
      final t = Transaction.fromMap(m);
      return t;
    }).toList();
  }

  Future<Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Transaction.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Summary queries ---
  Future<double> getTotalIncome(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      ['income', startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalExpense(String startDate, String endDate) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = ? AND date >= ? AND date <= ?',
      ['expense', startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getCategorySummary(
      String type, String startDate, String endDate) async {
    final db = await database;
    return db.rawQuery(
      'SELECT c.id, c.name, c.color, c.icon, COALESCE(SUM(t.amount), 0) as total '
      'FROM categories c '
      'LEFT JOIN transactions t ON c.id = t.category_id AND t.date >= ? AND t.date <= ? '
      'WHERE c.type = ? '
      'GROUP BY c.id '
      'ORDER BY total DESC',
      [startDate, endDate, type],
    );
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrends(int months) async {
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final startDate = '${target.year}-${target.month.toString().padLeft(2, '0')}-01';
      final endDay = DateTime(target.year, target.month + 1, 0).day;
      final endDate =
          '${target.year}-${target.month.toString().padLeft(2, '0')}-${endDay.toString().padLeft(2, '0')}';

      final income = await getTotalIncome(startDate, endDate);
      final expense = await getTotalExpense(startDate, endDate);

      results.add({
        'month': '${target.year}-${target.month.toString().padLeft(2, '0')}',
        'income': income,
        'expense': expense,
      });
    }

    return results;
  }

  // --- WorkSession CRUD ---
  Future<List<WorkSession>> getWorkSessions({int? jobId, String? startDate, String? endDate}) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (jobId != null) {
      conditions.add('job_id = ?');
      args.add(jobId);
    }
    if (startDate != null) {
      conditions.add('date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('date <= ?');
      args.add(endDate);
    }

    String where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final sql = 'SELECT * FROM work_sessions $where ORDER BY date DESC, id DESC';

    final maps = await db.rawQuery(sql, args);
    return maps.map((m) => WorkSession.fromMap(m)).toList();
  }

  Future<int> insertWorkSession(WorkSession session) async {
    final db = await database;
    return db.insert('work_sessions', session.toMap());
  }

  Future<void> deleteWorkSessionsByDateAndAmount(String date, double totalIncome) async {
    final db = await database;
    await db.delete(
      'work_sessions',
      where: 'date = ? AND ABS(total_income - ?) < 0.01',
      whereArgs: [date, totalIncome],
    );
  }

  Future<void> updateWorkSessionNoteByMatch(String date, double totalIncome, String? note) async {
    final db = await database;
    await db.update(
      'work_sessions',
      {'note': note},
      where: 'date = ? AND ABS(total_income - ?) < 0.01',
      whereArgs: [date, totalIncome],
    );
  }

  Future<Map<String, double>> getDailyHours(String yearMonth) async {
    final db = await database;
    final maps = await db.rawQuery(
      "SELECT date, SUM(hours_worked) as total_hours FROM work_sessions WHERE date LIKE ? GROUP BY date",
      ['$yearMonth%'],
    );
    final result = <String, double>{};
    for (final m in maps) {
      result[m['date'] as String] = (m['total_hours'] as num).toDouble();
    }
    return result;
  }

  Future<double> getMonthlyHours(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(hours_worked), 0) as total FROM work_sessions WHERE date LIKE ?",
      ['$yearMonth%'],
    );
    return (result.first['total'] as num).toDouble();
  }


  // --- Budget CRUD ---
  Future<List<Budget>> getBudgets(String month) async {
    final db = await database;
    final maps = await db.query('budgets', where: 'month = ?', whereArgs: [month]);
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<Budget?> getBudget(int categoryId, String month) async {
    final db = await database;
    final maps = await db.query(
      'budgets',
      where: 'category_id = ? AND month = ?',
      whereArgs: [categoryId, month],
    );
    if (maps.isNotEmpty) {
      return Budget.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveBudget(Budget budget) async {
    final db = await database;
    final existing = await getBudget(budget.categoryId, budget.month);
    if (existing != null) {
      await db.update(
        'budgets',
        budget.toMap(),
        where: 'category_id = ? AND month = ?',
        whereArgs: [budget.categoryId, budget.month],
      );
    } else {
      await db.insert('budgets', budget.toMap());
    }
  }

  // --- RecurringRule CRUD ---
  Future<List<RecurringRule>> getRecurringRules() async {
    final db = await database;
    final sql = 'SELECT r.*, c.name as category_name '
        'FROM recurring_rules r '
        'LEFT JOIN categories c ON r.category_id = c.id '
        'ORDER BY r.id DESC';
    final maps = await db.rawQuery(sql);
    return maps.map((m) => RecurringRule.fromMap(m)).toList();
  }

  Future<int> insertRecurringRule(RecurringRule rule) async {
    final db = await database;
    return db.insert('recurring_rules', rule.toMap());
  }

  Future<int> updateRecurringRule(RecurringRule rule) async {
    final db = await database;
    return db.update(
      'recurring_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRecurringRule(int id) async {
    final db = await database;
    return db.delete('recurring_rules', where: 'id = ?', whereArgs: [id]);
  }

  // --- Date marks for calendar ---
  Future<Set<String>> getDatesWithTransactions(String yearMonth) async {
    final db = await database;
    final maps = await db.rawQuery(
      "SELECT DISTINCT date FROM transactions WHERE date LIKE ?",
      ['$yearMonth%'],
    );
    return maps.map((m) => m['date'] as String).toSet();
  }

  // --- Export / Import ---
  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final jobs = await db.query('part_time_jobs');
    final sessions = await db.query('work_sessions');
    final budgets = await db.query('budgets');
    final rules = await db.query('recurring_rules');

    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories,
      'transactions': transactions,
      'part_time_jobs': jobs,
      'work_sessions': sessions,
      'budgets': budgets,
      'recurring_rules': rules,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      if (data['categories'] != null) {
        for (final cat in (data['categories'] as List)) {
          await txn.insert(
            'categories',
            cat as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (data['transactions'] != null) {
        for (final t in (data['transactions'] as List)) {
          await txn.insert(
            'transactions',
            t as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (data['part_time_jobs'] != null) {
        for (final j in (data['part_time_jobs'] as List)) {
          await txn.insert(
            'part_time_jobs',
            j as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (data['work_sessions'] != null) {
        for (final s in (data['work_sessions'] as List)) {
          await txn.insert(
            'work_sessions',
            s as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (data['budgets'] != null) {
        for (final b in (data['budgets'] as List)) {
          await txn.insert(
            'budgets',
            b as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (data['recurring_rules'] != null) {
        for (final r in (data['recurring_rules'] as List)) {
          await txn.insert(
            'recurring_rules',
            r as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }
}
