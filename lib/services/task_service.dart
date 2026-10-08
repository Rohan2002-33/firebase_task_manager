import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  TaskService._();
  static final TaskService instance = TaskService._();

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  Stream<List<TaskModel>> watchTasks() {
    return _col
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map(TaskModel.fromDoc).toList());
  }

  Future<String> addTask(TaskModel task) async {
    final ref = await _col.add(task.toMap());
    return ref.id;
  }

  Future<void> updateTask(TaskModel task) =>
      _col.doc(task.id).update(task.toMap());

  Future<void> setCompleted(String id, bool value) =>
      _col.doc(id).update({'isCompleted': value});

  Future<void> deleteTask(String id) => _col.doc(id).delete();

  Future<TaskModel?> getTask(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? TaskModel.fromDoc(doc) : null;
  }
}