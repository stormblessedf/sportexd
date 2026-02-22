import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../domain/domain.dart';
import '../data/live_broadcast_service.dart';
import '../data/agora_service.dart';
import 'widgets/widgets.dart';

/// Izleyici ekrani - Canli yayin izleme
class ViewerScreen extends StatefulWidget {
  final String streamId;

  const ViewerScreen({
    super.key,
    required this.streamId,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen>
    with SingleTickerProviderStateMixin {
  late LiveBroadcastService _service;
  late StreamManager _streamManager;
  late ViewerTracker _viewerTracker;
  late ConnectionManager _connectionManager;
  late ChatManager _chatManager;
  late ReactionManager _reactionManager;
  late AgoraService _agoraService;

  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  bool _isAgoraReady = false;
  final List<_FloatingReaction> _floatingReactions = [];
  bool _wasLive = false;
  bool _endedDialogShown = false;

  @override
  void initState() {
    super.initState();
    _initManagers();
    _loadStream();
  }

  void _initManagers() {
    _service = LiveBroadcastService();
    _streamManager = StreamManager(service: _service);
    _viewerTracker = ViewerTracker(service: _service);
    _connectionManager = ConnectionManager();
    _chatManager = ChatManager(service: _service);
    _reactionManager = ReactionManager(service: _service);
    _agoraService = AgoraService();

    _reactionManager.onReactionReceived = _onReactionReceived;
    _connectionManager.onReconnectFailed = _onReconnectFailed;

    _streamManager.addListener(_onStreamStateChanged);

    // Listen for remote user joining (broadcaster)
    _agoraService.remoteUidNotifier.addListener(_onRemoteUserChanged);
  }

  void _onRemoteUserChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadStream() async {
    debugPrint('[ViewerScreen] Loading stream: ${widget.streamId}');
    final stream = await _streamManager.joinStream(widget.streamId);

    if (stream != null) {
      debugPrint('[ViewerScreen] Stream loaded: ${stream.id}, status: ${stream.status}');

      if (stream.status == StreamStatus.live) {
        _wasLive = true;
      }

      _viewerTracker.startTracking(widget.streamId);
      _connectionManager.startMonitoring();
      _chatManager.joinChatRoom(widget.streamId);
      _reactionManager.joinStream(widget.streamId);

      // Initialize Agora and join as audience
      await _initAgoraViewer(widget.streamId);

      // Check follow status
      _checkFollowStatus(stream.broadcasterId);
    } else {
      debugPrint('[ViewerScreen] Failed to load stream');
    }
  }

  Future<void> _initAgoraViewer(String channelName) async {
    try {
      await _agoraService.initialize();
      await _agoraService.joinAsAudience(channelName);
      if (mounted) {
        setState(() => _isAgoraReady = true);
      }
    } catch (e) {
      debugPrint('[ViewerScreen] Agora init error: $e');
      if (mounted) {
        _showError('Video baglantisi kurulamadi: $e');
      }
    }
  }

  Future<void> _checkFollowStatus(String broadcasterId) async {
    final isFollowing = await _service.isFollowing(broadcasterId);
    if (mounted) {
      setState(() => _isFollowing = isFollowing);
    }
  }

  void _onStreamStateChanged() {
    if (!mounted) return;

    debugPrint('[ViewerScreen] Stream state changed: ${_streamManager.status}, wasLive: $_wasLive');

    if (_streamManager.status == StreamStatus.live) {
      _wasLive = true;
    }

    if (_streamManager.status == StreamStatus.ended && _wasLive && !_endedDialogShown) {
      _endedDialogShown = true;
      _agoraService.leaveChannel();
      _showStreamEndedDialog();
    }

    if (_streamManager.errorMessage != null) {
      _showError(_streamManager.errorMessage!);
      _streamManager.clearError();
    }
  }

  void _onReactionReceived(Reaction reaction) {
    if (!mounted) return;

    setState(() {
      _floatingReactions.add(_FloatingReaction(
        key: UniqueKey(),
        reaction: reaction,
        onComplete: (key) {
          setState(() {
            _floatingReactions.removeWhere((r) => r.key == key);
          });
        },
      ));
    });
  }

  void _onReconnectFailed(String message) {
    _showError(message);
  }

  Future<void> _toggleFollow() async {
    final stream = _streamManager.currentStream;
    if (stream == null) return;

    setState(() => _isLoadingFollow = true);

    try {
      if (_isFollowing) {
        await _service.unfollowBroadcaster(stream.broadcasterId);
      } else {
        await _service.followBroadcaster(stream.broadcasterId);
      }

      setState(() => _isFollowing = !_isFollowing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing
                ? '${stream.broadcasterName} takip edildi'
                : 'Takipten cikildi'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Islem basarisiz oldu');
    } finally {
      setState(() => _isLoadingFollow = false);
    }
  }

  void _showStreamEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Yayin Sona Erdi'),
        content: const Text('Bu yayin sonlandirildi.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showQualitySettings() {
    final currentQuality =
        _streamManager.currentStream?.quality ?? StreamQuality.auto;

    showModalBottomSheet(
      context: context,
      builder: (context) => QualitySettingsSheet(
        currentQuality: currentQuality,
        onQualitySelected: (quality) {
          _streamManager.changeQuality(quality);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _sendReaction() async {
    await _reactionManager.sendReaction();
  }

  @override
  void dispose() {
    _agoraService.remoteUidNotifier.removeListener(_onRemoteUserChanged);
    _streamManager.removeListener(_onStreamStateChanged);
    _streamManager.leaveStream();
    _viewerTracker.stopTracking();
    _connectionManager.stopMonitoring();
    _chatManager.leaveChatRoom();
    _reactionManager.leaveStream();
    _agoraService.dispose();
    _streamManager.dispose();
    _viewerTracker.dispose();
    _connectionManager.dispose();
    _chatManager.dispose();
    _reactionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _streamManager),
        ChangeNotifierProvider.value(value: _viewerTracker),
        ChangeNotifierProvider.value(value: _connectionManager),
        ChangeNotifierProvider.value(value: _chatManager),
        ChangeNotifierProvider.value(value: _reactionManager),
      ],
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<StreamManager>(
          builder: (context, manager, _) {
            if (manager.isLoading && manager.currentStream == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (manager.currentStream == null) {
              return _buildErrorState();
            }

            return Stack(
              children: [
                // Agora remote video
                _buildVideoPlayer(),

                // Floating reactions
                ..._floatingReactions.map((r) => _FloatingReactionWidget(
                      key: r.key,
                      reaction: r.reaction,
                      onComplete: () => r.onComplete(r.key),
                    )),

                // Top bar
                _buildTopBar(manager.currentStream!),

                // Event card
                _buildEventCard(manager.currentStream!),

                // Chat overlay
                _buildChatOverlay(),

                // Bottom controls
                _buildBottomControls(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Yayin yuklenemedi',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStream,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isAgoraReady || _agoraService.engine == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Yayina baglaniliyor...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final remoteUid = _agoraService.remoteUid;
    if (remoteUid == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Yayinci bekleniyor...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraService.engine!,
          canvas: VideoCanvas(uid: remoteUid),
          connection: const RtcConnection(channelId: 'test123'), // Temp test channel
        ),
      ),
    );
  }

  Widget _buildTopBar(StreamSession stream) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            // Broadcaster info
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: stream.broadcasterAvatar.isNotEmpty
                        ? NetworkImage(stream.broadcasterAvatar)
                        : null,
                    child: stream.broadcasterAvatar.isEmpty
                        ? Text(stream.broadcasterName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stream.broadcasterName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Host',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Follow button
            _buildFollowButton(),

            const SizedBox(width: 8),

            // Live indicator
            Consumer<ViewerTracker>(
              builder: (context, tracker, _) => LiveIndicator(
                viewerCount: tracker.currentViewerCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton() {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: _isLoadingFollow ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoadingFollow
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(_isFollowing ? 'Takip Ediliyor' : 'Takip Et'),
      ),
    );
  }

  Widget _buildEventCard(StreamSession stream) {
    return Positioned(
      top: 100,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_soccer, color: Colors.white70, size: 16),
                SizedBox(width: 6),
                Text(
                  'Etkinlik',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stream.eventName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      right: 100,
      bottom: 100,
      child: SizedBox(
        height: 200,
        child: Consumer<ChatManager>(
          builder: (context, chatManager, _) => ChatOverlay(
            messages: chatManager.messages,
            onSendMessage: chatManager.sendMessage,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: _buildMessageInput(),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _showQualitySettings,
                icon: const Icon(Icons.settings, color: Colors.white),
              ),
              GestureDetector(
                onTap: _sendReaction,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final controller = TextEditingController();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Mesaj yaz...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (text) async {
                if (text.trim().isNotEmpty) {
                  await _chatManager.sendMessage(text);
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            onPressed: () async {
              final text = controller.text;
              if (text.trim().isNotEmpty) {
                await _chatManager.sendMessage(text);
                controller.clear();
              }
            },
            icon: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Floating reaction helper classes
class _FloatingReaction {
  final Key key;
  final Reaction reaction;
  final void Function(Key) onComplete;

  _FloatingReaction({
    required this.key,
    required this.reaction,
    required this.onComplete,
  });
}

class _FloatingReactionWidget extends StatefulWidget {
  final Reaction reaction;
  final VoidCallback onComplete;

  const _FloatingReactionWidget({
    super.key,
    required this.reaction,
    required this.onComplete,
  });

  @override
  State<_FloatingReactionWidget> createState() =>
      _FloatingReactionWidgetState();
}

class _FloatingReactionWidgetState extends State<_FloatingReactionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _positionAnimation;
  late double _startX;

  @override
  void initState() {
    super.initState();

    _startX = 16 + (50 * (DateTime.now().millisecondsSinceEpoch % 5) / 5);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0),
      ),
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -150),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: _startX,
      bottom: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: _positionAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Text(
              widget.reaction.type.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chat overlay widget
class ChatOverlay extends StatelessWidget {
  final List<ChatMessage> messages;
  final Future<bool> Function(String) onSendMessage;

  const ChatOverlay({
    super.key,
    required this.messages,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
        ],
        stops: const [0.0, 0.15, 1.0],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return _ChatMessageItem(message: message);
        },
      ),
    );
  }
}

class _ChatMessageItem extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: message.userAvatar.isNotEmpty
                ? NetworkImage(message.userAvatar)
                : null,
            child: message.userAvatar.isEmpty
                ? Text(
                    message.userName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: TextStyle(
                        color: message.isFromBroadcaster
                            ? Colors.amber
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (message.isFromBroadcaster) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Host',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  message.message,
                  style: const TextStyle(color: Colors.white),
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
