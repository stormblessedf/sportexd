import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  PremiumPlan _selectedPlan = PremiumPlan.annual;
  bool _isPurchasing = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const _gold = Color(0xFFFBBF24);
  static const _goldDeep = Color(0xFFF59E0B);
  static const _goldDark = Color(0xFFB45309);
  static const _bgDark = Color(0xFF0A0A14);
  static const _bgCard = Color(0xFF141420);
  static const _bgCardBorder = Color(0xFF2A2A40);

  final List<_PremiumFeature> _features = const [
    _PremiumFeature(
      icon: Icons.swipe_rounded,
      title: 'Swipe Eşleşme Sistemi',
      subtitle: 'Sağa kaydırarak spor arkadaşı bul',
    ),
    _PremiumFeature(
      icon: Icons.workspace_premium_rounded,
      title: 'Premium Profil Rozeti',
      subtitle: 'Profilinde altın premium rozeti göster',
    ),
    _PremiumFeature(
      icon: Icons.trending_up_rounded,
      title: 'Öne Çıkan Profil',
      subtitle: 'Keşfet sayfasında üst sıralarda görün',
    ),
    _PremiumFeature(
      icon: Icons.event_available_rounded,
      title: 'Sınırsız Etkinlik Oluşturma',
      subtitle: 'Ücretsiz hesaplarda aylık 3 etkinlik limiti',
    ),
    _PremiumFeature(
      icon: Icons.support_agent_rounded,
      title: 'Öncelikli Destek',
      subtitle: '7/24 öncelikli müşteri desteği',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    final premiumService = context.read<PremiumService>();
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;

    if (userId == null) {
      _showSnack('Satın almak için giriş yapmalısınız.');
      return;
    }

    final plan = _selectedPlan;
    final details = PremiumService.planDetails(plan);
    final price = details['price'] as String;
    final label = details['label'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Premium\'u Onayla',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label plan: $price',
              style: const TextStyle(color: _gold, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu ekran gerçek ödeme entegrasyonu için hazır yapıdadır. Demo modunda premium aktif edilecek.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasing = true);
    try {
      await premiumService.activatePremium(userId: userId, plan: plan);
      if (!mounted) return;
      _showSnack('🎉 Premium aktif edildi!');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Bir hata oluştu. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PremiumService>(
      builder: (context, premiumService, _) {
        final isAlreadyPremium = premiumService.hasActivePremium;
        return Scaffold(
          backgroundColor: _bgDark,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, isAlreadyPremium),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      if (isAlreadyPremium)
                        _buildActiveState(premiumService)
                      else ...[
                        _buildHeroSection(),
                        const SizedBox(height: 32),
                        _buildPlanSelector(),
                        const SizedBox(height: 32),
                        _buildFeatureList(),
                        const SizedBox(height: 32),
                        _buildPurchaseButton(),
                        const SizedBox(height: 12),
                        _buildRestoreText(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, bool isAlreadyPremium) {
    return SliverAppBar(
      backgroundColor: _bgDark,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: _gold, size: 22),
          SizedBox(width: 8),
          Text(
            'Sporsal Premium',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) => Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x40FBBF24), Color(0x00FBBF24)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: child,
          ),
          child: const Center(
            child: Text(
              '👑',
              style: TextStyle(fontSize: 52),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sporsal\'ın Tüm\nGücünü Aç',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Premium üyelikle spor deneyimini bir üst seviyeye taşı.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSelector() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _bgCardBorder),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _buildPlanTile(PremiumPlan.monthly),
          _buildPlanTile(PremiumPlan.annual),
        ],
      ),
    );
  }

  Widget _buildPlanTile(PremiumPlan plan) {
    final details = PremiumService.planDetails(plan);
    final isSelected = _selectedPlan == plan;
    final savings = details['savingsLabel'] as String?;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = plan),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? _gold : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                details['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details['price'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              if (savings != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black.withValues(alpha: 0.15)
                        : _gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    savings,
                    style: TextStyle(
                      color: isSelected ? Colors.black87 : _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Premium\'a Dahil Olanlar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_features.length, (i) {
          final feature = _features[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFeatureRow(feature),
          );
        }),
      ],
    );
  }

  Widget _buildFeatureRow(_PremiumFeature feature) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(feature.icon, color: _gold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                feature.subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: _gold, size: 20),
      ],
    );
  }

  Widget _buildPurchaseButton() {
    final details = PremiumService.planDetails(_selectedPlan);
    final price = details['price'] as String;
    final label = details['label'] as String;

    return GestureDetector(
      onTap: _isPurchasing ? null : _handlePurchase,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isPurchasing
                ? [_goldDark.withValues(alpha: 0.5), _goldDark.withValues(alpha: 0.5)]
                : [_gold, _goldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPurchasing
              ? []
              : [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: _isPurchasing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.black,
                  ),
                )
              : Text(
                  '$label Premium — $price',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRestoreText() {
    return const Center(
      child: Text(
        'Abonelikler, satın alma onayından sonra aktif olur.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF475569), fontSize: 12),
      ),
    );
  }

  Widget _buildActiveState(PremiumService premiumService) {
    final until = premiumService.premiumUntil;
    final remainingDays = until?.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0x60FBBF24), Color(0x00FBBF24)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Premium Aktif!',
            style: TextStyle(
              color: _gold,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (remainingDays != null)
            Text(
              '$remainingDays gün kaldı',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
          if (until != null) ...[
            const SizedBox(height: 4),
            Text(
              'Bitiş: ${_formatDate(until)}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF1E1E2E)),
          const SizedBox(height: 24),
          const Text(
            'Tüm Premium Avantajlarını Kullanıyorsunuz',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ...[
            const _PremiumFeature(icon: Icons.swipe_rounded, title: 'Swipe Eşleşme', subtitle: ''),
            const _PremiumFeature(icon: Icons.workspace_premium_rounded, title: 'Premium Rozeti', subtitle: ''),
            const _PremiumFeature(icon: Icons.trending_up_rounded, title: 'Öne Çıkan Profil', subtitle: ''),
            const _PremiumFeature(icon: Icons.event_available_rounded, title: 'Sınırsız Etkinlik', subtitle: ''),
          ].map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(f.icon, color: _gold, size: 20),
                  const SizedBox(width: 12),
                  Text(f.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const Spacer(),
                  const Icon(Icons.check_circle_rounded, color: _gold, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

class _PremiumFeature {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PremiumFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
