import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/meetup_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatScreen({super.key, required this.chatId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final MeetupService _meetupService = MeetupService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isChatLocked = false;
  bool _isOrganizer = false;
  bool _isOrganizerOnlyMode = false;

  // Reply state
  MessageModel? _replyingTo;

  // Edit state
  MessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _markChatNotificationAsRead();
    _listenToChatMode();
  }

  void _listenToChatMode() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
          if (mounted && snapshot.exists) {
            final data = snapshot.data();
            setState(() {
              _isOrganizerOnlyMode = data?['isOrganizerOnlyMode'] ?? false;
            });
          }
        });
  }

  Future<void> _loadData() async {
    await Future.wait([_loadUser(), _loadMeetup()]);
  }

  Future<void> _loadMeetup() async {
    try {
      final meetup = await _meetupService.getMeetupById(widget.chatId);
      if (mounted && meetup != null) {
        setState(() {
          _isChatLocked = _meetupService.isMeetupPast(meetup);
          _isOrganizer = meetup.organizerId == _authService.currentUserId;
        });
      }
    } catch (e) {
      debugPrint('Error loading meetup: $e');
    }
  }

  Future<void> _toggleOrganizerOnlyMode() async {
    try {
      final nextValue = !_isOrganizerOnlyMode;
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({
            'isOrganizerOnlyMode': nextValue,
          }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('meetups')
          .doc(widget.chatId)
          .set({
            'isOrganizerOnlyChat': nextValue,
          }, SetOptions(merge: true));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isOrganizerOnlyMode
                  ? l10n.everyoneCanSend
                  : l10n.onlyOrganizerCanSend,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling organizer only mode: $e');
    }
  }

  Future<void> _markChatNotificationAsRead() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    try {
      final notifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'chat_message')
          .where('relatedId', isEqualTo: widget.chatId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        await doc.reference.update({
          'isRead': true,
          'metadata.unreadCount': 0,
        });
      }
    } catch (e) {
      debugPrint('Error marking chat notification as read: $e');
    }
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  bool get _canSendMessage {
    if (_isChatLocked) return false;
    if (_isOrganizerOnlyMode && !_isOrganizer) return false;
    return true;
  }

  Future<void> _sendMessage({bool isAnnouncement = false}) async {
    if (_controller.text.trim().isEmpty || _currentUser == null) return;
    if (!_canSendMessage) return;

    final messageText = _controller.text.trim();
    _controller.clear();

    // Handle edit mode
    if (_editingMessage != null) {
      final success = await _chatService.editMessage(
        chatId: widget.chatId,
        messageId: _editingMessage!.id,
        senderId: _currentUser!.id,
        newText: messageText,
      );

      if (mounted) {
        setState(() => _editingMessage = null);
        if (!success) {
          _controller.text = messageText;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.editFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // Handle normal/reply message
    final success = await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.username,
      senderImageUrl: _currentUser!.profileImageUrl,
      text: isAnnouncement ? '📢 DUYURU: $messageText' : messageText,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      replyToSenderName: _replyingTo?.senderName,
    );

    if (mounted) {
      setState(() => _replyingTo = null);
      if (!success) {
        _controller.text = messageText;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sendFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.deleteMessage(
        chatId: widget.chatId,
        messageId: message.id,
        senderId: _currentUser!.id,
      );
    }
  }

  void _startReply(MessageModel message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null;
    });
  }

  void _startEdit(MessageModel message) {
    setState(() {
      _editingMessage = message;
      _replyingTo = null;
      _controller.text = message.text;
    });
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _controller.clear();
    });
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  Color _getNameColor(String visitorId) {
    final colors = [
      Colors.redAccent,
      Colors.green,
      Colors.blueAccent,
      Colors.orange,
      Colors.purpleAccent,
      Colors.teal,
    ];
    return colors[visitorId.hashCode.abs() % colors.length];
  }

  void _showMessageOptions(MessageModel message) {
    final isMe = message.senderId == _currentUser?.id;
    if (message.isDeleted) return;

    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canSendMessage) ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(l10n.reply),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.copy),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.messageCopied)),
                );
              },
            ),
            if (isMe && !_isChatLocked) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(l10n.edit),
                onTap: () {
                  Navigator.pop(context);
                  _startEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(child: Text(AppLocalizations.of(context)!.loginToJoinChat)),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Organizer-only mode toggle (only visible to organizer)
          if (_isOrganizer)
            IconButton(
              icon: Icon(
                _isOrganizerOnlyMode ? Icons.lock : Icons.lock_open,
                color: _isOrganizerOnlyMode ? Colors.orange : null,
              ),
              tooltip: _isOrganizerOnlyMode ? l10n.openToAll : l10n.organizerOnly,
              onPressed: _toggleOrganizerOnlyMode,
            ),
          if (_isOrganizer)
            IconButton(
              icon: const Icon(Icons.campaign),
              tooltip: l10n.sendAnnouncement,
              onPressed: () => _showAnnouncementDialog(),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Organizer only mode banner
            if (_isOrganizerOnlyMode)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.orange.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOrganizer
                          ? l10n.organizerModeActive
                          : l10n.onlyOrganizerCanSend,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            // Chat locked banner
            if (_isChatLocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: Colors.grey.withValues(alpha: 0.2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      l10n.chatReadOnly,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(l10n.noMessagesFirst),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final message = snapshot.data![index];
                      final isMe = message.senderId == _currentUser!.id;
                      final isAnnouncement = message.text.startsWith(
                        '📢 DUYURU:',
                      );

                      return GestureDetector(
                        onLongPress: () => _showMessageOptions(message),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: isAnnouncement
                              ? _buildAnnouncementMessage(message)
                              : _buildRegularMessage(message, isMe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementMessage(MessageModel message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                message.senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text.replaceFirst('📢 DUYURU: ', ''),
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularMessage(MessageModel message, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          GestureDetector(
            onTap: () => context.push('/user-profile/${message.senderId}'),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[800],
              backgroundImage: message.senderImageUrl?.isNotEmpty == true
                  ? NetworkImage(message.senderImageUrl!)
                  : null,
              child: message.senderImageUrl?.isEmpty != false
                  ? Text(
                      message.senderName.isNotEmpty
                          ? message.senderName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isDeleted
                  ? Colors.grey[700]
                  : isMe
                  ? Theme.of(context).primaryColor
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply preview
                if (message.replyToText != null && !message.isDeleted) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: _getNameColor(message.replyToSenderName ?? ''),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.replyToSenderName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getNameColor(
                              message.replyToSenderName ?? '',
                            ),
                          ),
                        ),
                        Text(
                          message.replyToText!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0),
                    child: GestureDetector(
                      onTap: () =>
                          context.push('/user-profile/${message.senderId}'),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getNameColor(message.senderId),
                        ),
                      ),
                    ),
                  ),
                Text(
                  message.isDeleted ? '🚫 ${AppLocalizations.of(context)!.messageDeleted}' : message.text,
                  style: TextStyle(
                    color: message.isDeleted ? Colors.grey[400] : Colors.white,
                    fontSize: 16,
                    fontStyle: message.isDeleted
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited && !message.isDeleted)
                      Text(
                        '${AppLocalizations.of(context)!.edited} • ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    // Chat locked (past event)
    if (_isChatLocked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.cannotSendMessages,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Organizer only mode and user is not organizer
    if (_isOrganizerOnlyMode && !_isOrganizer) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 16,
              color: Colors.orange[300],
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.onlyOrganizerCanSend,
              style: TextStyle(color: Colors.orange[300]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply/Edit preview bar
          if (_replyingTo != null || _editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF1E1E1E),
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit : Icons.reply,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingMessage != null
                              ? AppLocalizations.of(context)!.editing
                              : _replyingTo!.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Text(
                          _editingMessage?.text ?? _replyingTo!.text,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReplyOrEdit,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _editingMessage != null
                          ? AppLocalizations.of(context)!.editMessageHint
                          : AppLocalizations.of(context)!.writeMessageHint,
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 24,
                  child: IconButton(
                    icon: Icon(
                      _editingMessage != null ? Icons.check : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final announcementController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.amber),
            const SizedBox(width: 8),
            Text(l10n.sendAnnouncement),
          ],
        ),
        content: TextField(
          controller: announcementController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.announcementHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (announcementController.text.trim().isNotEmpty) {
                _controller.text = announcementController.text.trim();
                _sendMessage(isAnnouncement: true);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
