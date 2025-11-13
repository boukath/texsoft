// lib/core/services/database/daos/user_dao.dart
import 'package:sqflite/sqflite.dart';
import '../../../models/user_model.dart';
import '../../../models/role_model.dart';
import '../database_helper.dart';

class UserDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<User?> validateLogin(String username, String password) async {
    final db = await _db;
    final hashedPassword = DatabaseHelper.instance.hashPassword(password);
    final List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'username = ? AND hashedPassword = ?',
      whereArgs: [username, hashedPassword],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('Users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<bool> createUser(String username, String password, UserRole role) async {
    if (await getUserByUsername(username) != null) return false;
    final db = await _db;
    await db.insert('Users', {
      'username': username,
      'hashedPassword': DatabaseHelper.instance.hashPassword(password),
      'role': userRoleToString(role),
    });
    return true;
  }

  Future<void> deleteUser(int id) async {
    final db = await _db;
    await db.delete('Users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await _db;
    final maps = await db.query('Users', where: 'username = ?', whereArgs: [username]);
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }
}