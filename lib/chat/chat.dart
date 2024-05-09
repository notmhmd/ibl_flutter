import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ibl_flutter/chat/chat_bubble.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final WebSocketChannel channel =
      IOWebSocketChannel.connect('ws://192.168.0.213:8000/ws/chat/?key=123');
  List<Map<String, dynamic>> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: channel.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _parseMessages(snapshot);
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = messages.length - 1 - index;
                      return ChatBubble(
                        message: messages[reversedIndex]['message'],
                        isSent: messages[reversedIndex]['isSent'],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoTextField(
                      controller: _controller,
                      onSubmitted: (String str) {
                        if (_controller.text.isNotEmpty) {
                          _sendMessage(_controller.text);
                          _controller.clear();
                        }
                      },
                      textInputAction: TextInputAction.done,
                      onEditingComplete: () {},
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const BoxDecoration(),
                      placeholder: 'Send a message...'),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(CupertinoIcons.arrow_right_circle_fill),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _parseMessages(AsyncSnapshot<dynamic> snapshot) {
    if (snapshot.hasData) {
      var data = json.decode(snapshot.data);
      String receivedMessage = data['message'];

      // Check if the received message is already present in the messages list
      bool messageExists =
          messages.any((message) => message['message'] == receivedMessage);

      // If the message doesn't exist in the list, add it
      if (!messageExists) {
        Future.microtask(() {
          setState(() {
            messages.add({'message': receivedMessage, 'isSent': false});
          });
        });
      }
    }
  }

  void _sendMessage(String message) {
    var jsonMessage = json.encode({'message': message});
    channel.sink.add(jsonMessage);
    setState(() {
      messages.add({'message': message, 'isSent': true});
    });
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
