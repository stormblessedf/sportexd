import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../domain/domain.dart';
import '../data/live_broadcast_service.dart';
import '../data/agora_service.dart';
import 'widgets/widgets.dart';

/// Yayinci ekrani - Canli yayin baslatma ve kontrol
class BroadcastScreen extends StatefulWidget {
  final String? eventId;
  final String? eventName;

  const BroadcastScreen({
    super.key,
    this.eventId,
    this.eventName,
  });

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late StreamManager _streamManager;
  late ViewerTracker _viewerTracker;
  late ConnectionManager _connectionManager;
  late ChatManager _chatManager;
  late ReactionManager _reactionManager;
  late AgoraService _agoraService;

  StreamQuality _selectedQuality = StreamQuality.auto;
  PrivacyLevel _selectedPrivacy = PrivacyLevel.public;
  bool _isRecordingEnabled = false;
  bool _isBroadcasting = false;
  bool _isAgoraReady = false;

  @override
  void initState() {
    super.initState();
    _initManagers();
    _initAgora();
  }

  void _initManagers() {
    final service = LiveBroadcastService();
    _streamManager = StreamManager(service: service);
    _viewerTracker = ViewerTracker(service: service);
    _connectionManager = ConnectionManager();
    _chatManager = ChatManager(service: service);
    _reactionManager = ReactionManager(service: service);

    _connectionManager.onQualityChange = (quality) {
      if (_selectedQuality == StreamQuality.auto) {
        _streamManager.changeQuality(quality);
      }
    };

    _streamManager.addListener(_onStreamStateChanged);
  }

  Future<void> _initAgora() async {
    _agoraService = AgoraService();
    try {
      await _agoraService.initialize();
      await _agoraService.setVideoQuality(_selectedQuality);
      if (mounted) {
        setState(() => _isAgoraReady = true);
      }
    } catch (e) {
      debugPrint('[BroadcastScreen] Agora init error: $e');
      if (mounted) {
        _showError('Video motoru baslatılamadı: $e');
      }
    }
  }

  void _onStreamStateChanged() {
    if (!mounted) return;

    if (_streamManager.currentStream != null && !_isBroadcasting) {
      setState(() => _isBroadcasting = true);
      _viewerTracker.startTracking(_streamManager.currentStream!.id);
      _connectionManager.startMonitoring();
      _chatManager.joinChatRoom(_streamManager.currentStream!.id);
      _reactionManager.joinStream(_streamManager.currentStream!.id);

      // Join Agora channel as broadcaster
      _agoraService.joinAsBroadcaster(_streamManager.currentStream!.id);
    }

    if (_streamManager.status == StreamStatus.ended && _isBroadcasting) {
      setState(() => _isBroadcasting = false);
      _agoraService.leaveChannel();
    }

    if (_streamManager.errorMessage != null) {
      _showError(_streamManager.errorMessage!);
      _streamManager.clearError();
    }
  }

  Future<void> _startBroadcast() async {
    if (widget.eventId == null || widget.eventName == null) {
      _showEventSelectionDialog();
      return;
    }

    debugPrint('Starting broadcast for event: ${widget.eventId} - ${widget.eventName}');

    final result = await _streamManager.startBroadcast(
      eventId: widget.eventId!,
      eventName: widget.eventName!,
      quality: _selectedQuality,
      privacy: _selectedPrivacy,
      isRecordingEnabled: _isRecordingEnabled,
    );

    if (result != null && mounted) {
      debugPrint('Broadcast started successfully: ${result.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yayin baslatildi! Artik canlisiniz.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && _streamManager.errorMessage == null) {
      debugPrint('Broadcast failed to start - no result returned');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yayin baslatilamadi. Lutfen tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopBroadcast() async {
    final confirmed = await _showStopConfirmation();
    if (confirmed == true) {
      await _agoraService.leaveChannel();
      final stats = await _streamManager.stopBroadcast();
      if (stats != null && mounted) {
        _showStatisticsDialog(stats);
      }
    }
  }

  void _showEventSelectionDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lutfen bir etkinlik secin')),
    );
  }

  Future<bool?> _showStopConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yayini Sonlandir'),
        content: const Text(
          'Yayini sonlandirmak istediginizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sonlandir'),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog(StreamStatistics stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yayin Istatistikleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Sure', stats.formattedDuration),
            _buildStatRow('Toplam Izleyici', '${stats.totalViewers}'),
            _buildStatRow('Maksimum Izleyici', '${stats.peakViewers}'),
            _buildStatRow('Toplam Mesaj', '${stats.totalMessages}'),
            _buildStatRow('Toplam Tepki', '${stats.totalReactions}'),
          ],
        ),
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showQualitySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => QualitySettingsSheet(
        currentQuality: _selectedQuality,
        onQualitySelected: (quality) {
          setState(() => _selectedQuality = quality);
          _agoraService.setVideoQuality(quality);
          if (_isBroadcasting) {
            _streamManager.changeQuality(quality);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => PrivacySettingsSheet(
        currentPrivacy: _selectedPrivacy,
        onPrivacySelected: (privacy) {
          setState(() => _selectedPrivacy = privacy);
          if (_isBroadcasting) {
            _streamManager.changePrivacy(privacy);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _streamManager.removeListener(_onStreamStateChanged);
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
        body: Stack(
          children: [
            // Agora camera preview
            _buildCameraPreview(),

            // Top bar
            _buildTopBar(),

            // Pre-broadcast or broadcasting controls
            if (!_isBroadcasting) _buildPreBroadcastControls(),
            if (_isBroadcasting) _buildBroadcastingControls(),

            // Chat overlay (only when broadcasting)
            if (_isBroadcasting) _buildChatOverlay(),

            // Loading indicator
            if (_streamManager.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
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
                'Kamera baslatiliyor...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _agoraService.engine!,
          canvas: const VideoCanvas(uid: 0), // 0 = local user
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Close button
            IconButton(
              onPressed: () {
                if (_isBroadcasting) {
                  _stopBroadcast();
                } else {
                  context.pop();
                }
              },
              icon: const Icon(Icons.close, color: Colors.white),
            ),

            const Spacer(),

            // Live indicator and viewer count
            if (_isBroadcasting) ...[
              Consumer<ViewerTracker>(
                builder: (context, tracker, _) => LiveIndicator(
                  viewerCount: tracker.currentViewerCount,
                ),
              ),
              const SizedBox(width: 16),
            ],

            // Connection indicator
            if (_isBroadcasting)
              Consumer<ConnectionManager>(
                builder: (context, connection, _) => ConnectionIndicator(
                  quality: connection.quality,
                ),
              ),

            // Camera switch button
            if (_isAgoraReady)
              IconButton(
                onPressed: () => _agoraService.switchCamera(),
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreBroadcastControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event info
            if (widget.eventName != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.eventName!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            const SizedBox(height: 16),

            // Settings row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSettingChip(
                  icon: Icons.hd,
                  label: _selectedQuality.displayName,
                  onTap: _showQualitySettings,
                ),
                const SizedBox(width: 12),
                _buildSettingChip(
                  icon: _getPrivacyIcon(_selectedPrivacy),
                  label: _selectedPrivacy.displayName,
                  onTap: _showPrivacySettings,
                ),
                const SizedBox(width: 12),
                _buildSettingChip(
                  icon: Icons.fiber_manual_record,
                  label: _isRecordingEnabled ? 'Kayit Acik' : 'Kayit Kapali',
                  onTap: () {
                    setState(() => _isRecordingEnabled = !_isRecordingEnabled);
                  },
                  isActive: _isRecordingEnabled,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam),
                    SizedBox(width: 8),
                    Text(
                      'Yayini Baslat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastingControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Duration
            Consumer<StreamManager>(
              builder: (context, manager, _) => Text(
                manager.currentStream?.formattedDuration ?? '00:00',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.hd,
                  label: 'Kalite',
                  onTap: _showQualitySettings,
                ),
                _buildControlButton(
                  icon: _getPrivacyIcon(_selectedPrivacy),
                  label: 'Gizlilik',
                  onTap: _showPrivacySettings,
                ),
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Durdur',
                  onTap: _stopBroadcast,
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    return Positioned(
      left: 16,
      right: 80,
      bottom: 160,
      child: SizedBox(
        height: 250,
        child: Consumer<ChatManager>(
          builder: (context, chatManager, _) {
            debugPrint('[BroadcastScreen] Chat rebuild: ${chatManager.messages.length} messages');
            return ChatWidget(
              messages: chatManager.messages,
              onSendMessage: chatManager.sendMessage,
              showInput: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.red) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red
                  : Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  IconData _getPrivacyIcon(PrivacyLevel privacy) {
    switch (privacy) {
      case PrivacyLevel.public:
        return Icons.public;
      case PrivacyLevel.followersOnly:
        return Icons.people;
      case PrivacyLevel.participantsOnly:
        return Icons.lock;
    }
  }
}
