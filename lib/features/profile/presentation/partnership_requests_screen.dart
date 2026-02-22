import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/partnership_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/partnership_service.dart';
import '../../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class PartnershipRequestsScreen extends StatefulWidget {
  const PartnershipRequestsScreen({super.key});

  @override
  State<PartnershipRequestsScreen> createState() =>
      _PartnershipRequestsScreenState();
}

class _PartnershipRequestsScreenState extends State<PartnershipRequestsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PartnershipService _partnershipService = PartnershipService();
  late TabController _tabController;

  List<_RequestWithUser> _incomingRequests = [];
  List<_RequestWithUser> _outgoingRequests = [];
  bool _isLoadingIncoming = true;
  bool _isLoadingOutgoing = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadIncomingRequests();
    _loadOutgoingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _currentUserId => _authService.currentUserId;

  Future<void> _loadIncomingRequests() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingIncoming = false);
      return;
    }

    setState(() => _isLoadingIncoming = true);

    try {
      final requests =
          await _partnershipService.getIncomingRequests(userId);
      final requestsWithUsers = <_RequestWithUser>[];

      for (final partnership in requests) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(partnership.userId)
            .get();

        UserModel? user;
        if (userDoc.exists) {
          user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        }

        requestsWithUsers.add(_RequestWithUser(
          partnership: partnership,
          user: user,
          sharedMeetupCount: partnership.sharedMeetupIds.length,
        ));
      }

      if (mounted) {
        setState(() {
          _incomingRequests = requestsWithUsers;
          _isLoadingIncoming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingIncoming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gelen istekler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _loadOutgoingRequests() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingOutgoing = false);
      return;
    }

    setState(() => _isLoadingOutgoing = true);

    try {
      final requests =
          await _partnershipService.getOutgoingRequests(userId);
      final requestsWithUsers = <_RequestWithUser>[];

      for (final partnership in requests) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(partnership.partnerId)
            .get();

        UserModel? user;
        if (userDoc.exists) {
          user = UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
        }

        requestsWithUsers.add(_RequestWithUser(
          partnership: partnership,
          user: user,
          sharedMeetupCount: partnership.sharedMeetupIds.length,
        ));
      }

      if (mounted) {
        setState(() {
          _outgoingRequests = requestsWithUsers;
          _isLoadingOutgoing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingOutgoing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gonderilen istekler yuklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _acceptRequest(PartnershipModel partnership) async {
    if (_processingIds.contains(partnership.id)) return;
    setState(() => _processingIds.add(partnership.id));

    try {
      await _partnershipService.acceptPartnershipRequest(partnership.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner istegi kabul edildi')),
      );
      await _loadIncomingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu, tekrar deneyin')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(partnership.id));
      }
    }
  }

  Future<void> _rejectRequest(PartnershipModel partnership) async {
    if (_processingIds.contains(partnership.id)) return;
    setState(() => _processingIds.add(partnership.id));

    try {
      await _partnershipService.rejectPartnershipRequest(partnership.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner istegi reddedildi')),
      );
      await _loadIncomingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu, tekrar deneyin')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(partnership.id));
      }
    }
  }

  Future<void> _cancelRequest(PartnershipModel partnership) async {
    if (_processingIds.contains(partnership.id)) return;
    setState(() => _processingIds.add(partnership.id));

    try {
      await _partnershipService.cancelRequest(partnership.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner istegi iptal edildi')),
      );
      await _loadOutgoingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu, tekrar deneyin')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(partnership.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Partner Istekleri'),
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(text: 'Gelen Istekler (${_incomingRequests.length})'),
            Tab(text: 'Gonderilen Istekler (${_outgoingRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(),
          _buildOutgoingTab(),
        ],
      ),
    );
  }

  Widget _buildIncomingTab() {
    if (_isLoadingIncoming) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_incomingRequests.isEmpty) {
      return _buildEmptyState('Gelen partner istegi yok', Icons.inbox_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadIncomingRequests,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _incomingRequests[index];
          return _buildIncomingRequestCard(item);
        },
      ),
    );
  }

  Widget _buildOutgoingTab() {
    if (_isLoadingOutgoing) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_outgoingRequests.isEmpty) {
      return _buildEmptyState(
          'Gonderilen partner istegi yok', Icons.outbox_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadOutgoingRequests,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _outgoingRequests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _outgoingRequests[index];
          return _buildOutgoingRequestCard(item);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestCard(_RequestWithUser item) {
    final user = item.user;
    final partnership = item.partnership;
    final isProcessing = _processingIds.contains(partnership.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: user != null
                ? () => context.push('/user-profile/${user.id}')
                : null,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary,
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? Text(
                      (user?.username ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'Bilinmeyen Kullanici',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.sports_handball,
                      size: 14,
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.sharedMeetupCount} ortak etkinlik',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _acceptRequest(partnership),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.textDark,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.textDark,
                                  ),
                                )
                              : const Text(
                                  'Kabul Et',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: isProcessing
                              ? null
                              : () => _rejectRequest(partnership),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Reddet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    );
  }

  Widget _buildOutgoingRequestCard(_RequestWithUser item) {
    final user = item.user;
    final partnership = item.partnership;
    final isProcessing = _processingIds.contains(partnership.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: user != null
                ? () => context.push('/user-profile/${user.id}')
                : null,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary,
              backgroundImage: user?.profileImageUrl != null
                  ? NetworkImage(user!.profileImageUrl!)
                  : null,
              child: user?.profileImageUrl == null
                  ? Text(
                      (user?.username ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? 'Bilinmeyen Kullanici',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yanit bekleniyor...',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Cancel button
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed:
                  isProcessing ? null : () => _cancelRequest(partnership),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                side: const BorderSide(color: Colors.red, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Text(
                      'Iptal Et',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to hold a partnership request together with the resolved user info.
class _RequestWithUser {
  final PartnershipModel partnership;
  final UserModel? user;
  final int sharedMeetupCount;

  const _RequestWithUser({
    required this.partnership,
    this.user,
    this.sharedMeetupCount = 0,
  });
}
