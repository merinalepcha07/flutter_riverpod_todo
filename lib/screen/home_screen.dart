import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Task {
  final String title;
  final bool isCompleted;

  Task({required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() {
    return {'title': title, 'isCompleted': isCompleted};
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      title: map['title'],
      isCompleted: map['isCompleted'],
    );
  }
}

// StateNotifier for managing tasks
class TodoNotifier extends StateNotifier<List<Task>> {
  TodoNotifier() : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getStringList('tasks') ?? [];
    final loadedTasks = savedData
        .map((e) => Task.fromMap(Map<String, dynamic>.from(jsonDecode(e))))
        .toList();
    state = loadedTasks;
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskList = state.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('tasks', taskList);
  }

  Future<void> addTask(String title) async {
    if (title.isEmpty) return;
    final newTask = Task(title: title);
    state = [...state, newTask];
    await _saveTasks();
  }

  Future<void> deleteTask(int index) async {
    final updated = List<Task>.from(state)..removeAt(index);
    state = updated;
    await _saveTasks();
  }

  Future<void> toggleTask(int index) async {
    final updated = List<Task>.from(state);
    final task = updated[index];
    updated[index] = Task(title: task.title, isCompleted: !task.isCompleted);
    state = updated;
    await _saveTasks();
  }

  //  Clear all completed tasks
  Future<void> clearCompleted() async {
    final updated = state.where((task) => !task.isCompleted).toList();
    state = updated;
    await _saveTasks();
  }
}


final todoProvider =
    StateNotifierProvider<TodoNotifier, List<Task>>((ref) => TodoNotifier());

// HomeScreen UI
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final todoList = ref.watch(todoProvider);
    final completedTasks =
        todoList.where((task) => task.isCompleted).toList().length;

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 550,
          child: Card(
            elevation: 10,
            child: Column(
              children: [
                // Input
                Container(
                  width: 250,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                      hintText: 'Enter your task',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Add button
                Container(
                  width: 250,
                  height: 50,
                  margin: const EdgeInsets.only(top: 10),
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(todoProvider.notifier)
                          .addTask(_controller.text.trim());
                      _controller.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Add Task',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Clear completed button (only shows when some tasks are done)
                if (completedTasks > 0)
                  Container(
                    width: 250,
                    height: 45,
                    margin: const EdgeInsets.only(top: 5),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(todoProvider.notifier).clearCompleted();
                      },
                      icon: const Icon(Icons.cleaning_services_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Clear Completed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                // Task List
                Expanded(
                  child: todoList.isEmpty
                      ? const Center(
                          child: Text('No tasks yet!',
                              style: TextStyle(fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: todoList.length,
                          itemBuilder: (context, index) {
                            final task = todoList[index];
                            return Container(
                              width: 250,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              margin: const EdgeInsets.only(
                                  top: 10, left: 20, right: 20),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.isCompleted,
                                  onChanged: (_) async {
                                    await ref
                                        .read(todoProvider.notifier)
                                        .toggleTask(index);
                                  },
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: task.isCompleted
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    await ref
                                        .read(todoProvider.notifier)
                                        .deleteTask(index);
                                  },
                                  child: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
