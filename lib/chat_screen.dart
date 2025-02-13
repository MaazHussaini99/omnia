import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;

  ChatScreen({required this.receiverId, required this.receiverEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final User _currentUser = FirebaseAuth.instance.currentUser!;

  void _sendMessage() async {
    if (_textController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('messages').add({
        'text': _textController.text.trim(),
        'senderId': _currentUser.uid,
        'receiverId': widget.receiverId,
        'email': _currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _textController.clear();
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: () => _logout(context))],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs.where((msg) =>
                    (msg['senderId'] == _currentUser.uid && msg['receiverId'] == widget.receiverId) ||
                    (msg['senderId'] == widget.receiverId && msg['receiverId'] == _currentUser.uid));

                return ListView(
                  reverse: true,
                  children: messages.map((message) {
                    final bool isMe = message['senderId'] == _currentUser.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(message['email'], style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(message['text']),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _textController, decoration: InputDecoration(hintText: 'Type a message')),
                ),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
