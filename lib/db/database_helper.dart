import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern (ensures only one database instance exists)
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cafe_delivery.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Creates the DB. If it doesn't exist, it calls _createDB
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. MEAL PLANS TABLE
    await db.execute('''
      CREATE TABLE meal_plans ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        meals_per_day INTEGER NOT NULL,
        price REAL NOT NULL,
        duration_days INTEGER NOT NULL
      )
    ''');

    // 2. CUSTOMERS TABLE
    await db.execute('''
      CREATE TABLE customers ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        plan_id INTEGER,
        start_date TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    // 3. DAILY DELIVERIES TABLE (The Checklist)
    await db.execute('''
      CREATE TABLE daily_deliveries ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        date TEXT NOT NULL,
        customer_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        address TEXT NOT NULL,
        meal_type TEXT NOT NULL, 
        status TEXT NOT NULL
      )
    ''');

    print("----- DATABASE CREATED SUCCESSFULLY -----");
  }

  // --- PLAN METHODS ---
  Future<int> addPlan(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('meal_plans', row);
  }

  Future<List<Map<String, dynamic>>> getPlans() async {
    Database db = await instance.database;
    return await db.query('meal_plans');
  }

  Future<int> deletePlan(int id) async {
    Database db = await instance.database;
    return await db.delete('meal_plans', where: 'id = ?', whereArgs: [id]);
  }

  // --- CUSTOMER METHODS ---
  Future<int> addCustomer(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('customers', row);
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    Database db = await instance.database;
    return await db.query('customers', orderBy: 'id DESC');
  }

  // --- DAILY DELIVERY LOGIC ---

  // 1. GET LIST: Fetch deliveries for a specific date
  Future<List<Map<String, dynamic>>> getDeliveriesForDate(String date) async {
    Database db = await instance.database;

    // First, try to generate them if they don't exist yet
    await _generateDeliveriesIfEmpty(db, date);

    // Then fetch them
    return await db.query(
      'daily_deliveries',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // 2. TOGGLE STATUS: Mark as Delivered / Pending
  Future<int> toggleDeliveryStatus(int id, bool isDone) async {
    Database db = await instance.database;
    String status = isDone ? "Delivered" : "Pending";
    return await db.update(
      'daily_deliveries',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 3. THE GENERATOR (Private Helper)
  Future<void> _generateDeliveriesIfEmpty(Database db, String dateStr) async {
    // Check if we already generated list for this date
    final existing = await db.query(
      'daily_deliveries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    if (existing.isNotEmpty) return; // Already exists, stop here.

    // If empty, let's create the list!
    print("GENERATING TASKS FOR $dateStr...");

    // A. Get all active customers
    // Logic: Active AND (Start <= Today) AND (Expiry >= Today)
    final customers = await db.rawQuery(
      '''
      SELECT * FROM customers 
      WHERE is_active = 1 
      AND start_date <= ? 
      AND expiry_date >= ?
    ''',
      [dateStr, dateStr],
    );

    if (customers.isEmpty) return;

    // B. Loop through them and create tasks
    for (var cust in customers) {
      int planId = cust['plan_id'] as int;

      // Get the plan details to know if it's 1 or 2 meals
      final planResult = await db.query(
        'meal_plans',
        where: 'id = ?',
        whereArgs: [planId],
      );
      if (planResult.isEmpty) continue;

      final plan = planResult.first;
      int mealsCount = plan['meals_per_day'] as int;

      // Create Task 1 (Lunch)
      await db.insert('daily_deliveries', {
        'date': dateStr,
        'customer_id': cust['id'],
        'customer_name': cust['name'],
        'address': cust['address'],
        'meal_type': 'Lunch', // You can change logic later if needed
        'status': 'Pending',
      });

      // Create Task 2 (Dinner - if applicable)
      if (mealsCount > 1) {
        await db.insert('daily_deliveries', {
          'date': dateStr,
          'customer_id': cust['id'],
          'customer_name': cust['name'],
          'address': cust['address'],
          'meal_type': 'Dinner',
          'status': 'Pending',
        });
      }
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
