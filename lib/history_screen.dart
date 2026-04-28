import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Stream<QuerySnapshot> getHistory() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> deleteItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('history')
        .doc(docId)
        .delete();
  }

  Future<void> clearAll() async {
    final user = FirebaseAuth.instance.currentUser;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('history')
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "No time";

    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Past Trips"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: clearAll,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No history yet 🚫"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final docId = data.id;

              return Dismissible(
                key: Key(docId),
                background: Container(color: Colors.red),
                onDismissed: (_) => deleteItem(docId),

                child: Card(
                  margin: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.history),

                    title: Text(
                      "${data['source']} → ${data['destination']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Text(
                      formatTime(data['timestamp']),
                    ),

                    // 🔁 SEND DATA BACK TO MAP SCREEN
                    onTap: () {
                      Navigator.pop(context, {
                        "source": data['source'],
                        "destination": data['destination'],
                      });
                    },

                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteItem(docId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
