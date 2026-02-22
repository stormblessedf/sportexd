import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/live_broadcast_service.dart';
import '../domain/models/models.dart';
import 'widgets/widgets.dart';

/// Aktif canlı yayınlar listesi ekranı
class LiveStreamsScreen extends StatefulWidget {
  const LiveStreamsScreen({super.key});

  @override
  State<LiveStreamsScreen> createState() => _LiveStreamsScreenState();
}

class _LiveStreamsScreenState extends State<LiveStreamsScreen> {
  final LiveBroadcastService _service = LiveBroadcastService();
  bool _isLoading = true;
  List<StreamSession> _streams = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final streams = await _service.getActiveStreams();
      setState(() {
        _streams = streams.where((s) => s.isLive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Yayınlar yüklenemedi';
        _isLoading = false;
      });
    }
  }

  void _navigateToViewer(StreamSession stream) {
    context.push('/live-broadcast/viewer/${stream.id}');
  }

  void _navigateToBroadcast() {
    context.push('/live-broadcast/create');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Yayınlar'),
        actions: [
          IconButton(
            onPressed: _loadStreams,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToBroadcast,
        icon: const Icon(Icons.videocam),
        label: const Text('Yayın Başlat'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStreams,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_streams.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _streams.length,
        itemBuilder: (context, index) {
          final stream = _streams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: StreamCard(
              stream: stream,
              onTap: () => _navigateToViewer(stream),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Şu an canlı yayın yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk yayını sen başlat!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToBroadcast,
            icon: const Icon(Icons.videocam),
            label: const Text('Yayın Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yayın kartı
class StreamCard extends StatelessWidget {
  final StreamSession stream;
  final VoidCallback? onTap;

  const StreamCard({
    super.key,
    required this.stream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[900],
          image: stream.thumbnailUrl != null
              ? DecorationImage(
                  image: NetworkImage(stream.thumbnailUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Placeholder icon if no thumbnail
            if (stream.thumbnailUrl == null)
              const Center(
                child: Icon(
                  Icons.videocam,
                  size: 48,
                  color: Colors.white24,
                ),
              ),

            // Canlı badge
            Positioned(
              top: 12,
              left: 12,
              child: LiveIndicator(
                viewerCount: stream.currentViewers,
                isLive: stream.isLive,
              ),
            ),

            // Gizlilik badge
            if (stream.privacy != PrivacyLevel.public)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stream.privacy == PrivacyLevel.followersOnly
                            ? Icons.people
                            : Icons.lock,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stream.privacy.displayName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Alt bilgiler
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etkinlik adı
                  Text(
                    stream.eventName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Yayıncı bilgisi
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: stream.broadcasterAvatar.isNotEmpty
                            ? NetworkImage(stream.broadcasterAvatar)
                            : null,
                        child: stream.broadcasterAvatar.isEmpty
                            ? Text(
                                stream.broadcasterName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stream.broadcasterName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Yayın süresi: ${stream.formattedDuration}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
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

/// Kullanıcının yayın geçmişi ekranı
class UserStreamHistoryScreen extends StatefulWidget {
  final String userId;

  const UserStreamHistoryScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserStreamHistoryScreen> createState() =>
      _UserStreamHistoryScreenState();
}

class _UserStreamHistoryScreenState extends State<UserStreamHistoryScreen> {
  final LiveBroadcastService _service = LiveBroadcastService();
  bool _isLoading = true;
  List<StreamSession> _streams = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final streams = await _service.getUserStreamHistory(widget.userId);
      setState(() {
        _streams = streams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yayın Geçmişi'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _streams.isEmpty
              ? const Center(
                  child: Text('Henüz yayın yapılmamış'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _streams.length,
                  itemBuilder: (context, index) {
                    final stream = _streams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryItem(stream),
                    );
                  },
                ),
    );
  }

  Widget _buildHistoryItem(StreamSession stream) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            image: stream.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(stream.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: stream.thumbnailUrl == null
              ? const Icon(Icons.videocam, color: Colors.white54)
              : null,
        ),
        title: Text(stream.eventName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${stream.startedAt.day}/${stream.startedAt.month}/${stream.startedAt.year}',
            ),
            Text(
              'Süre: ${stream.formattedDuration} • ${stream.peakViewers} izleyici',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: stream.recordingUrl != null
            ? IconButton(
                onPressed: () {
                  // TODO: Play recording
                },
                icon: const Icon(Icons.play_circle_outline),
              )
            : null,
      ),
    );
  }
}
