import "package:flutter/material.dart";
import 'dart:io';
import 'dart:convert';
import 'dart:async';


class SocketWrapper {
  final Socket _socket;
  late final StreamController<List<int>> _controller;
  StreamSubscription? _subscription;
  
  SocketWrapper(this._socket) {
    _controller = StreamController<List<int>>.broadcast();
    
    _subscription = _socket.listen(
      (data) => _controller.add(data),
      onError: (error) => _controller.addError(error),
      onDone: () => _controller.close(),
      cancelOnError: false,
    );
  }
  
  Stream<List<int>> get stream => _controller.stream;
  
  void write(List<int> data) {
    _socket.add(data);
  }
  
  void close() {
    _subscription?.cancel();
    _controller.close();
    _socket.close();
  }
}

void main() {
  runApp(SajiloChat());
}

class SajiloChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sajilo Chat',
      theme: ThemeData(
        primaryColor: Color(0xFF075E54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF075E54),
          secondary: Color(0xFF25D366),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ============================================================================
// LOGIN PAGE
// ============================================================================
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _serverController = TextEditingController(text: '192.168.0.100');
  final _portController = TextEditingController(text: '5050');
  bool _isLoading = false;

  Future<void> _connect() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final host = _serverController.text;
        final port = int.parse(_portController.text);
        final username = _usernameController.text;

        print('🔌 Connecting to $host:$port...');
        
        final socket = await Socket.connect(
          host,
          port,
          timeout: Duration(seconds: 10),
        );

        final wrappedSocket = SocketWrapper(socket);
        final intro = jsonEncode({
        'type': 'set_username',
        'username': username,
          }) + '\n';

      wrappedSocket.write(utf8.encode(intro));

        print('✅ Connected!');
        
        setState(() => _isLoading = false);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatsListPage(
              socket: wrappedSocket,
              username: username,
            ),
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        print('❌ Error: $e');
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: Color(0xFF667eea),
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Sajilo Chat',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Connect to start chatting!',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        SizedBox(height: 50),
                        
                        _buildTextField(
                          controller: _usernameController,
                          hintText: 'Username',
                          icon: Icons.person,
                          validator: (v) => v?.isEmpty ?? true ? 'Enter username' : null,
                        ),
                        SizedBox(height: 20),
                        
                        _buildTextField(
                          controller: _serverController,
                          hintText: 'Server IP',
                          icon: Icons.dns,
                          validator: (v) => v?.isEmpty ?? true ? 'Enter IP' : null,
                        ),
                        SizedBox(height: 20),
                        
                        _buildTextField(
                          controller: _portController,
                          hintText: 'Port',
                          icon: Icons.power,
                          keyboardType: TextInputType.number,
                          validator: (v) => v?.isEmpty ?? true ? 'Enter port' : null,
                        ),
                        SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _connect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Color(0xFF667eea),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '💡 Quick Start',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '1. Start server: python chatroom_server.py',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                '2. Use "localhost" for same PC',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                '3. Port: 5050',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Color(0xFF667eea)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    super.dispose();
  }
}

// ============================================================================
// CHAT LIST PAGE
// ============================================================================
class ChatsListPage extends StatefulWidget {
  final SocketWrapper socket;
  final String username;

  const ChatsListPage({
    Key? key,
    required this.socket,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  StreamSubscription? _socketSubscription;
  List<String> _onlineUsers = [];
  Map<String, int> _unreadCounts = {'group': 0};
  Map<String, String> _lastMessages = {'group': 'No messages yet'};
  bool _isConnected = true;
  String _buffer = '';

  @override
void initState() {
  super.initState();
  _setupSocketListener();
  
  // FIX: Request users after a brief delay to ensure the listener is active
  Future.delayed(Duration(milliseconds: 500), () {
    print('[ChatList] Requesting user list...');
    
        final request = jsonEncode({
       'type': 'request_users',
  '     message': 'Requesting list'
        }) + '\n';

  widget.socket.write(utf8.encode(request));
    
  });
}
  void _setupSocketListener() {
    print('[ChatList] Setting up listener');
    
    _socketSubscription = widget.socket.stream.listen(
      (data) {
        _buffer += utf8.decode(data);
        
        while (_buffer.contains('\n')) {
          final index = _buffer.indexOf('\n');
          final message = _buffer.substring(0, index);
          _buffer = _buffer.substring(index + 1);
          
          if (message.trim().isEmpty) continue;
          
          try {
            final jsonData = jsonDecode(message);
            final type = jsonData['type'];

            if (type == 'request_username') {
              final response = jsonEncode({'username': widget.username}) + '\n';
              widget.socket.write(utf8.encode(response));
              
            } else if (type == 'user_list') {
              setState(() {
                _onlineUsers = List<String>.from(jsonData['users'])
                  ..remove(widget.username);
              });
              
            } else if (type == 'group') {
              final from = jsonData['from'];
              final msg = jsonData['message'];

              


              setState(() {
                _lastMessages['group'] = '$from: $msg';
                _unreadCounts['group'] = (_unreadCounts['group'] ?? 0) + 1;
              });
              
              
            } else if (type == 'dm') {
              final from = jsonData['from'];
              final msg = jsonData['message'];
              if (from != widget.username) {
                setState(() {
                  _lastMessages[from] = msg;
                  _unreadCounts[from] = (_unreadCounts[from] ?? 0) + 1;
                });
              }
            }
          } catch (e) {
            print('[ChatList] Parse error: $e');
          }
        }
      },
      onError: (error) {
        setState(() => _isConnected = false);
        _showDisconnectDialog();
      },
      onDone: () {
        setState(() => _isConnected = false);
        _showDisconnectDialog();
      },
      cancelOnError: false,
    );
  }

  void _showDisconnectDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Disconnected'),
        content: Text('Lost connection to server'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openChat(String chatWith) {
    setState(() {
      _unreadCounts[chatWith] = 0;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          socket: widget.socket,
          username: widget.username,
          chatWith: chatWith,
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _unreadCounts[chatWith] = 0;
        });
      }
    });
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.pink, Colors.blue, Colors.green, Colors.orange,
      Colors.teal, Colors.purple, Colors.red, Colors.indigo,
    ];
    return colors[index % colors.length];
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allChats = ['Group Chat', ..._onlineUsers];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        title: Row(
          children: [
            Text(
              'Sajilo Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isConnected ? 'Online' : 'Offline',
                style: TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'Logout') {
                widget.socket.close();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: allChats.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Waiting for users...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: allChats.length,
              itemBuilder: (context, index) {
                final chatName = allChats[index];
                final isGroup = chatName == 'Group Chat';
                final chatKey = isGroup ? 'group' : chatName;
                final unreadCount = _unreadCounts[chatKey] ?? 0;
                final lastMessage = _lastMessages[chatKey] ??
                    (isGroup ? 'No messages' : 'Start chat!');

                return ChatListTile(
                  name: chatName,
                  message: lastMessage,
                  time: 'Now',
                  unreadCount: unreadCount,
                  avatarColor: _getAvatarColor(index),
                  isGroup: isGroup,
                  onTap: () => _openChat(chatKey),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF25D366),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tap a user to chat!')),
          );
        },
        child: Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}

// ============================================================================
// CHAT LIST TILE
// ============================================================================
class ChatListTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final Color avatarColor;
  final bool isGroup;
  final VoidCallback onTap;

  const ChatListTile({
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.avatarColor,
    required this.isGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: avatarColor,
              child: isGroup
                  ? Icon(Icons.group, color: Colors.white, size: 28)
                  : Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? Color(0xFF25D366)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CHAT SCREEN
// ============================================================================
class ChatScreen extends StatefulWidget {
  final SocketWrapper socket;
  final String username;
  final String chatWith;

  const ChatScreen({
    Key? key,
    required this.socket,
    required this.username,
    required this.chatWith,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _socketSubscription;
  String _buffer = '';

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    _socketSubscription = widget.socket.stream.listen(
      (data) {
        _buffer += utf8.decode(data);
        
        while (_buffer.contains('\n')) {
          final index = _buffer.indexOf('\n');
          final message = _buffer.substring(0, index);
          _buffer = _buffer.substring(index + 1);
          
          if (message.trim().isEmpty) continue;
          
          try {
            final jsonData = jsonDecode(message);
            final type = jsonData['type'];

            if (type == 'group' && widget.chatWith == 'group') {
              setState(() {
                _messages.add({
                  'from': jsonData['from'],
                  'message': jsonData['message'],
                  'isMe': jsonData['from'] == widget.username,
                });
              });
              _scrollToBottom();
              
            } else if (type == 'dm') {
              final from = jsonData['from'];
              final to = jsonData['to'];

              if ((from == widget.username && to == widget.chatWith) ||
                  (from == widget.chatWith)) {
                setState(() {
                  _messages.add({
                    'from': from,
                    'message': jsonData['message'],
                    'isMe': from == widget.username,
                  });
                });
                _scrollToBottom();
              }
            }
          } catch (e) {
            print('[ChatScreen] Parse error: $e');
          }
        }
      },
      cancelOnError: false,
    );
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageData = widget.chatWith == 'group'
        ? {
            'type': 'group',
            'message': _messageController.text,
          }
        : {
            'type': 'dm',
            'to': widget.chatWith,
            'message': _messageController.text,
          };

    final msg = jsonEncode(messageData) + '\n';
    widget.socket.write(utf8.encode(msg));
    _messageController.clear();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF075E54),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: widget.chatWith == 'group'
                  ? Icon(Icons.group, color: Color(0xFF075E54))
                  : Text(
                      widget.chatWith[0].toUpperCase(),
                      style: TextStyle(color: Color(0xFF075E54)),
                    ),
            ),
            SizedBox(width: 12),
            Text(
              widget.chatWith == 'group' ? 'Group Chat' : widget.chatWith,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Container(
        color: Color(0xFFECE5DD),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start the conversation!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return MessageBubble(
                          message: msg['message'],
                          isMe: msg['isMe'],
                          sender: msg['from'],
                          showSender: widget.chatWith == 'group' && !msg['isMe'],
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Color(0xFF25D366),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BUBBLE
// ============================================================================
class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String sender;
  final bool showSender;

  const MessageBubble({
    required this.message,
    required this.isMe,
    required this.sender,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
            bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF075E54),
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}