import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/partnership_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/partnership_service.dart';
import '../../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

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
  List<UserModel> _suggestedUsers = [];
  bool _isLoadingIncoming = true;
  bool _isLoadingOutgoing = true;
  bool _isLoadingSuggestions = true;
  final Set<String> _processingIds = {};

  String? _suggestionsError;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // Load incoming and outgoing in parallel, with individual timeouts
      await Future.wait([
        _loadIncomingRequests().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('_loadIncomingRequests timed out');
            if (mounted) setState(() => _isLoadingIncoming = false);
          },
        ),
        _loadOutgoingRequests().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('_loadOutgoingRequests timed out');
            if (mounted) setState(() => _isLoadingOutgoing = false);
          },
        ),
      ]);
      await _loadSuggestedUsers().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('_loadSuggestedUsers timed out');
          if (mounted) {
            setState(() {
              _suggestedUsers = [];
              _isLoadingSuggestions = false;
              _suggestionsError = l10n.timeoutError;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _loadAllData: $e');
      // Ensure all loading states are cleared even on unexpected errors
      if (mounted) {
        setState(() {
          _isLoadingIncoming = false;
          _isLoadingOutgoing = false;
          _isLoadingSuggestions = false;
          _suggestionsError ??= e.toString();
        });
      }
    }
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
      final requests = await _partnershipService.getIncomingRequests(userId);
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

        requestsWithUsers.add(
          _RequestWithUser(
            partnership: partnership,
            user: user,
            sharedMeetupCount: partnership.sharedMeetupIds.length,
          ),
        );
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
          SnackBar(content: Text(l10n.incomingRequestsLoadError(e.toString()))),
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
      final requests = await _partnershipService.getOutgoingRequests(userId);
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

        requestsWithUsers.add(
          _RequestWithUser(
            partnership: partnership,
            user: user,
            sharedMeetupCount: partnership.sharedMeetupIds.length,
          ),
        );
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
          SnackBar(content: Text(l10n.outgoingRequestsLoadError(e.toString()))),
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
        SnackBar(content: Text(l10n.partnerRequestAccepted)),
      );
      await _loadIncomingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorRetry)),
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
        SnackBar(content: Text(l10n.partnerRequestRejected)),
      );
      await _loadIncomingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorRetry)),
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
        SnackBar(content: Text(l10n.partnerRequestCanceled)),
      );
      await _loadOutgoingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorRetry)),
      );
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(partnership.id));
      }
    }
  }

  Future<void> _loadSuggestedUsers() async {
    final userId = _currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingSuggestions = false);
      return;
    }

    if (mounted) setState(() => _isLoadingSuggestions = true);

    try {
      // Get current user's partners list
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final currentPartners =
          (currentUserDoc.data()?['partners'] as List<dynamic>?)
              ?.cast<String>()
              .toSet() ??
          <String>{};

      // Get pending request user IDs (both incoming and outgoing)
      final pendingUserIds = <String>{};
      for (final r in _incomingRequests) {
        pendingUserIds.add(r.partnership.userId);
      }
      for (final r in _outgoingRequests) {
        pendingUserIds.add(r.partnership.partnerId);
      }

      // Get users who participated in same meetups
      final myMeetups = await FirebaseFirestore.instance
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .limit(20)
          .get();

      final candidateIds = <String>{};
      for (final doc in myMeetups.docs) {
        final participants =
            (doc.data()['participantIds'] as List<dynamic>?)?.cast<String>() ??
            [];
        candidateIds.addAll(participants);
      }

      // Remove self, existing partners, and pending requests
      candidateIds.remove(userId);
      candidateIds.removeAll(currentPartners);
      candidateIds.removeAll(pendingUserIds);

      if (candidateIds.isEmpty) {
        if (mounted) {
          setState(() {
            _suggestedUsers = [];
            _isLoadingSuggestions = false;
          });
        }
        return;
      }

      // Fetch user models (limit to 20)
      final limitedIds = candidateIds.take(20).toList();
      final users = <UserModel>[];
      for (var i = 0; i < limitedIds.length; i += 10) {
        final end = (i + 10).clamp(0, limitedIds.length);
        final batch = limitedIds.sublist(i, end);
        if (batch.isEmpty) continue;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snapshot.docs) {
          users.add(UserModel.fromJson(doc.data()));
        }
      }

      if (mounted) {
        setState(() {
          _suggestedUsers = users;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggested users: $e');
      if (mounted) {
        setState(() {
          _suggestedUsers = [];
          _isLoadingSuggestions = false;
          _suggestionsError = e.toString();
        });
      }
    }
  }

  Future<void> _sendPartnerRequest(UserModel user) async {
    final userId = _currentUserId;
    if (userId == null) return;
    if (_processingIds.contains(user.id)) return;

    setState(() => _processingIds.add(user.id));

    try {
      final sharedMeetupIds = await _partnershipService.getSharedMeetupIds(
        userId,
        user.id,
      );

      if (sharedMeetupIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noSharedEventError),
          ),
        );
        return;
      }

      await _partnershipService.sendPartnershipRequest(
        requesterId: userId,
        receiverId: user.id,
        sharedMeetupIds: sharedMeetupIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.requestSentTo(user.username)),
        ),
      );

      // Remove from suggestions and reload outgoing
      setState(() {
        _suggestedUsers.removeWhere((u) => u.id == user.id);
      });
      await _loadOutgoingRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requestFailed(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _processingIds.remove(user.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.partnershipAction),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: l10n.incomingTab),
            Tab(text: l10n.sentTab),
            Tab(text: l10n.discoverTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIncomingTab(),
          _buildOutgoingTab(),
          _buildDiscoverTab(),
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
      return _buildEmptyState(l10n.incomingRequestsEmpty, Icons.inbox_outlined);
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
        l10n.outgoingRequestsEmpty,
        Icons.outbox_outlined,
      );
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

  Widget _buildDiscoverTab() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_suggestionsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.suggestionsLoadFailed,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _suggestionsError = null);
                  _loadSuggestedUsers();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retryButton),
              ),
            ],
          ),
        ),
      );
    }

    if (_suggestedUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 64,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noSuggestions,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.discoverPartnersHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSuggestedUsers,
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestedUsers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = _suggestedUsers[index];
          return _buildSuggestedUserCard(user);
        },
      ),
    );
  }

  Widget _buildSuggestedUserCard(UserModel user) {
    final isProcessing = _processingIds.contains(user.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/user-profile/${user.id}'),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primary,
              backgroundImage: user.profileImageUrl != null
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.username[0].toUpperCase(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                if (user.interestedSports != null &&
                    user.interestedSports!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.interestedSports!
                        .take(3)
                        .map((s) => s.displayName)
                        .join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => _sendPartnerRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.textDark,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  : Text(
                      l10n.sendRequest,
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
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 16),
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
                  user?.username ?? l10n.unknownUser,
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
                      l10n.sharedMeetupCount(item.sharedMeetupCount),
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
                              : Text(
                                  l10n.accept,
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
                          child: Text(
                            l10n.reject,
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
                  user?.username ?? l10n.unknownUser,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.pendingResponse,
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
              onPressed: isProcessing
                  ? null
                  : () => _cancelRequest(partnership),
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
                  : Text(
                      l10n.cancelRequest,
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



