import 'package:flutter/material.dart';

class FakeNotesScreen extends StatelessWidget {
  const FakeNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Personal Notes',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fakeNotes.length,
        itemBuilder: (context, index) {
          final note = _fakeNotes[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.note, color: Colors.blue),
              title: Text(note['title'] as String),
              subtitle: Text(note['preview'] as String),
              trailing: Text(
                note['date'] as String,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  static const List<Map<String, String>> _fakeNotes = [
    {
      'title': 'Grocery List',
      'preview': 'Milk, Eggs, Bread, Butter...',
      'date': '2026-05-01',
    },
    {
      'title': 'Meeting Notes',
      'preview': 'Discuss Q2 targets and deliverables...',
      'date': '2026-04-28',
    },
    {
      'title': 'Book Recommendations',
      'preview': 'The Great Gatsby, 1984, Brave New World...',
      'date': '2026-04-25',
    },
    {
      'title': 'Workout Plan',
      'preview': 'Monday: Chest, Tuesday: Back...',
      'date': '2026-04-20',
    },
  ];
}

class FakeDashboardScreen extends StatelessWidget {
  const FakeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildFakeCard('Tasks', Icons.check_circle, Colors.green),
          _buildFakeCard('Calendar', Icons.calendar_today, Colors.orange),
          _buildFakeCard('Messages', Icons.message, Colors.blue),
          _buildFakeCard('Files', Icons.folder, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildFakeCard(String title, IconData icon, Color color) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
